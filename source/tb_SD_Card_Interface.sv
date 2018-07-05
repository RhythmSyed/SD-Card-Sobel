// $Id: $
// File name:   tb_SD_Card_Interface.sv
// Created:     4/21/2018
// Author:      Daniel Gilmore
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: test bench for SD Card Interface
`timescale 1ns/10ps

module tb_SD_Card_Interface();

	//Define local constants
	localparam CLK_PERIOD		= 10ns;

	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_rst;
	reg tb_read;
	reg tb_write;
	reg tb_change_size;
	reg [31:0] tb_block_size;
	reg tb_cmd0; 
	reg tb_cmd2; 
	reg tb_cmd3;
	reg tb_cmd7; 
	reg tb_cmd8;
	reg tb_acmd41;
	reg tb_getData;
	wire tb_CMD;
	wire [3:0] tb_data;
	reg [7:0] tb_fifo_data;	
	reg [31:0] tb_r_address;	
	reg [31:0] tb_w_address;	

	wire tb_sd_read;
	wire tb_sd_write;
	wire tb_sd_change_size;
	wire [23:0] tb_image_data;
	wire [63:0] tb_header_data; 
	wire tb_sd_error; 
	wire tb_detect;
	wire tb_enable; 
	wire tb_hold;
	
	// Test bench verification signals
	integer tb_test_case_num;

	task reset_dut;
	begin
		// Activate the design's reset (does not need to be synchronize with clock)
		tb_n_rst = 1'b0;
		
		// Wait for a couple clock cycles
		@(posedge tb_clk);
		@(posedge tb_clk);
		
		// Release the reset
		@(negedge tb_clk);
		tb_n_rst = 1;
		
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
	SD_Card_Interface DUT(
				.clk(tb_clk),
				.n_rst(tb_n_reset),
				.read(tb_read),
				.write(tb_write),
				.change_size(tb_change_size),
				.block_size(tb_block_size),
				.cmd0(tb_cmd0),
				.cmd2(tb_cmd2),
				.cmd3(tb_cmd3),
				.cmd7(tb_cmd7),
				.cmd8(tb_cmd8),
				.acmd41(tb_acmd41),
				.getData(tb_getData),
				.fifo_data(tb_fifo_data),
				.r_address(tb_r_address),
				.w_address(tb_w_address),
				.CMD(tb_CMD),
				.Data(tb_data),
				.Image_data(tb_image_data),
				.Header_data(tb_header_data),
				.sd_error(tb_sd_error),
				.detect(tb_detect),
				.enable(tb_enable),
				.hold(tb_hold)
			);
	
	// Task for sending a signle coefficient
	// Test bench process
	initial
	begin
		// Initial values
		tb_test_case_num = 0;
		tb_n_rst = 1'b1;
		tb_read = 0;
		tb_write = 0;
		tb_change_size = 0;
		tb_block_size = '0;
		tb_cmd0 = 0; 
		tb_cmd2 = 0; 
		tb_cmd3 = 0;
		tb_cmd7 = 0; 
		tb_cmd8 = 0;
		tb_acmd41 = 0;
		tb_getData = 0;
		tb_fifo_data = '0;	
		tb_r_address = '0;	
		tb_w_address = '0;	
		
		// Wait for some time before starting test cases
		#(1ns);
		
		// Power on reset (just inspect on waves)
		reset_dut;
		
		// Test case 1: Check values after n_reset
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD)

		// Test case 2: cmd 0
		tb_test_case_num = tb_test_case_num + 1;
		tb_cmd0 = 1;
		#(CLK_PERIOD*56);
		tb_cmd0 = 0;

		// Test case 3: cmd 8
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_cmd8 = 1;
		#(CLK_PERIOD*56);
		tb_cmd8 = 0;

		// test case 4: acmd41
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_acmd41 = 1;
		#(CLK_PERIOD*56);
		tb_acmd41 = 0;

		// Test case 4: cmd 2
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_cmd2 = 1;
		#(CLK_PERIOD*56);
		tb_cmd2 = 0;

		// Test case 5: cmd 3
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_cmd3 = 1;
		#(CLK_PERIOD*56);
		tb_cmd3 = 0;

		// Test case 6: cmd 7
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_cmd7 = 1;
		#(CLK_PERIOD*56);
		tb_cmd7 = 0;

		// Test case 7: read
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_read = 1;
		#(CLK_PERIOD*56);
		tb_read = 0;

		// Test case 8: write
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_write = 1;
		#(CLK_PERIOD*56);
		tb_write = 0;

		// Test case 9: change size 54
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_change_size = 1;
		tb_block_size = 32'd54;
		#(CLK_PERIOD*56);
		tb_change_size = 0;

		// Test case 9: change size 3
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD);
		tb_change_size = 1;
		tb_block_size = 32'd3;
		#(CLK_PERIOD*56);
		tb_change_size = 0;
	end
endmodule