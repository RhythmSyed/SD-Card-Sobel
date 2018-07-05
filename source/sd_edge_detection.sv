// $Id: $
// File name:   sd_edge_detection.sv
// Created:     4/17/2018
// Author:      Daniel Gilmore
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: High-level file for project
module sd_edge_detection
(
	input wire clk,
	input wire n_rst,

	inout [3:0] DAT,
	inout CMD,

	output reg done,
	output reg error,

	output reg sram_read,
	output reg sram_write,
	output reg [15:0] sram_address,
	output reg [7:0] new_pixel,
	input wire [7:0] output_data
	
);
reg [63:0] header_data;
reg read_header;
reg read_buffer;
reg [23:0] pixel_data;
reg [31:0] r_address;
reg [15:0] w_address;
reg new_col;
reg buffer_full;
reg eof;
reg [31:0]img_size;
reg sd_error;
reg enable;
reg hold;
reg detect;
reg sd_read; //tells SD interface to send a read command
reg sd_write; //tells SD interface to send a write command
reg sd_change_size; //tells SD interface to send a change block size command
reg [31:0] sd_block_size; //new block size
//reg sram_read; //signal to read data FROM the FIFO
//reg sram_write; //signal to write data INTO the FIFO
reg sed_en;//enable for Sobel Edge Detection module
reg sd_cmd0; //setup commands for SD card
reg sd_cmd2;
reg sd_cmd3;
reg sd_cmd7;
reg sd_cmd8;
reg sd_acmd41;
reg [71:0] image_buffer;
//reg [7:0] new_pixel;
reg sed_done;
//reg output_write;
//reg [7:0] output_data;

image_receiver Image_Receiver(
	.clk(clk),
	.n_rst(n_rst),
	//from SD 	
	.pixel_data(pixel_data),
	.header_data_in(header_data),
	//from controller	
	.read_buffer(read_buffer), 
	.read_header(read_header), 
	//to controller	  
	.buffer_full(buffer_full),
	.image_complete(eof),
	.image_size(img_size),  
	//to SRAM		
	.w_address(w_address), //sram address to store at
	//to Sobel Edge	
	.image_buffer(image_buffer),
	//to SD
	.r_address(r_address),
	.new_col(new_col),
	.default_address(16'h36)
);

sobelBlock sobel(
	.clk(clk),
	.n_rst(n_rst),
	.image_buffer(image_buffer),
	.enable(sed_en),
	.new_pixel(new_pixel),
	.done(sed_done)
);

controller Controller(
	.clk(clk),
	.n_rst(n_rst),
	.detect(detect), //sd card detect signal
	.sd_error(sd_error), //sd card error signal
	.eof(eof), //received from image receiver when file is done processing
	.hold(hold), //when low, indicates SD Interface has completed current command
	.enable(enable), //signal from SD Interface for Image Receiver to start processing
	.buffer_full(buffer_full), //received from Image Receiver when ready to send data to SED
	.new_col(new_col), //received from Image Receiver when reading data from a new column
	.sed_done(sed_done),
	.img_size(img_size),
	.w_address(w_address),

	.sd_read(sd_read), //tells SD interface to send a read command
	.sd_write(sd_write), //tells SD interface to send a write command
	.sd_change_size(sd_change_size), //tells SD interface to send a change block size command
	.sd_block_size(sd_block_size), //new block size
	.read_header(read_header), //enables Image Receiver to read header data
	.read_buffer(read_buffer), //enables Image Receiver to read pixel data
	.sram_read(sram_read), //signal to read data FROM the FIFO
	.sram_write(sram_write), //signal to write data INTO the FIFO
	.sed_en(sed_en), //enable for Sobel Edge Detection module
	.done(done), //signifies that the program is finished running
	.error(error), //signifies that the program has encountered an error
	.sd_cmd0(sd_cmd0), //setup commands for SD card
	.sd_cmd2(sd_cmd2),
	.sd_cmd3(sd_cmd3),
	.sd_cmd7(sd_cmd7),
	.sd_cmd8(sd_cmd8),
	.sd_acmd41(sd_acmd41),
	.sram_address(sram_address)
);

SD_Card_Interface sd_interface
(
	.clk(clk),
	.n_rst(n_rst),
	.read(sd_read), // tells SD_Card_Interface to read from SD Card
	.write(sd_write), // tells SD_Card_Interface to write to SD Card
	.change_size(sd_change_size), //tells SD_Card_Interface to change block size
	.block_size(sd_block_size), //gives block size for change_size
	.cmd0(sd_cmd0), //tells SD card to send command 0
	.cmd2(sd_cmd2),
	.cmd3(sd_cmd3),
	.cmd7(sd_cmd7),
	.cmd8(sd_cmd8),
	.acmd41(sd_acmd41),
	.getData(sram_read), //tells SD card that its receiving data from the fifo
	.fifo_data(output_data),
	.r_address(r_address),
	.w_address(32'd5000),
	.CMD(CMD),
	.Data(DAT),
	.Image_data(pixel_data), //3 pixel buffer
	.Header_data(header_data), //height and width from header
	.sd_error(sd_error), 
	.detect(detect),
	.enable(enable), //tells image_receiver that pixel data is ready
	.hold(hold) //deassert when command is finished sending
);

endmodule
