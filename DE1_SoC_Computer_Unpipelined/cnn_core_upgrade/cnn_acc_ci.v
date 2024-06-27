`include "timescale.vh"

module cnn_acc_ci (
    // Clock & Reset
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_ci_acc              
    );
`include "defines_cnn_core.vh"

localparam LATENCY = 1;
//==============================================================================
// Input/Output declaration
//==============================================================================
input                                       clk         	;
input                                       reset_n     	;
input                                       i_soft_reset	;
input     [ICH*KX*KY*DATA_LEN-1 : 0]        i_cnn_weight 	;
input                                       i_in_valid  	;
input     [ICH*IX*IY*DATA_LEN-1 : 0]        i_in_fmap    	;
output                                      o_ot_valid  	;
output    [OX*OY*DATA_LEN-1 : 0]  		    o_ot_ci_acc 	;

//==============================================================================
// Data Enable Signals 
//==============================================================================
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
wire    [ICH*OX*OY-1 : 0]   w_ot_valid;
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
// mul_acc kenel instance
//==============================================================================

wire    [ICH*OX*OY-1 : 0]               w_in_valid;
wire    [ICH*OX*OY*DATA_LEN-1 : 0]      w_ot_kernel_acc;

// wire signed [DATA_LEN-1:0] parse_w_in_fmap_kernel[0:ICH-1][0:OY-1][0:OX-1][0:KY-1][0:KX-1];

genvar ich, oy, ox;
genvar j;
generate
    for (ich = 0; ich < ICH; ich = ich+1) begin : gen_ich
        wire    [KX*KY*DATA_LEN-1 : 0]      w_cnn_weight    = i_cnn_weight[ich*KX*KY*DATA_LEN +: KX*KY*DATA_LEN];
        wire    [IX*IY*DATA_LEN-1 : 0]  	w_in_fmap    	= i_in_fmap[ich*IX*IY*DATA_LEN +: IX*IY*DATA_LEN];
        for (oy = 0; oy < OY; oy = oy+1) begin  : gen_oy
            for (ox = 0; ox < OX; ox = ox+1) begin : gen_ox
                // wire [KX*KY*DATA_LEN-1 : 0] w_in_fmap_kernel   = {w_in_fmap[((oy+0)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+1)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+2)*IX+ox)*DATA_LEN +: KX*DATA_LEN]};
                wire [KX*KY*DATA_LEN-1 : 0] w_in_fmap_kernel   = {w_in_fmap[((oy+2)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+1)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+0)*IX+ox)*DATA_LEN +: KX*DATA_LEN]};

                // for (j = 0; j<KX; j=j+1) begin : PARSE_W_FMAP_KERNEL
                //     assign parse_w_in_fmap_kernel[ich][oy][ox][0][j] = w_in_fmap_kernel[(KX*DATA_LEN * 0) + (DATA_LEN * j) +: DATA_LEN];
				// 	assign parse_w_in_fmap_kernel[ich][oy][ox][1][j] = w_in_fmap_kernel[(KX*DATA_LEN * 1) + (DATA_LEN * j) +: DATA_LEN];
				// 	assign parse_w_in_fmap_kernel[ich][oy][ox][2][j] = w_in_fmap_kernel[(KX*DATA_LEN * 2) + (DATA_LEN * j) +: DATA_LEN];
                // end

                assign	w_in_valid[ich*OY*OX + oy*OX + ox] = i_in_valid;

                cnn_kernel u_cnn_kernel(
                .clk             (clk            ),
                .reset_n         (reset_n        ),
                .i_soft_reset    (i_soft_reset   ),
                .i_cnn_weight    (w_cnn_weight   ),
                .i_in_valid      (w_in_valid[ich*OY*OX + oy*OX + ox]),
                .i_in_fmap       (w_in_fmap_kernel),
                .o_ot_valid      (w_ot_valid[ich*OY*OX + oy*OX + ox]),
                .o_ot_kernel_acc (w_ot_kernel_acc[(ich*OY*OX + oy*OX + ox)*DATA_LEN +: DATA_LEN])             
                );
            end
        end
    end
endgenerate

//==============================================================================
// ci_acc = ci_acc + kernel_acc
//==============================================================================

wire    [OX*OY*DATA_LEN-1 : 0]  		w_ot_ci_acc;
reg     [OX*OY*DATA_LEN-1 : 0]  		r_ot_ci_acc;
reg     [OX*OY*DATA_LEN-1 : 0]  		ot_ci_acc;


// TODO Logic
// to accumulate the output of each Kernel
integer i;
always @(*) begin
	ot_ci_acc = {OX*OY*DATA_LEN{1'b0}};
    for(i = 0; i < ICH; i = i+1) begin
        ot_ci_acc = ot_ci_acc + w_ot_kernel_acc[i*OX*OY*DATA_LEN +: OX*OY*DATA_LEN];
    end
 
end
assign w_ot_ci_acc = ot_ci_acc;


// F/F
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= {OX*OY*DATA_LEN{1'b0}};
    end else if(i_soft_reset) begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= {OX*OY*DATA_LEN{1'b0}};
    end else if(&w_ot_valid)begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= w_ot_ci_acc[0 +: OX*OY*DATA_LEN];
    end
end

assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_ci_acc = r_ot_ci_acc;

endmodule
