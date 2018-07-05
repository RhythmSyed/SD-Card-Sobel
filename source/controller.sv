// $Id: $
// File name:   controller.sv
// Created:     4/10/2018
// Author:      Daniel Gilmore
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: FSM controller for SD Sobel Edge Detection project
module controller
(
	input wire clk,
	input wire n_rst,
	input wire detect, //sd card detect signal
	input wire sd_error, //sd card error signal
	input wire eof, //received from image receiver when file is done processing
	input wire hold, //when low, indicates SD Interface has completed current command
	input wire enable, //signal from SD Interface for Image Receiver to start processing
	input wire buffer_full, //received from Image Receiver when ready to send data to SED
	input wire new_col, //received from Image Receiver when reading data from a new column
	input wire sed_done,
	input wire [31:0] img_size,
	input wire [15:0] w_address,

	output reg sd_read, //tells SD interface to send a read command
	output reg sd_write, //tells SD interface to send a write command
	output reg sd_change_size, //tells SD interface to send a change block size command
	output reg [31:0] sd_block_size, //new block size
	output reg read_header, //enables Image Receiver to read header data
	output reg read_buffer, //enables Image Receiver to read pixel data
	output reg sram_read, //signal to read data FROM the FIFO
	output reg sram_write, //signal to write data INTO the FIFO
	output reg sed_en, //enable for Sobel Edge Detection module
	output reg done, //signifies that the program is finished running
	output reg error, //signifies that the program has encountered an error
	output reg sd_cmd0, //setup commands for SD card
	output reg sd_cmd2,
	output reg sd_cmd3,
	output reg sd_cmd7,
	output reg sd_cmd8,
	output reg sd_acmd41,
	output reg [15:0] sram_address

);

typedef enum logic [5:0] {IDLE, SD_SETUP1, SD_FAILURE, FINISH, SD_SET_SIZE_HEADER, SD_READ_HEADER_CMD, READ_HEADER,
			READ_HEADER2, SD_WRITE_HEADER_CMD, CHECK_EOF, SD_SET_SIZE_PIXELS, SD_READ_PIXELS_CMD,
			READ_PIXELS, SED_ENABLE, STORE_SED_RESULT, SD_SET_SIZE_WRITE, SD_WRITE_DATA1, SD_WRITE_DATA2,
			SD_SETUP2, SD_SETUP3, SD_SETUP4, SD_SETUP5, SD_SETUP6, SD_SETUP7, SD_GET_WRITE_DATA}
state_type;
state_type state, nextstate;

always_ff @(posedge clk, negedge n_rst)
begin: StateReg
	if (n_rst == 0)
		state <= IDLE;
	else
		state <= nextstate;
end

always_comb begin
	nextstate = state;
	sd_cmd0 = 0;
	sd_cmd8 = 0;
	sd_acmd41 = 0;
	sd_cmd2 = 0;
	sd_cmd3 = 0;
	sd_cmd7 = 0;
	sd_read = 0;
	sd_write = 0;
	sd_change_size = 0;
	sd_block_size = sd_block_size;
	read_header = 0;
	read_buffer = 0;
	sram_read = 0;
	sram_write = 0;
	sed_en = 0;
	done = 0;
	error = 0;
	sram_address = 16'h36;
	case (state)
		IDLE: begin
			sd_block_size = '0;
			if (detect==1) 
				nextstate = SD_SETUP1;
		end

		SD_SETUP1: begin
			sd_cmd0 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SETUP2;
		end

		SD_SETUP2: begin
			sd_cmd8 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SETUP3;
		end

		SD_SETUP3: begin
			sd_acmd41 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SETUP4;
		end

		SD_SETUP4: begin
			sd_cmd2 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SETUP5;
		end

		SD_SETUP5: begin
			sd_cmd3 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SETUP6;
		end

		SD_SETUP6: begin
			sd_cmd7 = 1;
			if (!hold & sd_error)
				nextstate = SD_FAILURE;
			else if (!hold & !sd_error)
				nextstate = SD_SET_SIZE_HEADER;
		end

		SD_FAILURE: begin
			error = 1;
			done = 1;
		end

		SD_SET_SIZE_HEADER: begin
			sd_change_size = 1;
			sd_block_size = 32'd54;
			if (!hold)
				nextstate = SD_READ_HEADER_CMD;
		end

		SD_READ_HEADER_CMD: begin
			sd_read = 1;
			if (enable)
				nextstate = READ_HEADER;
		end

		READ_HEADER: begin
			read_header = 1;
			if (!hold)
				nextstate = SD_WRITE_HEADER_CMD;
		end

		SD_WRITE_HEADER_CMD: begin
			sd_write = 1;
			if (!hold)
				nextstate = SD_SET_SIZE_PIXELS;
		end

		SD_SET_SIZE_PIXELS: begin
			sd_change_size = 1;
			sd_block_size = 32'd3;
			if (!hold)
				nextstate = CHECK_EOF;
		end

		CHECK_EOF: begin
			if (eof)
				nextstate = SD_SET_SIZE_WRITE;
			else
				nextstate = SD_READ_PIXELS_CMD;
		end

		SD_READ_PIXELS_CMD: begin
			sd_read = 1;
			if (enable)
				nextstate = READ_PIXELS;
		end

		READ_PIXELS: begin
			read_buffer = 1;
			if (!hold & new_col & !buffer_full)
				nextstate = SD_READ_PIXELS_CMD;
			else if ((!hold & !new_col) | (!hold & buffer_full))
				nextstate = SED_ENABLE;
		end
		
		SED_ENABLE: begin
			sed_en = 1;
			if (sed_done)
				nextstate = STORE_SED_RESULT;
		end
		
		STORE_SED_RESULT: begin
			sram_write = 1;
			sram_address = w_address;
			nextstate = CHECK_EOF;
		end

		SD_SET_SIZE_WRITE: begin
			sd_change_size = 1;
			sd_block_size = img_size;
			if (!hold)
				nextstate = SD_GET_WRITE_DATA;
		end

		SD_WRITE_DATA1: begin
			sd_write = 1;
			sram_address = sram_address;
			sram_read = 1;
			nextstate = SD_WRITE_DATA2;
		end

		SD_WRITE_DATA2: begin
			sd_write = 1;
			sram_address = sram_address+1;
			if (hold)
				nextstate = SD_WRITE_DATA1;
			else
				nextstate = FINISH;
		end

		FINISH: begin
			done = 1;
		end
	endcase
end

endmodule