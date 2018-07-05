// $Id: $
// File name:   tb_ImageIO.sv
// Created:     4/17/2018
// Author:      Muhtadyuzzaman Syed
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: TestBench that serves as a simulated SD Card File Location For Read and Write.

`timescale 1ns / 100ps

module tb_fir_image();
	
	parameter		INPUT_FILENAME		= "./docs/test_1.bmp";
	parameter		RESULT1_FILENAME		= "./docs/filtered_1.bmp";
	parameter		RESULT2_FILENAME		= "./docs/filtered_2.bmp";
	parameter		RESULT3_FILENAME		= "./docs/filtered_3.bmp";
	
	// Define file io offset constants
	localparam SEEK_START	= 0;
	localparam SEEK_CUR		= 1;
	localparam SEEK_END		= 2;
	
	// Bitmap file based parameters
	localparam BMP_HEADER_SIZE_BYTES	= 14;	// The length of the BMP file header field in Bytes
	localparam PIXEL_ARR_PTR_ADDR			= BMP_HEADER_SIZE_BYTES - 4;
	localparam DIB_HEADER_C1_SIZE			= 40; // The length of the expected BITMAPINFOHEADER DIB header
	localparam DIB_HEADER_C2_SIZE			= 12; // The length of the expected BITMAPCOREHEADER DIB header
	localparam NO_COMPRESSION 				= 0;	// The compression mode value should be 0 if no compression is used (normal case)

	// Define local constants
	localparam NUM_VAL_BITS	= 16;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam CHECK_DELAY	= 1ns;
	localparam CLK_PERIOD		= 10ns;
	
	// Test coefficient constants
	localparam COEFF1 		= 16'h8000; // 1.0
	localparam COEFF_5 		= 16'h4000; // 0.5
	localparam COEFF_25 	= 16'h2000; // 0.25
	localparam COEFF_125 	= 16'h1000; // 0.125
	localparam COEFF0  		= 16'h0000; // 0.0
	
	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_reset;
	reg tb_data_ready;
	reg tb_load_coeff;
	reg [MAX_VAL_BIT:0] tb_sample_r;
	reg [MAX_VAL_BIT:0] tb_sample_g;
	reg [MAX_VAL_BIT:0] tb_sample_b;
	reg [MAX_VAL_BIT:0] tb_coeff;
	wire tb_one_k_samples_r;
	wire tb_one_k_samples_g;
	wire tb_one_k_samples_b;
	wire tb_modwait_r;
	wire tb_modwait_g;
	wire tb_modwait_b;
	wire tb_err_r;
	wire tb_err_g;
	wire tb_err_b;
	wire [MAX_VAL_BIT:0] tb_fir_out_r;
	wire [MAX_VAL_BIT:0] tb_fir_out_g;
	wire [MAX_VAL_BIT:0] tb_fir_out_b;
	
	// Declare Image Processing Test Bench Variables
	integer r;										// Loop variable for working with rows of pixels
	integer c;										// Loop variable for working with pixels in a row
	reg [7:0] tmp_byte;						// temp variable for read/writing bytes from/to files
	integer in_file;							// Input file handle
	integer res_file;							// Result file handle
	string  curr_res_filename;
	integer num_rows;							// The number of rows of pixels in the image file
	integer num_cols;						// The number of pixels pwer row in the image file
	integer num_pad_bytes;				// The number of padding bytes at the end of each row
	reg [2:0][7:0] in_pixel_val;	// The raw bytes read from the input file
	reg [2:0][7:0] res_pixel_val;	// The averaged values for the result file
	integer i;										// Loop variable for misc. for loops
	integer quiet_catch; // Just used to remove warnings about not capturing the value of the file function returns
	
	// The bitmap file header is 14 Bytes
	reg [(BMP_HEADER_SIZE_BYTES - 1):0][7:0] in_bmp_file_header;
	reg [(BMP_HEADER_SIZE_BYTES - 1):0][7:0] res_bmp_file_header;
	reg [31:0] in_image_data_ptr;		// The starting byte address of the pixel array in the input file
	reg [31:0] res_image_data_ptr;	// The starting byte address of the pixel array in the result file
	// The normal/supported DIB header is 40 Bytes
	reg [(DIB_HEADER_C1_SIZE - 1):0][7:0] dib_header;
	reg [31:0] dib_header_size;	// The dib header size is a 32-bit unsigned integer
	reg [31:0] image_width;			// The image width (pixels) is a 32-bit signed integer
	reg [31:0] image_height;		// The image height (pixels) is a 32-bit signed integer
	reg [15:0] num_pixel_bits;	// The number of pixels per bit (1, 4, 8, 16, 24, 32) is an unsigned integer
	reg [31:0] compression_mode;// The type of compression used (this test bench doesn't support compression)
	// Pixel array stuff
	integer row_size_bytes;	// Used to store the calculated row size for the pixel array
	
	// 2-D Filter approach buffers
	reg [2:0][7:0] tb_input_image [][];
	reg [2:0][7:0] tb_row_pass_output [][];
	reg [2:0][7:0] tb_col_pass_output [][];
	reg [2:0][7:0] tb_merged_output [][];
	reg [8:0] tb_temp_merge_sum;
	
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


