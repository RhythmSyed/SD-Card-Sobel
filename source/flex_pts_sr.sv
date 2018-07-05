// $Id: $
// File name:   flex_pts_sr.sv
// Created:     1/29/2018
// Author:      Peiyuan Li
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: n bits pts

module flex_pts_sr
  #(
    parameter NUM_BITS = 4,
    parameter SHIFT_MSB = 1
    )
   (	  
		   input wire 			 clk,
	  	   input wire 			 n_rst,
		   input wire 			 load_enable,
		   input wire 			 shift_enable,
		   input wire                    [(NUM_BITS-1):0] parallel_in,
		   output reg                    serial_out
    );
   
   reg [(NUM_BITS-1):0] cur;
   reg [(NUM_BITS - 1):0] next;
   int i;


	 always_ff @ (posedge clk, negedge n_rst)
		begin
		if (n_rst == 0) begin
		for( i = 0; i < NUM_BITS; i = i + 1) begin
	  		cur[i] = 1;
		end
		end
		else
			cur = next;
		end

	always_comb
	begin
	if (load_enable == 1)
		next = parallel_in;
	else
		if (shift_enable == 1) begin
			if (SHIFT_MSB == 1)
				next = {cur[(NUM_BITS-2):0],1'b1};	
			else
				next = {1'b1, cur[(NUM_BITS-1):1]};
		end		
		else
			next = cur;

	if(SHIFT_MSB == 1)
		serial_out = cur[(NUM_BITS - 1)];  
	else
		serial_out = cur[0];
end
endmodule

