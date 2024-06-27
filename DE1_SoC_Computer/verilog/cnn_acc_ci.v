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
`include "defines_computer.vh"

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
// FSM
//==============================================================================
parameter IDLE = 6'd0;
parameter LOAD_ich0 = 6'd1;
parameter TRANS_ich0_oy0_ox0 = 6'd2;
parameter TRANS_ich0_oy0_ox1 = 6'd3;
parameter TRANS_ich0_oy0_ox2 = 6'd4;
parameter TRANS_ich0_oy0_ox3 = 6'd5;
parameter TRANS_ich0_oy0_ox4 = 6'd6;
parameter TRANS_ich0_oy1_ox0 = 6'd7;
parameter TRANS_ich0_oy1_ox1 = 6'd8;
parameter TRANS_ich0_oy1_ox2 = 6'd9;
parameter TRANS_ich0_oy1_ox3 = 6'd10;
parameter TRANS_ich0_oy1_ox4 = 6'd11;

parameter TRANS_ich1_oy0_ox0 = 6'd12;
parameter TRANS_ich1_oy0_ox1 = 6'd13;
parameter TRANS_ich1_oy0_ox2 = 6'd14;
parameter TRANS_ich1_oy0_ox3 = 6'd15;
parameter TRANS_ich1_oy0_ox4 = 6'd16;
parameter TRANS_ich1_oy1_ox0 = 6'd17;
parameter TRANS_ich1_oy1_ox1 = 6'd18;
parameter TRANS_ich1_oy1_ox2 = 6'd19;
parameter TRANS_ich1_oy1_ox3 = 6'd20;
parameter TRANS_ich1_oy1_ox4 = 6'd21;

parameter TRANS_ich2_oy0_ox0 = 6'd22;
parameter TRANS_ich2_oy0_ox1 = 6'd23;
parameter TRANS_ich2_oy0_ox2 = 6'd24;
parameter TRANS_ich2_oy0_ox3 = 6'd25;
parameter TRANS_ich2_oy0_ox4 = 6'd26;
parameter TRANS_ich2_oy1_ox0 = 6'd27;
parameter TRANS_ich2_oy1_ox1 = 6'd28;
parameter TRANS_ich2_oy1_ox2 = 6'd29;
parameter TRANS_ich2_oy1_ox3 = 6'd30;
parameter TRANS_ich2_oy1_ox4 = 6'd31;
parameter WAIT1 = 6'd32;
parameter WAIT2 = 6'd33;
parameter WAIT3 = 6'd34;
parameter ACCUM = 6'd35;
parameter DONE = 6'd36;



reg [5:0] state, next_state;
wire         w_in_valid;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= IDLE;
    else if (i_soft_reset) state <= IDLE;
    else state <= next_state;
end


always @(*) begin
    case (state)
        IDLE: begin
                if (i_in_valid) next_state = LOAD_ich0;
                else next_state = IDLE;
            end
        LOAD_ich0: next_state = TRANS_ich0_oy0_ox0;
        TRANS_ich0_oy0_ox0: next_state = TRANS_ich0_oy0_ox1;
        TRANS_ich0_oy0_ox1: next_state = TRANS_ich0_oy0_ox2;
        TRANS_ich0_oy0_ox2: next_state = TRANS_ich0_oy0_ox3;
        TRANS_ich0_oy0_ox3: next_state = TRANS_ich0_oy0_ox4;
        TRANS_ich0_oy0_ox4: next_state = TRANS_ich0_oy1_ox0;
        TRANS_ich0_oy1_ox0: next_state = TRANS_ich0_oy1_ox1;
        TRANS_ich0_oy1_ox1: next_state = TRANS_ich0_oy1_ox2;
        TRANS_ich0_oy1_ox2: next_state = TRANS_ich0_oy1_ox3;
        TRANS_ich0_oy1_ox3: next_state = TRANS_ich0_oy1_ox4;
        TRANS_ich0_oy1_ox4: next_state = TRANS_ich1_oy0_ox0;
        TRANS_ich1_oy0_ox0: next_state = TRANS_ich1_oy0_ox1;
        TRANS_ich1_oy0_ox1: next_state = TRANS_ich1_oy0_ox2;
        TRANS_ich1_oy0_ox2: next_state = TRANS_ich1_oy0_ox3;
        TRANS_ich1_oy0_ox3: next_state = TRANS_ich1_oy0_ox4;
        TRANS_ich1_oy0_ox4: next_state = TRANS_ich1_oy1_ox0;
        TRANS_ich1_oy1_ox0: next_state = TRANS_ich1_oy1_ox1;
        TRANS_ich1_oy1_ox1: next_state = TRANS_ich1_oy1_ox2;
        TRANS_ich1_oy1_ox2: next_state = TRANS_ich1_oy1_ox3;
        TRANS_ich1_oy1_ox3: next_state = TRANS_ich1_oy1_ox4;
        TRANS_ich1_oy1_ox4: next_state = TRANS_ich2_oy0_ox0;
        TRANS_ich2_oy0_ox0: next_state = TRANS_ich2_oy0_ox1;
        TRANS_ich2_oy0_ox1: next_state = TRANS_ich2_oy0_ox2;
        TRANS_ich2_oy0_ox2: next_state = TRANS_ich2_oy0_ox3;
        TRANS_ich2_oy0_ox3: next_state = TRANS_ich2_oy0_ox4;
        TRANS_ich2_oy0_ox4: next_state = TRANS_ich2_oy1_ox0;
        TRANS_ich2_oy1_ox0: next_state = TRANS_ich2_oy1_ox1;
        TRANS_ich2_oy1_ox1: next_state = TRANS_ich2_oy1_ox2;
        TRANS_ich2_oy1_ox2: next_state = TRANS_ich2_oy1_ox3;
        TRANS_ich2_oy1_ox3: next_state = TRANS_ich2_oy1_ox4;
        TRANS_ich2_oy1_ox4: next_state = WAIT1;
        WAIT1: next_state = WAIT2;
        WAIT2: next_state = WAIT3;
        WAIT3: next_state = ACCUM;
        ACCUM: next_state = DONE;
        DONE: next_state = DONE;
       
        default: next_state = IDLE;
    endcase
end


//==============================================================================
// Data Enable Signals
//==============================================================================
wire    	r_valid;

assign r_valid = (state==DONE) ? 1: 0;
assign w_in_valid = i_in_valid;
//==============================================================================
// mul_acc kenel instance
//==============================================================================


reg    [KX*KY*DATA_LEN-1 : 0]   w_cnn_weight;    
reg    [IX*IY*DATA_LEN-1 : 0]  	w_in_fmap;    	
reg    [KX*KY*DATA_LEN-1 : 0]   w_in_fmap_kernel;


always @(posedge clk) begin
    if(!reset_n) w_in_fmap_kernel <= 0;
    else if(i_soft_reset) w_in_fmap_kernel <= 0;
    else begin
            case(state)
TRANS_ich0_oy0_ox0: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy0_ox1: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy0_ox2: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy0_ox3: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy0_ox4: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy1_ox0: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy1_ox1: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy1_ox2: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy1_ox3: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich0_oy1_ox4: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy0_ox0: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy0_ox1: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy0_ox2: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy0_ox3: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy0_ox4: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy1_ox0: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy1_ox1: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy1_ox2: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy1_ox3: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich1_oy1_ox4: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy0_ox0: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy0_ox1: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy0_ox2: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy0_ox3: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy0_ox4: w_in_fmap_kernel <= {w_in_fmap[((0+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((0+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy1_ox0: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+0)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+0)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy1_ox1: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+1)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+1)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy1_ox2: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+2)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+2)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy1_ox3: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+3)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+3)*DATA_LEN +: KX*DATA_LEN]};
TRANS_ich2_oy1_ox4: w_in_fmap_kernel <= {w_in_fmap[((1+2)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+1)*IX+4)*DATA_LEN +: KX*DATA_LEN], w_in_fmap[((1+0)*IX+4)*DATA_LEN +: KX*DATA_LEN]};
default : w_in_fmap_kernel <= w_in_fmap_kernel;
        endcase
    end
end


always @(posedge clk) begin
    if(!reset_n) w_in_fmap <= 0;
    else if(i_soft_reset) w_in_fmap <= 0;
    else begin
            case(state)
            LOAD_ich0: w_in_fmap <= i_in_fmap[0*IX*IY*DATA_LEN +: IX*IY*DATA_LEN];
            TRANS_ich0_oy1_ox4: w_in_fmap <= i_in_fmap[1*IX*IY*DATA_LEN +: IX*IY*DATA_LEN];
            TRANS_ich1_oy1_ox4: w_in_fmap <= i_in_fmap[2*IX*IY*DATA_LEN +: IX*IY*DATA_LEN];
            default: w_in_fmap <= w_in_fmap;
            endcase
    end
end


always @(posedge clk) begin
    if(!reset_n) w_cnn_weight <= 0;
    else if(i_soft_reset) w_cnn_weight <= 0;
    else begin
            case(state)
            TRANS_ich0_oy0_ox0: w_cnn_weight <= i_cnn_weight[0*KX*KY*DATA_LEN +: KX*KY*DATA_LEN];
            TRANS_ich1_oy0_ox0: w_cnn_weight <= i_cnn_weight[1*KX*KY*DATA_LEN +: KX*KY*DATA_LEN];
            TRANS_ich2_oy0_ox0: w_cnn_weight <= i_cnn_weight[2*KX*KY*DATA_LEN +: KX*KY*DATA_LEN];
            default : w_cnn_weight <= w_cnn_weight;
            endcase
    end

end


wire                                    w_ot_valid_1bit;
wire    [DATA_LEN-1 : 0]  				w_ot_kernel_acc_1output;
reg    [ICH*OX*OY*DATA_LEN-1 : 0]      w_ot_kernel_acc;

cnn_kernel u_cnn_kernel(
                .clk             (clk            ),
                .reset_n         (reset_n        ),
                .i_soft_reset    (i_soft_reset   ),
                .i_cnn_weight    (w_cnn_weight   ),
                .i_in_valid      (w_in_valid),
                .i_in_fmap       (w_in_fmap_kernel),
                .o_ot_valid      (w_ot_valid_1bit),
                .o_ot_kernel_acc (w_ot_kernel_acc_1output)            
                );

always @(posedge clk) begin
    if(!reset_n)  w_ot_kernel_acc <= 0;
    else if(i_soft_reset) w_ot_kernel_acc <= 0;
    else begin
            case(state)
TRANS_ich0_oy0_ox3: w_ot_kernel_acc[(0*OY*OX + 0*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy0_ox4: w_ot_kernel_acc[(0*OY*OX + 0*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy1_ox0: w_ot_kernel_acc[(0*OY*OX + 0*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy1_ox1: w_ot_kernel_acc[(0*OY*OX + 0*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy1_ox2: w_ot_kernel_acc[(0*OY*OX + 0*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy1_ox3: w_ot_kernel_acc[(0*OY*OX + 1*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich0_oy1_ox4: w_ot_kernel_acc[(0*OY*OX + 1*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy0_ox0: w_ot_kernel_acc[(0*OY*OX + 1*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy0_ox1: w_ot_kernel_acc[(0*OY*OX + 1*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy0_ox2: w_ot_kernel_acc[(0*OY*OX + 1*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy0_ox3: w_ot_kernel_acc[(1*OY*OX + 0*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy0_ox4: w_ot_kernel_acc[(1*OY*OX + 0*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy1_ox0: w_ot_kernel_acc[(1*OY*OX + 0*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy1_ox1: w_ot_kernel_acc[(1*OY*OX + 0*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy1_ox2: w_ot_kernel_acc[(1*OY*OX + 0*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy1_ox3: w_ot_kernel_acc[(1*OY*OX + 1*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich1_oy1_ox4: w_ot_kernel_acc[(1*OY*OX + 1*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy0_ox0: w_ot_kernel_acc[(1*OY*OX + 1*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy0_ox1: w_ot_kernel_acc[(1*OY*OX + 1*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy0_ox2: w_ot_kernel_acc[(1*OY*OX + 1*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy0_ox3: w_ot_kernel_acc[(2*OY*OX + 0*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy0_ox4: w_ot_kernel_acc[(2*OY*OX + 0*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy1_ox0: w_ot_kernel_acc[(2*OY*OX + 0*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy1_ox1: w_ot_kernel_acc[(2*OY*OX + 0*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy1_ox2: w_ot_kernel_acc[(2*OY*OX + 0*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy1_ox3: w_ot_kernel_acc[(2*OY*OX + 1*OX + 0)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
TRANS_ich2_oy1_ox4: w_ot_kernel_acc[(2*OY*OX + 1*OX + 1)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
WAIT1: w_ot_kernel_acc[(2*OY*OX + 1*OX + 2)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
WAIT2: w_ot_kernel_acc[(2*OY*OX + 1*OX + 3)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
WAIT3: w_ot_kernel_acc[(2*OY*OX + 1*OX + 4)*DATA_LEN +: DATA_LEN] <= w_ot_kernel_acc_1output;
default :  w_ot_kernel_acc <= w_ot_kernel_acc;
endcase
end
end


//==============================================================================
// ci_acc = ci_acc + kernel_acc
//==============================================================================

reg     [OX*OY*DATA_LEN-1 : 0]  		r_ot_ci_acc;

always @(posedge clk) begin
    if(!reset_n)  r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= 0;
    else if(i_soft_reset) r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= 0;
    else begin
            case(state)
            ACCUM: r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= w_ot_kernel_acc[0*OX*OY*DATA_LEN +: OX*OY*DATA_LEN] + w_ot_kernel_acc[1*OX*OY*DATA_LEN +: OX*OY*DATA_LEN] + w_ot_kernel_acc[2*OX*OY*DATA_LEN +: OX*OY*DATA_LEN];
            default : r_ot_ci_acc[0 +: OX*OY*DATA_LEN] <= r_ot_ci_acc[0 +: OX*OY*DATA_LEN];
        endcase
    end
end



assign o_ot_valid = r_valid;
assign o_ot_ci_acc = r_ot_ci_acc;

endmodule