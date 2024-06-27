
module mat_ops_controller #(
	parameter POLLING				= 2'b11,	// wiat for HPS signal(onchip == 1)
	parameter START   		    	= 2'b00,	// Start read
	parameter OPS               	= 2'b01,	// Finish write
	parameter DONE        			= 2'b10		// Finish all
)
(
	input 					 		  	i_clk,
	input 					 		  	i_rstn,
	
	///////////// SRAM a //////////	
	input   [ROW_SIZE-1:0]	  	  	i_read_data_A,
	output	[ADDRESS_SIZE-1:0]	  	o_address_A,
	output  						o_wr_en_A,
		
	output 	[ROW_SIZE-1:0]	  	  	o_write_data_A,
		
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
	output	[3:0]					o_cnn_done,
	output	[3:0]					o_write_state,
	output							o_done
);
`include "defines_computer.vh"
	
	reg  [1:0] state;     
	reg  [1:0] next_state; 
	wire 	   poll_done;
	
	
	wire 							  	ops_start			  ;
	///////////// read a /////////	
	wire 	[ADDRESS_SIZE-1:0]	  	  	ops_address_A         ;
	wire   						 	  	ops_wr_en_A           ;
													
	///////////// read b //////////   	               
	wire	[ADDRESS_SIZE-1:0]	  	  	ops_address_B         ;
	wire  	    					  	ops_wr_en_B           ;
													
	///////////// write b //////////	  	                
	wire    [ROW_SIZE-1:0]	  	  		ops_write_data_B      ;	
	
	///////////// read c //////////   	               
	wire	[ADDRESS_SIZE-1:0]	  	  	ops_address_C         ;
	wire  	    					  	ops_wr_en_C           ;
													
	///////////// write c //////////	  	                
	wire    [ROW_SIZE-1:0]	  	  		ops_write_data_C      ;	
	
	
	wire    [2:0]					  	ops_state             ;
	wire	[3:0]					  	ops_read_state        ;
	wire	[3:0]					  	ops_mat_mul_state     ;
	wire	[3:0]					  	ops_write_state       ;
	wire							  	ops_done              ;
	
	
	always @(posedge i_clk, negedge i_rstn) begin
		if(!i_rstn) begin
			state <= POLLING;
		end
		else begin
			state <= next_state;
		end	
	end
	
	assign o_state = state;
	
	always @(*) begin
		case(state) 
			POLLING:        begin		
					         	if(poll_done)   next_state = START;
					         	else 	     	next_state = POLLING;
					        end                 
			START:          begin               
												next_state = OPS;
					        end	
			OPS:            begin 
								if(ops_done)    next_state = DONE;
					         	else 	     	next_state = OPS;
					        end	
			DONE:           begin               
					         					next_state = POLLING;
					        end 
			default: 	    					next_state = POLLING;
		endcase      
	end
	
	assign ops_start 		= (state == START);
	
	assign o_address_A		= ((state == POLLING) || (state == DONE)) ? {(ADDRESS_SIZE){1'b0}} : ops_address_A ;	//default 0
	assign o_wr_en_A        = (state == POLLING) ? 1'b0 : ((state == DONE) ? 1'b1 :  ops_wr_en_A) ; 				//turn on when finish everything
	assign o_write_data_A   = {(ROW_SIZE){1'b0}};																	//HPS handshake
	
	assign o_address_B      = ((state == POLLING) || (state == DONE)) ? {(ADDRESS_SIZE){1'b0}} : ops_address_B ;	//default 0
	assign o_wr_en_B        = ((state == POLLING) || (state == DONE)) ?		 1'b0			   : ops_wr_en_B   ;  	//turn on when finish MAC operation

	assign o_address_C      = ((state == POLLING) || (state == DONE)) ? {(ADDRESS_SIZE){1'b0}} : ops_address_C ;	//default 0
	assign o_wr_en_C        = ((state == POLLING) || (state == DONE)) ?		 1'b0			   : ops_wr_en_C   ;  	//turn on when finish MAC operation

	assign poll_done		= (state == POLLING) && (i_read_data_A[DATA_LEN-1:0] == {{(DATA_LEN-1){1'b0}}, 1'b1});	//HPS handshake
	assign o_done           = (state == DONE);
	
	mat_ops u0(
	.i_clk			 (i_clk				),
	.i_rstn          (i_rstn			),
	.i_start         (ops_start			),
						
	.i_read_data_A   (i_read_data_A		),
	.o_address_A     (ops_address_A		),
	.o_wr_en_A       (ops_wr_en_A		),
						
	.i_read_data_B   (i_read_data_B		),
	.o_address_B     (ops_address_B		),
	.o_wr_en_B       (ops_wr_en_B		),
						
	.o_write_data_B  (o_write_data_B	),
	
	.i_read_data_C   (i_read_data_C		),
	.o_address_C     (ops_address_C		),
	.o_wr_en_C       (ops_wr_en_C		),
						
	.o_write_data_C  (o_write_data_C	),
						
	.o_state         (ops_state			),
	.o_read_state    (o_read_state   	),
	.o_cnn_done		 (o_cnn_done		),
	.o_write_state   (o_write_state  	),
	.o_done          (ops_done         	)
);
	
endmodule
