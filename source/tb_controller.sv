// $Id: $
// File name:   tb_controller.sv
// Created:     4/21/2018
// Author:      Daniel Gilmore
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: test bench for controller FSM
`timescale 1ns/10ps

module tb_controller();

	//Define local constants
	localparam CLK_PERIOD		= 10ns;

	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_reset;
	reg tb_detect;
	reg tb_sd_error;
	reg tb_eof;
	reg tb_hold;
	reg tb_enable; //signal from SD Interface for Image Receiver to start processing
	reg tb_header_valid; //received from Image Receiver if header is valid
	reg tb_buffer_full; //received from Image Receiver when ready to send data to SED
	reg tb_new_col; //received from Image Receiver when reading data from a new column
	reg tb_sed_done;
	reg [31:0] tb_img_size;	

	wire tb_sd_read;
	wire tb_sd_write;
	wire tb_sd_change_size;
	wire [31:0] tb_sd_block_size;
	wire tb_read_header; //enables Image Receiver to read header data
	wire tb_read_buffer; //enables Image Receiver to read pixel data
	wire tb_sram_read; //signal to read data FROM the FIFO
	wire tb_sram_write; //signal to write data INTO the FIFO
	wire tb_sed_en; //enable for Sobel Edge Detection module
	wire tb_done; //signifies that the program is finished running
	wire tb_error; //signifies that the program has encountered an error
	wire tb_sd_cmd0; //setup commands for SD card
	wire tb_sd_cmd2;
	wire tb_sd_cmd3;
	wire tb_sd_cmd7;
	wire tb_sd_cmd8;
	wire tb_sd_acmd41;
	
	// Test bench verification signals
	integer tb_test_case_num;
	reg tb_expected_err;
	
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
	controller DUT(
				.clk(tb_clk),
				.n_rst(tb_n_reset),
				.detect(tb_detect),
				.sd_error(tb_sd_error),
				.eof(tb_eof),
				.hold(tb_hold),
				.enable(tb_enable),
				.buffer_full(tb_buffer_full),
				.new_col(tb_new_col),
				.sed_done(tb_sed_done),
				.img_size(tb_img_size),
				.sd_read(tb_sd_read),
				.sd_write(tb_sd_write),
				.sd_change_size(tb_sd_change_size),
				.sd_block_size(tb_sd_block_size),
				.read_header(tb_read_header),
				.read_buffer(tb_read_buffer),
				.sram_read(tb_sram_read),
				.sram_write(tb_sram_write),
				.sed_en(tb_sed_en),
				.done(tb_done),
				.error(tb_error),
				.sd_cmd0(tb_sd_cmd0),
				.sd_cmd2(tb_sd_cmd2),
				.sd_cmd3(tb_sd_cmd3),
				.sd_cmd7(tb_sd_cmd7),
				.sd_cmd8(tb_sd_cmd8),
				.sd_acmd41(tb_sd_acmd41)
			);
	
	// Task for sending a signle coefficient
	// Test bench process
	initial
	begin
		// Initial values
		tb_test_case_num = 0;
		tb_n_reset = 1'b1;
		tb_detect = 1'b0;
		tb_sd_error = 1'b0;
		tb_eof = 1'b0;
		tb_hold = 1'b1;
		tb_enable = 1'b0; //signal from SD Interface for Image Receiver to start processing
		tb_header_valid = 1'b0; //received from Image Receiver if header is valid
		tb_buffer_full = 1'b0; //received from Image Receiver when ready to send data to SED
		tb_new_col = 1'b0; //received from Image Receiver when reading data from a new column
		tb_sed_done = 1'b0;
		tb_img_size = '0;	
		
		// Wait for some time before starting test cases
		#(1ns);
		
		// Power on reset (just inspect on waves)
		reset_dut;
		
		// Test case 1: Check values after n_reset
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD)

		// Test case 2: setup everything
		tb_test_case_num = tb_test_case_num + 1;
		tb_detect = 1;
		tb_hold = 0;
		#(CLK_PERIOD);
		//cmd0
		#(CLK_PERIOD);
		//cmd8
		#(CLK_PERIOD);
		//acmd41
		#(CLK_PERIOD);
		//cmd2
		#(CLK_PERIOD);
		//cmd3
		#(CLK_PERIOD);
		//cmd7
		#(CLK_PERIOD);

		// Test case 3: set size then read header
		tb_test_case_num = tb_test_case_num + 1;
		tb_hold = 1;
		#(CLK_PERIOD * 48);
		tb_hold = 0;
		#(CLK_PERIOD);
		tb_hold = 1;
		#(CLK_PERIOD*48 + CLK_PERIOD*108);
		tb_hold = 0;

		// Test case 4: extract header info
		tb_test_case_num = tb_test_case_num + 1;
		tb_enable = 1;
		#(CLK_PERIOD);
		tb_enable = 0;
	
		// Test case 5: write header
		tb_test_case_num = tb_test_case_num + 1;
		tb_hold = 1;
		#(CLK_PERIOD*48 + CLK_PERIOD*108);
		tb_hold = 0;
		#(CLK_PERIOD)

		
		// test case 6: change block size
		tb_test_case_num = tb_test_case_num + 1;
		tb_hold = 1;
		#(CLK_PERIOD * 48);
		tb_hold = 0;

		// test case 7: read first pixel data
		tb_test_case_num = tb_test_case_num + 1;
		#(CLK_PERIOD)
		//read 1st row
		tb_hold = 1;
		#(CLK_PERIOD * 48);
		tb_hold = 0;
		#(CLK_PERIOD)
		//read 2nd row
		tb_hold = 1;
		#(CLK_PERIOD * 48);
		tb_hold = 0;
		#(CLK_PERIOD)
		//read 3rd row
		tb_hold = 1;
		#(CLK_PERIOD * 48);
		tb_hold = 0;
		#(CLK_PERIOD);
		
	end

endmodule