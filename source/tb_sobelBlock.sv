// $Id: $
// File name:   tb_sobel.sv
// Created:     4/17/2018
// Author:      Muhtadyuzzaman Syed
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: TestBench for Sobel Block

`timescale 1ns/10ps

module tb_sobelBlock();

	// Define local constants
	localparam NUM_VAL_BITS	= 16;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam CHECK_DELAY	= 1ns;
	localparam CLK_PERIOD		= 10ns;
	
	
	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_reset;
	reg [71:0] tb_image_data;
	reg tb_enable;
	reg [7:0] tb_new_pixel;
	reg tb_done;
	reg [3:0] tb_test_num;

	task reset_dut;
	begin
		// Activate the design's reset (does not need to be synchronize with clock)
		tb_n_reset = 1'b0;
		
		// Wait for a couple clock cycles
		@(posedge tb_clk);
		@(posedge tb_clk);
		
		// Release the reset
		@(negedge tb_clk);
		tb_n_reset = 1;
		
		// Wait for a while before activating the design
		@(posedge tb_clk);
		@(posedge tb_clk);
	end
	endtask
	
	// Clock gen block
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_PERIOD / 2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD / 2.0);
	end
	
	// DUT portmap
	sobelBlock DUT(.clk(tb_clk), .n_rst(tb_n_reset), .image_buffer(tb_image_data), .enable(tb_enable), .new_pixel(tb_new_pixel), .done(tb_done));


	initial 
	begin
		//Test Case 1
		tb_test_num = 1;
		@(posedge tb_clk);
		tb_n_reset = 1'b1;
		@(posedge tb_clk);
		tb_enable = 1;
		
		tb_image_data[7:0] = 8'hFF; 
		tb_image_data[15:8] = 8'hFF;
		tb_image_data[23:16] = 8'hFF;
		tb_image_data[31:24] = 8'hFF;
		tb_image_data[39:32] = 8'hFF;
		tb_image_data[47:40] = 8'hFF;
		tb_image_data[55:48] = 8'hFF;
		tb_image_data[63:56] = 8'hFF;
		tb_image_data[71:64] = 8'hFF;

		@(posedge tb_clk);

		if (tb_new_pixel == 0)
			$info("Test Case 1: Passed!");
		else
			$error("Test Case 1: Failed!");

		//Test Case 2
		tb_test_num = 2;
		@(posedge tb_clk);
		tb_n_reset = 1'b1;
		@(posedge tb_clk);
		tb_enable = 1;
		
		tb_image_data[7:0] = 8'd1; 
		tb_image_data[15:8] = 8'd2;
		tb_image_data[23:16] = 8'd3;
		tb_image_data[31:24] = 8'd4;
		tb_image_data[39:32] = 8'd5;
		tb_image_data[47:40] = 8'd6;
		tb_image_data[55:48] = 8'd7;
		tb_image_data[63:56] = 8'd8;
		tb_image_data[71:64] = 8'd9;

		@(posedge tb_clk);
		

		if (tb_new_pixel == 25)
			$info("Test Case 1: Passed!");
		else
			$error("Test Case 1: Failed!");

		//Test Case 3
		tb_test_num = 3;
		@(posedge tb_clk);
		tb_n_reset = 1'b1;
		@(posedge tb_clk);
		tb_enable = 1;
		
		tb_image_data[7:0] = 8'd9; 
		tb_image_data[15:8] = 8'd8;
		tb_image_data[23:16] = 8'd7;
		tb_image_data[31:24] = 8'd6;
		tb_image_data[39:32] = 8'd5;
		tb_image_data[47:40] = 8'd4;
		tb_image_data[55:48] = 8'd3;
		tb_image_data[63:56] = 8'd2;
		tb_image_data[71:64] = 8'd1;

		@(posedge tb_clk);
		

		if (tb_new_pixel == 25)
			$info("Test Case 1: Passed!");
		else
			$error("Test Case 1: Failed!");

		

	end

endmodule

	
