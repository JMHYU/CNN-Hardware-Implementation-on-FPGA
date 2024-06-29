`include "timescale.vh"

module cnn_acc_ci #(
    parameter IDLE =6'd0,
    parameter KERNEL0 = 6'd1,
	parameter KERNEL1 = 6'd2,
	parameter KERNEL2 = 6'd3,
    parameter KERNEL3 = 6'd4,
	parameter KERNEL4 = 6'd5,
	parameter KERNEL5 = 6'd6,
    parameter KERNEL6 = 6'd7,
	parameter KERNEL7 = 6'd8,
	parameter KERNEL8 = 6'd9,
    parameter KERNEL9 = 6'd10,
	parameter KERNEL10 = 6'd11,
	parameter KERNEL11 = 6'd12,
    parameter KERNEL12 = 6'd13,
	parameter KERNEL13 = 6'd14,
	parameter KERNEL14 = 6'd15,	
    parameter KERNEL15 = 6'd16,
	parameter KERNEL16 = 6'd17,
	parameter KERNEL17 = 6'd18,
    parameter KERNEL18 = 6'd19,
	parameter KERNEL19 = 6'd20,
	parameter KERNEL20 = 6'd21,
    parameter KERNEL21 = 6'd22,
	parameter KERNEL22 = 6'd23,
	parameter KERNEL23 = 6'd24,
    parameter KERNEL24 = 6'd25,
	parameter KERNEL25 = 6'd26,
	parameter KERNEL26 = 6'd27,
    parameter KERNEL27 = 6'd28,
	parameter KERNEL28 = 6'd29,
	parameter KERNEL29 = 6'd30,
    parameter WAIT1 =6'd31,
    parameter WAIT2 =6'd32,
    parameter ACC =6'd33,
    parameter DONE =6'd34
    
)(
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

input                                       clk         	;
input                                       reset_n     	;
input                                       i_soft_reset	;
input     [ICH*KX*KY*DATA_LEN-1 : 0]        i_cnn_weight 	;
input                                       i_in_valid  	;
input     [ICH*IX*IY*DATA_LEN-1 : 0]        i_in_fmap    	;
output                                      o_ot_valid  	;
output    [OX*OY*DATA_LEN-1 : 0]  		    o_ot_ci_acc 	;

reg  [5:0] state, next_state;   
wire         w_in_valid = i_in_valid;
wire w_valid = (state == DONE);
wire acc     = (state == ACC);

always @(posedge clk, negedge reset_n) begin
	if(!reset_n)          state <= IDLE;
    else if(i_soft_reset) state <= IDLE;
	else 			      state <= next_state;
end

//==============================================================================
// mul_acc kenel instance
//==============================================================================
wire [2:0] ich, oy, ox;
wire w_o_kernel_valid; // Not needed?
wire [DATA_LEN-1:0] w_o_kernel_acc;

assign ich = (state < KERNEL10) ? 0 : (state < KERNEL20) ? 1 :  (state < WAIT1) ? 2: (state < DONE) ? 3 : 0;
assign oy = ((state-1) % 10 < 5) ? 0 : 1;
assign ox = ((state-1) % 5);

reg     [ICH*OX*OY*DATA_LEN-1 : 0]   r_ot_kernel_acc;
wire    [KX*KY*DATA_LEN-1 : 0]       w_cnn_weight    = i_cnn_weight[ich*KX*KY*DATA_LEN +: KX*KY*DATA_LEN];
wire    [IX*IY*DATA_LEN-1 : 0]  	 w_in_fmap    	= i_in_fmap[ich*IX*IY*DATA_LEN +: IX*IY*DATA_LEN];
wire    [KX*KY*DATA_LEN-1 : 0]       w_in_fmap_kernel   = {w_in_fmap[((oy+2)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+1)*IX+ox)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((oy+0)*IX+ox)*DATA_LEN +: KX*DATA_LEN]};

cnn_kernel u_cnn_kernel(
                .clk             (clk            ),
                .reset_n         (reset_n        ),
                .i_soft_reset    (i_soft_reset   ),
                .i_cnn_weight    (w_cnn_weight   ),
                .i_in_valid      (w_in_valid),
                .i_in_fmap       (w_in_fmap_kernel),
                .o_ot_valid      (w_o_kernel_valid),
                .o_ot_kernel_acc (w_o_kernel_acc)             
                );

//==============================================================================
// ci_acc = ci_acc + kernel_acc
//==============================================================================

wire    [OX*OY*DATA_LEN-1 : 0]  		w_ot_ci_acc;
reg     [OX*OY*DATA_LEN-1 : 0]  		r_ot_ci_acc;
reg     [OX*OY*DATA_LEN-1 : 0]  		ot_ci_acc;

assign w_ot_ci_acc = ot_ci_acc;

always @ (*) begin
    if ((KERNEL1 < state) && (state < ACC )) begin
        r_ot_kernel_acc[(ich*OY*OX + oy*OX + ox-2)*DATA_LEN +: DATA_LEN]=w_o_kernel_acc;
    end
    else r_ot_kernel_acc = r_ot_kernel_acc; 

    if (acc) ot_ci_acc = r_ot_kernel_acc[2*OX*OY*DATA_LEN +: OX*OY*DATA_LEN] + r_ot_kernel_acc[1*OX*OY*DATA_LEN +: OX*OY*DATA_LEN] + r_ot_kernel_acc[0*OX*OY*DATA_LEN +: OX*OY*DATA_LEN];
    else ot_ci_acc = ot_ci_acc;
end

    always @(*) begin
		case(state) 
            IDLE: begin
                    if(i_in_valid)next_state=KERNEL0;
                    else next_state =IDLE;
            end
			KERNEL0: next_state = KERNEL1;
			KERNEL1: next_state = KERNEL2;
			KERNEL2: next_state = KERNEL3;
			KERNEL3: next_state = KERNEL4;
			KERNEL4: next_state = KERNEL5;
			KERNEL5: next_state = KERNEL6;
            KERNEL6: next_state = KERNEL7;
			KERNEL7: next_state = KERNEL8;
            KERNEL8: next_state = KERNEL9;
			KERNEL9: next_state = KERNEL10;
            KERNEL10: next_state = KERNEL11;
			KERNEL11: next_state = KERNEL12;
            KERNEL12: next_state = KERNEL13;
			KERNEL13: next_state = KERNEL14;
            KERNEL14: next_state = KERNEL15;
			KERNEL15: next_state = KERNEL16;
            KERNEL16: next_state = KERNEL17;
			KERNEL17: next_state = KERNEL18;
            KERNEL18: next_state = KERNEL19;
			KERNEL19: next_state = KERNEL20;
            KERNEL20: next_state = KERNEL21;
			KERNEL21: next_state = KERNEL22;
            KERNEL22: next_state = KERNEL23;
			KERNEL23: next_state = KERNEL24;
            KERNEL24: next_state = KERNEL25;
			KERNEL25: next_state = KERNEL26;
            KERNEL26: next_state = KERNEL27;
			KERNEL27: next_state = KERNEL28;
            KERNEL28: next_state = KERNEL29;
			KERNEL29: next_state = WAIT1;
            WAIT1: next_state = WAIT2;
            WAIT2: next_state = ACC;
            ACC: next_state = DONE;
            DONE: next_state = DONE;
            default: next_state = IDLE;
		endcase
	end

// F/F
always @(posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= {OX*OY*DATA_LEN{1'b0}};
    end else if(i_soft_reset) begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= {OX*OY*DATA_LEN{1'b0}};
    end else if(acc)begin
        r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= w_ot_ci_acc[0 +: OX*OY*DATA_LEN];
    end
end

assign o_ot_valid = w_valid;
assign o_ot_ci_acc = r_ot_ci_acc;

endmodule