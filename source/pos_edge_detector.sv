// $Id: $
// File name:   pos_edge_detector.sv
// Created:     4/19/2018
// Author:      Matthew Hill
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: positive edge detector for detecting commands

module pos_edge_detector
(
	input cmd,
	input clk,
	output cmd_detect
);
reg prev_cmd;

always_ff @(posedge clk) begin	
	prev_cmd <= cmd;
end

assign cmd_detect = cmd & ~prev_cmd;

endmodule

