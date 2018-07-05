// $Id: $
// File name:   flex_counter.sv
// Created:     1/29/2018
// Author:      Peiyuan Li
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: counter

module flex_counter
  #(
    	parameter NUM_CNT_BITS = 4
    )
    (
	input wire clk,
	input wire n_rst,
	input wire clear,
	input wire count_enable,
	input wire [(NUM_CNT_BITS-1):0] rollover_val,
	output reg [(NUM_CNT_BITS-1):0] count_out,
	output reg rollover_flag
    );

	
	reg [(NUM_CNT_BITS-1):0] current_count;
	reg [(NUM_CNT_BITS-1):0] next_count;
	reg current_rollover_flag;
	reg next_rollover_flag;

	always_ff @ (posedge clk, negedge n_rst) begin
		if( n_rst == 0 ) begin
			current_count <= '0;
			current_rollover_flag <= 1'b0;
		end
		else begin
			current_count <= next_count;
			current_rollover_flag <= next_rollover_flag;
		end

	end
	always_comb begin
		next_count = current_count;
		next_rollover_flag = current_rollover_flag;
		if(clear == 1) begin
	   		next_count = '0;
	  		next_rollover_flag = 0;
		end
		else begin
			if (count_enable == 1) begin
		
			   	if(next_count == rollover_val - 1) begin
					next_count = current_count + 1;	
					next_rollover_flag = 1'b1;
				end
				else if(next_count >= rollover_val) begin
					next_count = 1;
					next_rollover_flag = 0;
				end
				else begin
					next_rollover_flag = 0;
					next_count = current_count + 1;	
				end
			end
			else begin
				next_count = current_count;
				next_rollover_flag = current_rollover_flag;
			end 
   		end
	end 
	   

	assign count_out = current_count;
	assign rollover_flag = current_rollover_flag;
endmodule
				

					
		

















