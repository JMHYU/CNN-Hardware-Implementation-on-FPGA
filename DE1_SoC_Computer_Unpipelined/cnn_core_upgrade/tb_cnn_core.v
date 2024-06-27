`include "timescale.vh"

`define TRACE_IN_FMAP 	"./files/in_fmap.txt" 
`define TRACE_IN_WEIGHT "./files/in_weight.txt"
`define TRACE_OT_RESULT "./files/ot_result_rtl.txt"

module tb_cnn_core ();
`include "defines_cnn_core.vh"

integer fp_f, fp_w, fp_result;
integer ix, iy;						// Input
integer kx, ky; 					// Kernel
integer ox, oy;						// Output
integer in, out;					// #input / #output
integer ich, och;	 				// in / ouput channel

reg clk , reset_n, soft_reset;

reg     [OCH*ICH*KX*KY*DATA_LEN-1 : 0] 	cnn_weight 	;
reg                               		in_valid  	;
reg     [IN*ICH*IX*IY*DATA_LEN-1 : 0]  	in_fmap    	;
wire                              		w_ot_valid  ;
wire    [IN*OCH*OX*OY*DATA_LEN-1 : 0]	w_ot_fmap   ;

// clk gen
always
    #5 clk = ~clk;

initial begin
//initialize value
$display("initialize value [%0d]", $time);
    reset_n 	<= 1;
    clk     	<= 0;
	soft_reset  <= 0;
	cnn_weight 	<= 0;
	in_valid  	<= 0;
	in_fmap    	<= 0;
// reset_n gen
$display("Reset! [%0d]", $time);
# 10
   reset_n <= 0;
# 10
   reset_n <= 1;
// start
$display("Read Input! [%0d]", $time);
read_trace(cnn_weight, in_fmap);
$display("Start! [%0d]", $time);
@(posedge clk); begin
	in_valid <= 1;
	#10 in_valid <= 0;
end
	
wait(w_ot_valid);
@(negedge clk);
$display("Write Output! [%0d]", $time);
write_result(w_ot_fmap);
# 100
$display("Finish! [%0d]", $time);
$stop;
end
 
// Call DUT
cnn_topCore u_cnn_topCore(
    // Clock & Reset
    .clk             (clk         	),
    .reset_n         (reset_n     	),
    .i_soft_reset    (soft_reset	),
    .i_cnn_weight    (cnn_weight	),
    .i_in_valid      (in_valid  	),
    .i_in_fmap       (in_fmap   	),
    .o_ot_valid      (w_ot_valid  	),
    .o_ot_fmap       (w_ot_fmap   	)      
    );

// $fscanf return the number of successful assignments performed.
task read_trace;
	output     [OCH*ICH*KX*KY*DATA_LEN-1 : 0]	cnn_weight 	;
	output     [IN*ICH*IX*IY*DATA_LEN-1 : 0]  	in_fmap    	;
	reg		   [7:0]							fmap, weight;
	integer										read_in,read_och,read_ich, result,temp;
	reg 										fcheck;
	begin
		fp_f = $fopen(`TRACE_IN_FMAP, "r");
		fp_w = $fopen(`TRACE_IN_WEIGHT, "r");
		fcheck = fp_f && fp_w;
		if(fcheck)
			$display("success file open");
   		else 
			$finish;
		for (in = 0; in < IN; in = in+1) begin
			for (ich = 0; ich < ICH; ich = ich+1) begin
				result = $fscanf(fp_f, "(%d,%d) ", read_in, read_ich);
				if(in != read_in) begin $finish; end
				if(ich != read_ich) begin $finish; end

				for (iy = 0; iy < IY; iy = iy+1) begin
					for (ix = 0; ix < IX; ix = ix+1) begin
						result = $fscanf(fp_f, "%d ", fmap);
						in_fmap[(in*ICH*IY*IX + ich*IY*IX + iy*IX + ix)*DATA_LEN +: DATA_LEN] = fmap;
					end
				end
				result = $fscanf(fp_f, "\n", temp);
			end
		end
		for (och = 0; och < OCH; och = och+1) begin
			for (ich = 0; ich < ICH; ich = ich+1) begin
				result = $fscanf(fp_w, "(%d,%d) ", read_och, read_ich);
				if(och != read_och) begin $finish; end
				if(ich != read_ich) begin $finish; end

				for (ky = 0; ky < KY; ky = ky+1) begin
					for (kx = 0; kx < KX; kx = kx+1) begin
						result = $fscanf(fp_w, "%d ", weight);
						cnn_weight[(och*ICH*KY*KX + ich*KY*KX + ky*KX + kx)*DATA_LEN +: DATA_LEN] = weight;
					end
				end
				result = $fscanf(fp_w, "\n", temp);
			end
		end

		$fclose(fp_f);
		$fclose(fp_w);
	end
endtask

task write_result;
	input    [IN*OCH*OX*OY*DATA_LEN-1 : 0] 	i_ot_fmap;
	integer									read_out,read_och, result,temp;
	reg [DATA_LEN-1 : 0]	ot_fmap;
	begin
		fp_result = $fopen(`TRACE_OT_RESULT, "w");

		for (out = 0; out < IN; out = out+1) begin
			for (och = 0; och < OCH; och = och+1) begin
				$fwrite(fp_result, "(%0d,%0d) ", out, och);
				$display("(%0d,%0d) ", out, och);
				for (oy = 0; oy < OY; oy = oy+1) begin
					for (ox = 0; ox < OX; ox = ox+1) begin
						ot_fmap = i_ot_fmap[(out*OCH*OY*OX + och*OY*OX + oy*OX + ox)*DATA_LEN +: DATA_LEN];
						$fwrite(fp_result, "%0d ", ot_fmap);
						$display("%0d ", ot_fmap);
					end
				end
				$fwrite(fp_result, "\n");
			end
			$fwrite(fp_result, "\n");
		end

		$fclose(fp_result);
	end
endtask

endmodule
