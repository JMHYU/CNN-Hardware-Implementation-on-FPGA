`include "timescale.vh"

module cnn_core (
    // Clock & Reset
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_one_fmap
    );
`include "defines_cnn_core.vh"

localparam LATENCY = 1;
//==============================================================================
// Input/Output declaration
//==============================================================================
input                                       clk         	;
input                                       reset_n     	;
input                                       i_soft_reset	;
input     [OCH*ICH*KX*KY*DATA_LEN-1 : 0]    i_cnn_weight 	;
input                                       i_in_valid  	;
input     [ICH*IX*IY*DATA_LEN-1 : 0]        i_in_fmap    	;
output                                      o_ot_valid  	;
output    [OCH*OX*OY*DATA_LEN-1 : 0]        o_ot_one_fmap   ;

//==============================================================================
// Data Enable Signals 
//==============================================================================
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
wire    [OCH-1 : 0]         w_ot_valid;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid   <= {LATENCY{1'b0}};
    end else if(i_soft_reset) begin
        r_valid   <= {LATENCY{1'b0}};
    end else begin
        r_valid[LATENCY-1]  <= &w_ot_valid;
    end
end

assign	ce = r_valid;

//==============================================================================
// acc ci instance
//==============================================================================

wire    [OCH-1 : 0]                     w_in_valid;
wire    [OCH*OX*OY*DATA_LEN-1 : 0]      w_ot_ci_acc;

// TODO Instantiation
// to call cnn_acc_ci instance. if use generate, you can use the template below.
genvar ci_inst;
generate
	for(ci_inst = 0; ci_inst < OCH; ci_inst = ci_inst + 1) begin : gen_ci_inst
        wire    [ICH*KX*KY*DATA_LEN-1 : 0]  w_cnn_weight 	= i_cnn_weight[ci_inst*ICH*KX*KY*DATA_LEN +: ICH*KX*KY*DATA_LEN];
        wire    [ICH*IX*IY*DATA_LEN-1 : 0]  w_in_fmap    	= i_in_fmap[0 +: ICH*IX*IY*DATA_LEN];
        assign	w_in_valid[ci_inst] = i_in_valid; 

        cnn_acc_ci u_cnn_acc_ci(
        .clk             (clk         ),
        .reset_n         (reset_n     ),
        .i_soft_reset    (i_soft_reset),
        .i_cnn_weight    (w_cnn_weight),
        .i_in_valid      (w_in_valid[ci_inst]),
        .i_in_fmap       (w_in_fmap),
        .o_ot_valid      (w_ot_valid[ci_inst]),
        .o_ot_ci_acc     (w_ot_ci_acc[ci_inst*OX*OY*(DATA_LEN) +: OX*OY*(DATA_LEN)])
        );
	end
endgenerate

reg         [OCH*OX*OY*DATA_LEN-1 : 0]  r_ot_ci_acc;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_ot_ci_acc <= 0;
    end else if(i_soft_reset) begin
        r_ot_ci_acc <= 0;
    end else if(&w_ot_valid) begin
        r_ot_ci_acc <= w_ot_ci_acc;
    end
end

//==============================================================================
// No Activation
//==============================================================================
assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_one_fmap  = r_ot_ci_acc;

endmodule