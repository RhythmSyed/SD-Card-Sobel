// $Id: $
// File name:   tb_image_receiver.sv
// Created:     4/17/2018
// Author:      Peiyuan Li
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: test bench for image receiver

`timescale 1ns / 10ps

module tb_image_receiver();

	localparam CLK_PERIOD = 2.5;
	localparam CHECK_DELAY = 1;
	
	
	reg tb_clk;
	reg tb_n_rst;
	reg [23:0]tb_pixel_data;
	reg [63:0]tb_header_data_in;
	reg tb_read_buffer;
	reg tb_read_header;
	reg tb_buffer_full;
	reg [63:0]tb_header_data_out;
	reg [16:0] tb_w_address;
	reg [31:0] tb_r_address;
	reg tb_new_col;
	reg [71:0]tb_image_buffer;
	reg tb_image_complete;
	reg [15:0]tb_default_address = 16'h00;
	reg [31:0] tb_image_size;

	image_receiver DUT (
		.clk(tb_clk), 
		.n_rst(tb_n_rst), 
		.pixel_data(tb_pixel_data), 
		.header_data_in(tb_header_data_in), 
		.read_buffer(tb_read_buffer), 
		.read_header(tb_read_header), 
		.buffer_full(tb_buffer_full), 
		.header_data_out(tb_header_data_out), 
		.image_buffer(tb_image_buffer), 
		.w_address(tb_w_address), 
		.r_address(tb_r_address), 
		.new_col(tb_new_col), 
		.image_complete(tb_image_complete),
		.default_address(tb_default_address),
		.image_size(tb_image_size)
	);

	//generate clock signal
	always
	begin
		tb_clk = 1'b0;
		#(CLK_PERIOD/2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD/2.0);
	end
	
	initial begin
	tb_n_rst = '0;
	@(posedge tb_clk);
	tb_n_rst = '1;
	@(posedge tb_clk);
	tb_read_buffer = 1'b0;
	@(posedge tb_clk);	
	tb_pixel_data = 24'H232323;
	tb_header_data_in = 64'H0000003000000030;  //first 4 byte is width, last 4 byte is height  48*48 pixels
	@(posedge tb_clk);
	@(posedge tb_clk);
	@(posedge tb_clk);
	tb_read_header = 1'b1;
	@(posedge tb_clk);
	@(posedge tb_clk);
	@(posedge tb_clk);
	tb_read_header = 1'b0;
	tb_read_buffer = 1'b1;
	@(posedge tb_clk);
	@(posedge tb_clk);
	@(posedge tb_clk);
	//tb_read_buffer = 1'b0;
	@(posedge tb_clk);
	
	end			
	

endmodule
