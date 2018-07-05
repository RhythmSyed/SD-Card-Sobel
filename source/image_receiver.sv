// $Id: $
// File name:   image_receiver.sv
// Created:     4/10/2018
// Author:      Peiyuan Li
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: receive header and generate header done flag, receiver ima and send them to sobel edge

`timescale 1ns / 10ps

module image_receiver (
	input wire clk,
	input wire n_rst,
	//from SD 	
	input wire [23:0] pixel_data,
	input wire [63:0] header_data_in,

	//from controller	
	input wire read_buffer, 
	input wire read_header, 
	
	//to controller	
	output reg buffer_full, 
	output reg [31:0] image_size,
		
	//to FIFO		
	//output reg [63:0] header_data_out, //header_data send to FIFO
	
	//to Sobel Edge	
	output reg [71:0] image_buffer,
	
	//to SD
	
	output reg image_complete,
	
	output reg [15:0] w_address,
	output reg [31:0] r_address,
	output reg new_col,
	
	input wire [15:0] default_address
);

	reg [31:0] width;  //output from width_calculator  and input to address_calculator
	reg [31:0] height;  //output from height_calculator and input to address_calculator
	wire height_flag;
	wire width_flag;
	reg [31:0] count_out_height;  
	reg [31:0] count_out_width;  
	
	always_ff @ (posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			width <= '0;
			height <= '0;
		end
		else if(read_header == '1) begin	
			width <= header_data_in[31:0];
			height <= header_data_in[63:32];
		end
		else begin
			width <= width;
			height <= height;
		end
	end	
	
	assign image_size = width * height;
	
	reg [2:0] count_out_buffer;  //output from BUFFER_COUNTER
	wire buffer_flag;  //output from BUFFER_COUNTER
	
	flex_counter #(32) HEIGHT_COUNTER (.clk(clk), .n_rst(n_rst), .clear(height_flag), .count_enable(read_buffer), .rollover_val(height), .count_out(count_out_height), .rollover_flag(height_flag));
	flex_counter #(32) WIDTH_COUNTER (.clk(clk), .n_rst(n_rst), .clear(), .count_enable(read_buffer && height_flag), .rollover_val(width - 2), .count_out(count_out_width), .rollover_flag(width_flag));
	
	//assign value to new_col	
	always_comb begin
		if(count_out_height == 0 || count_out_height == 1 || count_out_height == 2) begin
			new_col = 1;
		end
		else begin
			new_col = 0;
		end
	end

	flex_counter #(3) BUFFER_COUNTER (.clk(clk), .n_rst(n_rst), .clear(!new_col), .count_enable(read_buffer), .rollover_val(3'd3), .count_out(count_out_buffer), .rollover_flag(buffer_flag));
	
	assign image_complete = width_flag;
	assign buffer_full = count_out_buffer == 3 ? 1 : 0;
	
	//calculate the address
	always_ff @ (posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			r_address <= '0;
			w_address <= '0;
		end
		else if (read_buffer == 1) begin
			w_address <= r_address - width + 1 + width;
			r_address <= default_address + width * count_out_height + count_out_width;				
		end
		else begin
			r_address <= r_address;
			w_address <= w_address;
		end
	end
	
	//always_ff @ (posedge clk, negedge n_res) beign
	//	if (n_rst == 0) beign
					
	//	end
	//make the matrix for image_buffer
	always_ff @ (posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			image_buffer[7:0] = '0;
			image_buffer[15:8] = '0;
			image_buffer[23:16] = '0;
			image_buffer[31:24] = '0;
			image_buffer[39:32] = '0;
			image_buffer[47:40] = '0;
			image_buffer[55:48] = '0;
			image_buffer[63:56] = '0;
			image_buffer[71:64] = '0;
		end		
		else if(read_buffer == '1) begin	
			image_buffer[7:0] = image_buffer[31:24];
			image_buffer[15:8] = image_buffer[39:32];
			image_buffer[23:16] = image_buffer[47:40];
			image_buffer[31:24] = image_buffer[55:48];
			image_buffer[39:32] = image_buffer[63:56];
			image_buffer[47:40] = image_buffer[71:64];
			image_buffer[55:48] = pixel_data[23:16];
			image_buffer[63:56] = pixel_data[15:8];
			image_buffer[71:64] = pixel_data[7:0];	
		end
		else begin
			image_buffer[7:0] = image_buffer[7:0];
			image_buffer[15:8] = image_buffer[15:8];
			image_buffer[23:16] = image_buffer[23:16];
			image_buffer[31:24] = image_buffer[31:24];
			image_buffer[39:32] = image_buffer[39:32];
			image_buffer[47:40] = image_buffer[47:40];
			image_buffer[55:48] = image_buffer[55:48];
			image_buffer[63:56] = image_buffer[63:56];
			image_buffer[71:64] = image_buffer[71:64];		
		end
	end
	
	
	
endmodule
	


