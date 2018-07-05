// $Id: $
// File name:   flex_stp_sr.sv
// Created:     1/29/2018
// Author:      Matthew Hill
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: flex serial to parallel

module flex_stp_sr
#(
	NUM_BITS = 4,
	SHIFT_MSB = 1
)
(
	input wire n_rst,
	input wire clk,
	input wire shift_enable,
	input wire serial_in,
	output reg [NUM_BITS-1:0] parallel_out
);

	
	always_ff @ (posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			parallel_out <= '1;
		end else if (shift_enable == 1) begin
			if(SHIFT_MSB == 1) begin
				parallel_out <= {parallel_out[NUM_BITS-2:0], serial_in};
			end else begin
				parallel_out <= {serial_in, parallel_out[NUM_BITS-1:1]};
			end
		end else begin
			parallel_out <= parallel_out;
		end
	end
endmodule 