module mat_ops#(

	parameter READ    = 3'b000,
	parameter CNN_RUN = 3'b001,
	parameter WRITE   = 3'b010,
	parameter DONE    = 3'b011,
	parameter IDLE	  = 3'b111,

	//parameter READ_READ0 = 4'd0,
	//parameter READ_READ1 = 4'd1,
	//parameter READ_READ2 = 4'd2,
	//parameter READ_READ3 = 4'd3,
	//parameter READ_READ4 = 4'd4,
	//parameter READ_READ5 = 4'd5,
	//parameter READ_READ6 = 4'd6,
	//parameter READ_READ7 = 4'd7,
	//parameter READ_WAIT  = 4'd8,
	parameter READ_DONE  = 4'd14,
	parameter READ_IDLE  = 4'd15,

	// parameter WRITE_WRITE0 = 4'd0,
	// parameter WRITE_WRITE1 = 4'd1,
	// parameter WRITE_WRITE2 = 4'd2,
	// parameter WRITE_WRITE3 = 4'd3,
	// parameter WRITE_WRITE4 = 4'd4,
	// parameter WRITE_WRITE5 = 4'd5,
	// parameter WRITE_WRITE6 = 4'd6,
	// parameter WRITE_WRITE7 = 4'd7,
    parameter WRITE_DONE   = 4'd8,
	parameter WRITE_IDLE   = 4'd15
)(
	input 					 		i_clk,
	input 					 		i_rstn,
	input							i_start,
	///////////// SRAM a //////////
	input   [ROW_SIZE-1:0]	  	  	i_read_data_A,
	output	[ADDRESS_SIZE-1:0]	  	o_address_A,
	output  						o_wr_en_A,
	
	///////////// SRAM b //////////
	input   [ROW_SIZE-1:0]	  	  	i_read_data_B,
	output	[ADDRESS_SIZE-1:0]	  	o_address_B,
	output  						o_wr_en_B,

	output  [ROW_SIZE-1:0]	  	  	o_write_data_B,
	
	///////////// SRAM C //////////
	input   [ROW_SIZE-1:0]	  	  	i_read_data_C,
	output	[ADDRESS_SIZE-1:0]	  	o_address_C,
	output  						o_wr_en_C,

	output  [ROW_SIZE-1:0]	  	  	o_write_data_C,
	
	output  [2:0]					o_state,
	output	[3:0]					o_read_state,
	output							o_cnn_done,
	output	[3:0]					o_write_state,
	output							o_done
);
`include "defines_computer.vh"

	reg		[2:0] state;     
	reg  	[2:0] next_state; 
	
	wire  	[3:0] read_state_a;
	wire  	[3:0] read_state_b;
	wire  	[3:0] read_state_c;
	
	wire  		  w_ot_valid;

	wire		  w_valid;
	
	wire  	[3:0] write_state_b;
	wire  	[3:0] write_state_c;
	
	assign o_read_state 	= (read_state_a && read_state_b && read_state_c);
	assign o_cnn_done  		= w_ot_valid;
	assign o_write_state	= (write_state_b && write_state_c);
	
	wire read_start  ;
	wire read_done  ;
	wire cnn_start;
	wire cnn_done;
	wire write_start ;
	wire write_done ;
	wire read_reset ;
	
	//write data
    wire [ADDRESS_SIZE-1:0] 	write_address_B;
	wire [ADDRESS_SIZE-1:0] 	write_address_C;
	
	//read data
    wire [ADDRESS_SIZE-1:0] 	read_address_A;
	wire [ADDRESS_SIZE-1:0] 	read_address_B;
	wire [ADDRESS_SIZE-1:0] 	read_address_C;
	
	wire w_en_B;
	wire w_en_C;
	
	//concat infmap
	wire [INPUT_SIZE-1:0]			infmap;			//input1 + input2
	wire [(DATA_LEN*IY*IX*ICH)-1:0]	read_B;			//fmap input1
	wire [(DATA_LEN*IY*IX*ICH)-1:0]	read_C;			//fmap input2
	
	assign infmap = {read_B, read_C};
	
	//concat output
	wire [OUTPUT_SIZE-1:0]			cnn_out;		//output from cnn_topCore
	wire [(DATA_LEN*OCH*OY*OX)-1:0]	cnn_out_B;		//output1
	wire [(DATA_LEN*OCH*OY*OX)-1:0]	cnn_out_C;		//output2
	
	assign {cnn_out_B, cnn_out_C} = cnn_out;
	
	wire [DATA_LEN*M*4-1:0]		w_write_cnn_B;		//8x4 matrix (read from memory)
	wire [DATA_LEN*M*4-1:0]		w_write_cnn_C;		//8x4 matrix (read from memory)
	
	//weight
	wire [ROW_SIZE*12-1:0]		read_weight;		//read from memory
	wire [WEIGHT_SIZE-1:0]		weight_A;			//weight
	
	//reconstruct weight data
	genvar i;
	generate
	for(i=0; i<ICH*OCH; i=i+1) begin: WEIGHT_PARSE
		assign weight_A[DATA_LEN*KX*KY*i +: DATA_LEN*KX*KY] = read_weight[ROW_SIZE*2*i +: DATA_LEN*KX*KY];
	end
	endgenerate

	
	//reconstruct output data
	assign w_write_cnn_B = {{(6*DATA_LEN){1'b0}}, cnn_out_B[(DATA_LEN*OY*OX) +: (DATA_LEN*OY*OX)], {(6*DATA_LEN){1'b0}}, cnn_out_B[0 +: (DATA_LEN*OY*OX)]};
	assign w_write_cnn_C = {{(6*DATA_LEN){1'b0}}, cnn_out_C[(DATA_LEN*OY*OX) +: (DATA_LEN*OY*OX)], {(6*DATA_LEN){1'b0}}, cnn_out_C[0 +: (DATA_LEN*OY*OX)]};

	
	//state logic
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn) begin
			state <= IDLE;
		end
		else begin
			state <= next_state;
		end	
	end
	
	assign o_state = state;
	
	always @(*) begin
		case(state) 
			IDLE:       begin
							if(i_start)  		next_state = READ;
							else 	     		next_state = IDLE;
						end	
			READ:       begin	
							if(read_done)  		next_state = CNN_RUN;
							else 	     		next_state = READ;		
						end	
			CNN_RUN:    begin			    	     	
							if(cnn_done)		next_state = WRITE;
							else 				next_state = CNN_RUN;
						end					
			WRITE:      begin	
							if(write_done)  	next_state = DONE;
							else 	     		next_state = WRITE;
						end	
			DONE:       begin	
												next_state = IDLE;
						end 
		endcase      
	end
	

	assign read_start 	= (state == IDLE   )   &&	(next_state     == READ);
	assign read_done  	= (state == READ   )   &&	(read_state_a   == READ_DONE)	&&	(read_state_b   == READ_DONE)	&&	(read_state_c   == READ_DONE);
	assign cnn_start 	= (state == READ   )   &&	(next_state     == CNN_RUN);
	assign cnn_done 	= (state == CNN_RUN)   &&	(w_ot_valid  == 1'b1);
	assign write_start 	= (state == CNN_RUN)   &&	(next_state     == WRITE);
	assign write_done  	= (state == WRITE  )   &&	(write_state_b 	== WRITE_DONE)	&&	(write_state_c	== WRITE_DONE);
	assign read_reset  	= (state == DONE   );
	assign o_done      	= (state == DONE   );
	assign o_address_A 	= read_address_A;
	assign o_address_B 	= (w_en_B == 1'b1) ? (write_address_B) : read_address_B;
	assign o_address_C 	= (w_en_C == 1'b1) ? (write_address_C) : read_address_C;
	assign o_wr_en_A   	= 1'b0;
	assign o_wr_en_B   	= (w_en_B == 1'b1) ? w_en_B : 1'b0;
	assign o_wr_en_C   	= (w_en_C == 1'b1) ? w_en_C : 1'b0;
	
																	//OFFSET mapping!
M10K_read_buffer #(.DATA_LEN(DATA_LEN), .ADDRESS_SIZE(ADDRESS_SIZE), .OFFSET(READ_A_ADDR_OFFSET)) s1
(
	.i_clk         (i_clk),			
	.i_rstn        (i_rstn),               
	.i_read_reset  (read_reset),           
	.i_read_start  (read_start),           
	.i_read_data   (i_read_data_A),        
				                           
	.o_store_mat   (read_weight),             		//port mapping!
	.o_read_addr   (read_address_A),            
	.o_state       (read_state_a)            
);

																	//OFFSET mapping!
M10K_read_buffer #(.DATA_LEN(DATA_LEN), .ADDRESS_SIZE(ADDRESS_SIZE), .OFFSET(READ_B_ADDR_OFFSET)) s2
(
	.i_clk		   (i_clk),
	.i_rstn  	   (i_rstn),
	.i_read_reset  (read_reset),
	.i_read_start  (read_start),
	.i_read_data   (i_read_data_B),
	
	.o_store_mat   (read_B),					//port mapping!
	.o_read_addr   (read_address_B),
	.o_state       (read_state_b)
);

																	//OFFSET mapping!
M10K_read_buffer #(.DATA_LEN(DATA_LEN), .ADDRESS_SIZE(ADDRESS_SIZE), .OFFSET(READ_C_ADDR_OFFSET)) s3
(
	.i_clk		   (i_clk),
	.i_rstn  	   (i_rstn),
	.i_read_reset  (read_reset),
	.i_read_start  (read_start),
	.i_read_data   (i_read_data_C),
	
	.o_store_mat   (read_C),					//port mapping!
	.o_read_addr   (read_address_C),
	.o_state       (read_state_c)
);


cnn_topCore c0(
	.clk          (i_clk)   ,
    .reset_n      (i_rstn)   ,
    // .i_soft_reset ()   ,
    .i_cnn_weight (weight_A)   ,
    .i_in_valid   (cnn_start)   ,
    .i_in_fmap    (infmap)   ,
    .o_ot_valid   (w_ot_valid)   ,
    .o_ot_fmap    (cnn_out)         

);


																//OFFSET mapping!
M10K_write #(.DATA_LEN(DATA_LEN), .ADDRESS_SIZE(ADDRESS_SIZE), .OFFSET(WRITE_B_ADDR_OFFSET)) w0
(
	.i_clk 		 	(i_clk ),
	.i_rstn 		(i_rstn),
	.i_write_start  (write_start),
	.i_in_mat 		(w_write_cnn_B),				//port mapping!
	 
	.o_write_addr 	(write_address_B),
	.o_write_data 	(o_write_data_B),
	.o_write_start  (w_en_B),
	.o_state 		(write_state_b)
	// .o_done		()
);

																//OFFSET mapping!
M10K_write #(.DATA_LEN(DATA_LEN), .ADDRESS_SIZE(ADDRESS_SIZE), .OFFSET(WRITE_C_ADDR_OFFSET)) w1
(
	.i_clk 		 	(i_clk ),
	.i_rstn 		(i_rstn),
	.i_write_start  (write_start),
	.i_in_mat 		(w_write_cnn_C),				//port mapping!
	 
	.o_write_addr 	(write_address_C),
	.o_write_data 	(o_write_data_C),
	.o_write_start  (w_en_C),
	.o_state 		(write_state_c)
	// .o_done		()
);


endmodule
