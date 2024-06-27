`include "timescale.vh"

module cnn_topCore (
    // Clock & Reset
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_fmap             
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
input     [IN*ICH*IX*IY*DATA_LEN-1 : 0]     i_in_fmap    	;
output                                      o_ot_valid  	;
output    [IN*OCH*OX*OY*DATA_LEN-1 : 0]     o_ot_fmap    	;

//==============================================================================
// Data Enable Signals 
//==============================================================================
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
wire    [IN-1 : 0]          w_ot_valid;
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
// cnn core instance for stride
//==============================================================================

wire    [IN-1 : 0]                      w_in_valid;
wire    [IN*OCH*OX*OY*DATA_LEN-1 : 0]   w_ot_one_fmap;

// TODO Instantiation
// to call cnn_acc_ci instance. if use generate, you can use the template below.
genvar core_inst;
generate
	for(core_inst = 0; core_inst < IN; core_inst = core_inst+1) begin : gen_core_inst
		wire    [OCH*ICH*KX*KY*DATA_LEN-1 : 0]  w_cnn_weight    = i_cnn_weight[0 +: OCH*ICH*KX*KY*DATA_LEN];
		wire    [ICH*IX*IY*DATA_LEN-1 : 0]  w_in_fmap           = i_in_fmap[core_inst*ICH*IX*IY*DATA_LEN +: ICH*IX*IY*DATA_LEN];
		assign	w_in_valid[core_inst] = i_in_valid; 

		cnn_core u_cnn_core(
	    .clk             (clk         ),
	    .reset_n         (reset_n     ),
	    .i_soft_reset    (i_soft_reset),
	    .i_cnn_weight    (w_cnn_weight),
	    .i_in_valid      (w_in_valid[core_inst]),
	    .i_in_fmap       (w_in_fmap),
	    .o_ot_valid      (w_ot_valid[core_inst]),
	    .o_ot_one_fmap   (w_ot_one_fmap[core_inst*OCH*OX*OY*DATA_LEN +: OCH*OX*OY*DATA_LEN])
	    );
	end
endgenerate

reg     [IN*OCH*OX*OY*DATA_LEN-1 : 0]   r_ot_one_fmap;

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_ot_one_fmap <= 0;
    end else if(i_soft_reset) begin
        r_ot_one_fmap <= 0;
    end else if(&w_ot_valid) begin
        r_ot_one_fmap <= w_ot_one_fmap;
    end
end

//==============================================================================
// No Activation
//==============================================================================
assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_fmap  = r_ot_one_fmap;

endmodule

