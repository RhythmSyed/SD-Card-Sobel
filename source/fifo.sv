// $Id: $
// File name:   fifo.sv
// Created:     4/14/2018
// Author:      Muhtadyuzzaman Syed
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: Fifo Block

module rx_fifo
(
	input wire clk,
	input wire n_rst,
	input wire r_enable,
	input wire w_enable,
	input wire [7:0] w_data,
	output wire [7:0] r_data,
	output wire empty,
	output wire full

);

fifo fifo(.w_clk(clk), .r_clk(clk), .n_rst(n_rst), .r_enable(r_enable), .w_enable(w_enable), .w_data(w_data), .r_data(r_data), .empty(empty), .full(full));

endmodule
