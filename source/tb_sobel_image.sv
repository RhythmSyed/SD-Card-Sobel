// $Id: $
// File name:   tb_sobel_image.sv
// Created:     4/23/2018
// Author:      Muhtadyuzzaman Syed
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: Test Sobel block, output edge detected image

`timescale 1ns / 100ps

module tb_sobel_image();
	
	parameter		INPUT_FILENAME		= "fruit.bmp";
	parameter		RESULT_FILENAME		= "sobel_image.bmp";
	
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
	localparam NUM_VAL_BITS	= 8;
	localparam MAX_VAL_BIT	= NUM_VAL_BITS - 1;
	localparam CHECK_DELAY	= 1ns;
	localparam CLK_PERIOD		= 10ns;
	
	// Test bench dut port signals
	reg tb_clk;
	reg tb_n_reset;
	reg tb_enable;
	reg tb_done;
	reg [71:0] tb_image_data;
	reg [7:0] tb_new_pixel;
	
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
	reg [7:0] in_pixel_val;	// The raw bytes read from the input file
	reg [7:0] res_pixel_val;	// The averaged values for the result file
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
	reg [7:0] tb_input_image [][];
	reg [7:0] tb_output_image [][];
	reg [7:0] tb_image_buffer [][];
	
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
	
	// Task for extracting the input file's header info
	task read_input_header;
	begin
		// Open the input file
		in_file = $fopen(INPUT_FILENAME, "rb");
		// Read in the Bitmap file header information (data is stored in little-endian (LSB first) format)
		for(i = 0; i < BMP_HEADER_SIZE_BYTES; i = i + 1) // Read the data in LSB format
		begin
			// Read a byte at a time
			quiet_catch = $fscanf(in_file,"%c" , in_bmp_file_header[i]);
		end
		// Extract the pixel array pointer (contains the file byte offset of the first byte of the pixel array)
		in_image_data_ptr[31:0] = in_bmp_file_header[(BMP_HEADER_SIZE_BYTES - 1):PIXEL_ARR_PTR_ADDR]; // The pixel array pointer is a 4 byte unsigned integer at the end of the header
		// Read in the DIB header information (LSB format)
		quiet_catch = $fscanf(in_file,"%c" , dib_header[0]);
		quiet_catch = $fscanf(in_file,"%c" , dib_header[1]);
		quiet_catch = $fscanf(in_file,"%c" , dib_header[2]);
		quiet_catch = $fscanf(in_file,"%c" , dib_header[3]);
		dib_header_size = dib_header[3:0];
		if(DIB_HEADER_C1_SIZE == dib_header_size)
		begin
			$display("Input bitmap file uses the BITMAPINFOHEADER type of DIB header");
			for(i = 4; i < dib_header_size; i = i + 1) // Read data in LSB format
			begin
				// Read a byte at a time
				quiet_catch = $fscanf(in_file,"%c" , dib_header[i]);
			end
			
			// Exract useful values from the header
			image_width				= dib_header[7:4];		// image width is bytes 4-7
			image_height			= dib_header[11:8];		// image height is bytes 8-11
			num_pixel_bits		= dib_header[15:14];	// number of bits per pixel is bytes 14 & 15
			compression_mode	= dib_header[19:16];	// compression mode is bytes 16-19
			
			$info("signature '%0d'", in_bmp_file_header[1:0]);
			$info("size of BMP file in bytes '%0d'", in_bmp_file_header[5:2]);
			$info("reversed1 '%0d'", in_bmp_file_header[7:6]);
			$info("reversed2 '%0d'", in_bmp_file_header[9:8]);
			$info("offset '%0d'", in_bmp_file_header[13:10]);
			$info("size of BITMAPINFOHEADER '%0d'", dib_header[3:0]);
			$info("image width '%0d'", dib_header[7:4]);
			$info("image height '%0d'", dib_header[11:8]);
			$info("number of planes '%0d'", dib_header[13:12]);
			$info("number of bits '%0d'", dib_header[15:14]);
			$info("compression type '%0d'", dib_header[19:16]);
			$info("size of image data in bytes '%0d'", dib_header[23:20]);
			$info("horizontal resolution '%0d'", dib_header[27:24]);
			$info("vertical resolution '%0d'", dib_header[31:28]);
			$info("number of colors in image '%0d'", dib_header[35:32]);
			$info("number of important colors '%0d'", dib_header[39:36]);
			
				
			if(16'd8 != num_pixel_bits)
				$fatal("This input file is using a pixel size (%0d)that is not supported, only 8bpp is supported", num_pixel_bits);
			
			if(NO_COMPRESSION != compression_mode)
				$fatal("This input file is using compression, this is not supported by this test bench");
			
		end
		else if(DIB_HEADER_C2_SIZE == dib_header_size)
		begin
			$display("Input bitmap file uses the BITMAPCOREHEADER  type of DIB header");
			for(i = 4; i < dib_header_size; i = i + 1) // Read data in LSB format
			begin
				// Read a byte at a time
				quiet_catch = $fscanf(in_file,"%c" , dib_header[i]);
			end
			
			// Exract useful values from the header
			image_width			= {16'd0,dib_header[5:4]};	// image width is bytes 4 & 5
			image_height		= {16'd0,dib_header[7:6]};	// image height is bytes 6 & 7
			num_pixel_bits	= dib_header[11:10];				// number of bits per pixel is bytes 10 & 11
			
			if(16'd8 != num_pixel_bits)
				$fatal("This input file is using a pixel size (%0d)that is not supported, only 8bpp is supported", num_pixel_bits);
		end
		else
		begin
			$fatal("Unsupported DIB header size of %0d found in input file", dib_header_size);
		end
		
		// Shouldn't need a color palette -> skip it
		res_image_data_ptr = BMP_HEADER_SIZE_BYTES + dib_header_size;
		// Should be at the start of the image data (there shoudln't be a color palette)
		// Skip padding if needed
		//if($ftell(in_file) != in_image_data_ptr)
			//quiet_catch = $fseek(in_file, in_image_data_ptr, SEEK_START);
	end
	endtask
	
	// Task to populate the input image buffer
	task extract_input_image;
	begin
		// Calculate image data row size
		//row_size_bytes = (((((num_pixel_bits + 7) / 8) * image_width) + 3) / 4) * 4;
		// Calculate the number of rows in the pixel array
		num_rows = image_height;
		// Calculate the number of pixels per row
		num_cols = image_width;
		// Calculate the number of padding bytes per row
		//num_pad_bytes	= row_size_bytes - (num_cols * 3);

		tb_input_image = new[num_rows];
		for(r = 0; r < num_rows; r = r + 1)
		begin
			tb_input_image[r] = new[num_cols];
			for(c = 0; c < num_cols; c = c + 1)
			begin
				// Get the input pixel value from the file (LSB format)
				quiet_catch = $fscanf(in_file, "%c", tb_input_image[r][c]);
				//$info("Storing pixel value '%0d'", tb_input_image[r][c]);
			end
			// Finished a row of pixels
			// Skip past any padding bytes in the input file (get to the next row)
			//quiet_catch = $fseek(in_file, num_pad_bytes, SEEK_CUR);
			// Ready to start working on the next row of pixels
		end
		
		// Done with pixel array section of input and row-dimension 1-D pass
		// Done with input file
		$fclose(in_file);
	end
	endtask
	
	// Task for generating the output file's header info to match the input one's
	task generate_output_header;
		input string filename;
	begin
		// Open the result file
		curr_res_filename = filename;
		res_file = $fopen(filename, "wb");
		// Create the bmp file header field (shouldn't change from input file, except for potetinally the image data ptr field)
		res_bmp_file_header = in_bmp_file_header;
		// Correct the image data ptr for discarding the color palette when allowed
		res_bmp_file_header[(BMP_HEADER_SIZE_BYTES - 1):PIXEL_ARR_PTR_ADDR] = res_image_data_ptr;
		// Write the bitmap header field to the result file
		for(i = 0; i < BMP_HEADER_SIZE_BYTES; i = i + 1) // Write data in LSB format
		begin
			// Write a byte at a time
			//$info("Storing header(%0d) '%0d'", i, res_bmp_file_header[i]);
			$fwrite(res_file, "%c", res_bmp_file_header[i]);
		end
		// Create the DIB header for the result file (shouldn't change from input file)
		for(i = 0; i < dib_header_size; i = i + 1) // Write data in LSB format
		begin
			// Write a byte at a time
			//$info("Storing header(%0d) '%0d'", i, dib_header[i]);
			$fwrite(res_file, "%c", dib_header[i]);
		end
		
		// Should be at the start of the image data (there shoudln't be a color palette)
		// Skip padding if needed
		if($ftell(res_file) != res_image_data_ptr)
			quiet_catch = $fseek(res_file, res_image_data_ptr, SEEK_START);
	end
	endtask
	
	initial
	begin
		tb_n_reset = 1'b1;
		tb_enable = 1'b1;
		
		#(1ns);
		
		read_input_header;
		
		extract_input_image;
		
		generate_output_header(RESULT_FILENAME);
		
		reset_dut;

		tb_image_buffer = new[num_rows];
		for (r = 0; r < num_rows; r = r + 1)
		begin
			tb_image_buffer[r] = new[num_cols];
			for(c = 0; c < num_cols; c = c + 1)
			begin
				tb_image_buffer[r][c] = 0;
			end
		end

		for (r = 0; r < (num_rows - 2); r = r + 1)
		begin
			for(c = 0; c < (num_cols - 2); c = c + 1)
			begin
				tb_image_data[7:0] = tb_input_image[r][c]; 
				tb_image_data[15:8] = tb_input_image[r][c + 1];
				tb_image_data[23:16] = tb_input_image[r][c + 2];
				tb_image_data[31:24] = tb_input_image[r + 1][c];
				tb_image_data[39:32] = tb_input_image[r + 1][c + 1];
				tb_image_data[47:40] = tb_input_image[r + 1][c + 2];
				tb_image_data[55:48] = tb_input_image[r + 2][c];
				tb_image_data[63:56] = tb_input_image[r + 2][c + 1];
				tb_image_data[71:64] = tb_input_image[r + 2][c + 2];
				
				@(posedge tb_clk);
				@(posedge tb_clk);
				@(posedge tb_clk);
				
				
				$info("Storing pixel value '%0d'", tb_new_pixel);
				
				tb_image_buffer[r+1][c+1] = tb_new_pixel;
				//$fwrite(res_file, "%c", tb_image_buffer[r][c]);

				#(5 * CLK_PERIOD);
			end
		end

		for (r = 0; r < num_rows; r = r + 1)
		begin
			for(c = 0; c < num_cols; c = c + 1)
			begin
				$fwrite(res_file, "%c", tb_image_buffer[r][c]);
			end
		end
		
		$fwrite(res_file, "%c", 8'd0);
		$fclose(res_file);
		
	end
	
	
	
endmodule

