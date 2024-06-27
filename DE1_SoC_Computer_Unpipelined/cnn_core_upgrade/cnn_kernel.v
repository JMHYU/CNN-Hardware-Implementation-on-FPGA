`include "timescale.vh"

module cnn_kernel (
    // Clock & Reset
    clk             ,
    reset_n         ,
    i_soft_reset    ,
    i_cnn_weight    ,
    i_in_valid      ,
    i_in_fmap       ,
    o_ot_valid      ,
    o_ot_kernel_acc              
    );
`include "defines_cnn_core.vh"

localparam LATENCY = 2;
//==============================================================================
// Input/Output declaration
//==============================================================================
input                               		clk         	;
input                               		reset_n     	;
input                               		i_soft_reset	;
input     [KX*KY*DATA_LEN-1 : 0]  			i_cnn_weight 	;
input                               		i_in_valid  	;
input     [KX*KY*DATA_LEN-1 : 0]  			i_in_fmap    	;
output                              		o_ot_valid  	;
output    [DATA_LEN-1 : 0]  				o_ot_kernel_acc ;
		
//==============================================================================
// Data Enable Signals 
//==============================================================================
wire    [LATENCY-1 : 0] 	ce;
reg     [LATENCY-1 : 0] 	r_valid;
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_valid   <= {LATENCY{1'b0}};
    end else if(i_soft_reset) begin
        r_valid   <= {LATENCY{1'b0}};
    end else begin
        r_valid[LATENCY-2]  <= i_in_valid;
        r_valid[LATENCY-1]  <= r_valid[LATENCY-2];
    end
end

assign	ce = r_valid;

//==============================================================================
// mul = fmap * weight
//==============================================================================

wire      [KY*KX*DATA_LEN-1 : 0]    mul  ;
reg       [KY*KX*DATA_LEN-1 : 0]    r_mul;

genvar mul_idx;
generate
	for(mul_idx = 0; mul_idx < KY*KX; mul_idx = mul_idx + 1) begin : gen_mul
		assign  mul[mul_idx * DATA_LEN +: DATA_LEN]	= i_in_fmap[mul_idx * DATA_LEN +: DATA_LEN] * i_cnn_weight[mul_idx * DATA_LEN +: DATA_LEN];

		always @(posedge clk or negedge reset_n) begin
		    if(!reset_n) begin
		        r_mul[mul_idx * DATA_LEN +: DATA_LEN] <= {DATA_LEN{1'b0}};
		    end else if(i_soft_reset) begin
		        r_mul[mul_idx * DATA_LEN +: DATA_LEN] <= {DATA_LEN{1'b0}};
		    end else if(i_in_valid)begin
		        r_mul[mul_idx *DATA_LEN +: DATA_LEN] <= mul[mul_idx * DATA_LEN +: DATA_LEN];
		    end
		end
	end
endgenerate


//==============================================================================
// acc = acc + mul
//==============================================================================

reg       [DATA_LEN-1 : 0]    acc_kernel 	;
reg       [DATA_LEN-1 : 0]    r_acc_kernel  ;

// TODO Logic
// to accumulate all multiplication results. if use for-loop, you can use the template below
integer acc_idx;
always @ (*) begin
	acc_kernel[0 +: DATA_LEN]= {DATA_LEN{1'b0}};
	for(acc_idx =0; acc_idx < KY*KX; acc_idx = acc_idx +1) begin
		acc_kernel[0 +: DATA_LEN] = acc_kernel[0 +: DATA_LEN] + r_mul[acc_idx*DATA_LEN +: DATA_LEN]; 
	end
end


// F/F
always @(posedge clk or negedge reset_n) begin
	if(!reset_n) begin
		r_acc_kernel[0 +: DATA_LEN] <= {DATA_LEN{1'b0}};
	end else if(i_soft_reset) begin
		r_acc_kernel[0 +: DATA_LEN] <= {DATA_LEN{1'b0}};
	end else if(ce[LATENCY-2])begin
		r_acc_kernel[0 +: DATA_LEN] <= acc_kernel[0 +: DATA_LEN];
	end
end


assign o_ot_valid = r_valid[LATENCY-1];
assign o_ot_kernel_acc = r_acc_kernel;

endmodule
