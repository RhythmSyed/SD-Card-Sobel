// $Id: $
// File name:   SD_Card_Interface.sv
// Created:     4/10/2018
// Author:      Matthew Hill
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: SD_card interfacing for final project.

module SD_Card_Interface
(
	input clk,
	input n_rst,
	input read, // tells SD_Card_Interface to read from SD Card
	input write, // tells SD_Card_Interface to write to SD Card
	input change_size, //tells SD_Card_Interface to change block size
	input [31:0] block_size, //gives block size for change_size
	input cmd0, //tells SD card to send command 0
	input cmd2,
	input cmd3,
	input cmd7,
	input cmd8,
	input acmd41,
	input getData, //tells SD card that its receiving data from the fifo
	input [7:0] fifo_data,
	input [31:0] r_address,
	input [31:0] w_address,
	inout CMD,
	inout [3:0] Data,
	output [23:0] Image_data, //3 pixel buffer
	output [63:0] Header_data, //height and width from header
	output sd_error, 
	output detect,
	output enable, //tells image_receiver that pixel data is ready
	output hold //deassert when command is finished sending
);

	wire cmd_out;	
	
	//command detection to detect changes in cmd variables from controller
	reg [5:0] cmd_index;
	reg cmd0_detect;
	reg cmd2_detect;
	reg cmd3_detect;
	reg cmd7_detect;
	reg cmd8_detect;
	reg read_detect;
	reg write_detect;
	reg change_size_detect;

	reg save_argument;//signals for system to save the argument on the next clock cycle
	reg [5:0] curr_cmd_index;
	reg [31:0] curr_cmd_argument;
	reg [15:0] RCA;
	reg load_enable_cmd;
	reg shift_enable_cmd;
	reg [5:0] count;
	reg next_cmd_bit;
	reg curr_cmd_bit;
	wire [39:0] cmd_data;	
	reg cmd_Rollover;
	reg delayed_Rollover;
	//crc variables
	reg crc_bit;
	reg [6:0] curr_crc;
	reg [6:0] new_crc;
	wire [7:0] crc7_data;
	wire crc_load_enable;

	//CMD DETECTOR///////////////////////////////////////////////////////////////////////////////////////
	pos_edge_detector cmd0_d(.cmd(cmd0), .clk(clk), .cmd_detect(cmd0_detect));
	pos_edge_detector cmd2_d(.cmd(cmd2), .clk(clk), .cmd_detect(cmd2_detect));
	pos_edge_detector cmd3_d(.cmd(cmd3), .clk(clk), .cmd_detect(cmd3_detect));
	pos_edge_detector cmd7_d(.cmd(cmd7), .clk(clk), .cmd_detect(cmd7_detect));
	pos_edge_detector cmd8_d(.cmd(cmd8), .clk(clk), .cmd_detect(cmd8_detect));
	pos_edge_detector read_d(.cmd(read), .clk(clk), .cmd_detect(read_detect));
	pos_edge_detector write_d(.cmd(write), .clk(clk), .cmd_detect(write_detect));
	pos_edge_detector acmd41_d(.cmd(acmd41), .clk(clk), .cmd_detect(acmd41_detect));
	pos_edge_detector change_size_d(.cmd(change_size), .clk(clk), .cmd_detect(change_size_detect));
	
	//use as load enable for command shift register
	assign CMD = (shift_enable_cmd == 1'b1) ? curr_cmd_bit : 1'bz;
	assign save_argument = cmd0_detect || cmd2_detect || cmd3_detect || cmd7_detect || cmd8_detect || read_detect || write_detect || acmd41_detect || change_size_detect;
	//sets cmd_index
	always_ff @(posedge clk, negedge n_rst) begin //cmd_index outputs correct index for the cycle that its command is detected
		if(n_rst == 0) begin
			curr_cmd_index <= 6'd0;
		end else begin
		if (read == 1'b1) begin
			curr_cmd_index <= 6'd17;
		end
		else if (write == 1'b1) begin
			curr_cmd_index <= 6'd24;
		end
		else if (cmd0 == 1'b1) begin
			curr_cmd_index <= 6'd0;
		end
		else if (cmd2 == 1'b1) begin
			curr_cmd_index <= 6'd2;
		end
		else if (cmd3 == 1'b1) begin
			curr_cmd_index <= 6'd3;
		end
		else if (cmd7 == 1'b1) begin
			curr_cmd_index <= 6'd7;
		end
		else if (cmd8 == 1'b1) begin
			curr_cmd_index <= 6'd8;
		end
		else if (acmd41 == 1'b1) begin
			curr_cmd_index <= 6'd41;
		end
		else if (change_size == 1'b1) begin
			curr_cmd_index <= 6'd16;
		end
		else begin
			curr_cmd_index <= curr_cmd_index;
		end
		end
	end
	//storing cmd_index stable into a register if a new cmd is detected
	
	///////////////////////////////////////////////////////////////////////////////////////////////////END COMMAND DETECTOR
	
	//SHIFT ENABLE and LOAD ENABLE LOGIC////////////////////////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge n_rst) begin //assert load enable for a single clock cycle after argument is saved
		if(n_rst == 0) begin
			load_enable_cmd <= 0;
			shift_enable_cmd <= 0;
		end else begin
			if((cmd_Rollover == 1)) begin
				load_enable_cmd <= 0;
				shift_enable_cmd <= 0;
			end else if(save_argument == 1) begin
				load_enable_cmd <= 1;
				shift_enable_cmd <= 1;
			end else begin
				load_enable_cmd <= 0;
				shift_enable_cmd <= shift_enable_cmd;
			end
		end
	end
	///////////////////////////////////////////////////////////////////////////////////////////END SHIFT/LOAD ENABLE LOGIC

	//ARGUMENT DECODER////////////////////////////////////////////////////////////////////
	always_ff @(posedge clk, negedge n_rst) begin 
		if(n_rst == 0) begin
			curr_cmd_argument <= 0;
		end else begin
		if(cmd0 == 1'b1) begin //go idle, send first
			curr_cmd_argument <= 32'd0;
		end else if(read == 1'b1) begin//write block
			if(block_size == 32'd54) begin
				curr_cmd_argument <= 32'd0; //assuming that image begins at address 0 for sake of testing
			end else begin
				curr_cmd_argument <= r_address;
			end
		end else if(write == 1'b1) begin // write block
			curr_cmd_argument <= w_address;
		end else if(cmd2 == 1'b1) begin //setup
			curr_cmd_argument <= 32'd0;
		end else if(cmd3 == 6'd3) begin//go to standby state, last setup cmd
			curr_cmd_argument <= 32'd0;
		end else if(cmd7 == 1'b1) begin//go to transfer state need RCA
			curr_cmd_argument <= {RCA, 16'd0};
		end else if(cmd8 == 1'b1) begin//setup
			curr_cmd_argument <= {20'd0, 4'b0001, 8'b10101010}; //voltage commad
		end else if(acmd41 == 1'b1) begin //setup
			curr_cmd_argument <= 32'd0;
		end else if(change_size == 1'b1) begin //block length
			curr_cmd_argument <= block_size;
		end else begin
			curr_cmd_argument <= 32'd0;
		end
		end
	end
	

	////////////////////////////////////////////////////////////////////////////////////////////////////END ARGUMENT DECODER
	
	assign count_enable_cmd = shift_enable_cmd && (!load_enable_cmd); //enable count when shift enable is asserted and load is deasserted i.e. the flexpts is shifting
	assign cmd_data = {1'b0, 1'b1, curr_cmd_index, curr_cmd_argument};
	assign crc_load_enable = count == 6'd39;

	flex_counter #(6) CMDcounter (.clk(clk), .n_rst(n_rst), .clear(load_enable_cmd), .count_enable(count_enable_cmd), .rollover_val(6'd48), .count_out(count), .rollover_flag(cmd_Rollover));
	flex_pts_sr #(40, 1) CMDShiftOut (.clk(clk), .n_rst(n_rst), .load_enable(load_enable_cmd), .shift_enable(shift_enable_cmd), .parallel_in(cmd_data), .serial_out(next_cmd_bit));
	flex_pts_sr #(8, 1) CRC7ShiftOut (.clk(clk), .n_rst(n_rst), .load_enable(crc_load_enable), .shift_enable(shift_enable_cmd), .parallel_in(crc7_data), .serial_out(crc7_bit));
	
	//CRC7 CALCULATOR//////////////////////////////////////////////////////////////////////////
	CRC7_D1 Crc7CmdCalculator (.new_data(next_cmd_bit), .curr_crc(curr_crc), .new_crc(new_crc));
	assign crc7_data = {new_crc, 1'b1};
	always_ff @(posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			curr_crc <= 0;
		end else begin
			if(load_enable_cmd == 1) begin
				curr_crc <= 0;
			end else begin
				curr_crc <= new_crc;
			end
		end
	end
	//END CRC7 CALCULATOR///////////////////////////////////////////////////////////////////////

	//MULTIPLEXER + REGISTER FOR CRC and CMD_BIT/////
	always_ff @(posedge clk, negedge n_rst) begin
		if(n_rst == 0) begin
			curr_cmd_bit <= 0;
			delayed_Rollover <= 0;
		end else begin
			delayed_Rollover <= cmd_Rollover;
			if(count < 6'd40) begin
				curr_cmd_bit <= next_cmd_bit;
			end else begin
				curr_cmd_bit <= crc7_bit;
			end
		end
	end
	//END MULTIPLEXER//////////////////////////////////////////////////////////////////////////


	//DATA RECEPTION CODE 
	//Receiving Data
	//use read as enable for data reception code and use write as enable for data transmit code
	reg data_read_enable;
	reg [6:0] data_count;
	reg data_complete;
	wire [6:0] data_rollover_val;
	reg [103:0] data0_parallel;
	reg [103:0] data1_parallel;
	reg [103:0] data2_parallel;
	reg [103:0] data3_parallel;
	
	//assign data3 = Data[0]

	assign data_rollover_val = block_size * 2; //shifting half bytes at a time so count to 2 * block_size
	//START BIT DETECTOR START///////////////////////////////////////
	always_ff @(posedge clk, negedge n_rst) begin: start_bit_detector
		if(n_rst == 0) begin
			data_read_enable <= 0;
		end else begin
			if((Data[3] == 0) && (Data[2] == 0) && (Data[1] == 0) && (Data[0] == 0) && read) begin
				data_read_enable <= 1;
			end else if(save_argument == 1) begin
				data_read_enable <= 0;
			end else begin
				data_read_enable <= data_read_enable;
			end
		end
	end
		
	//START BIT DETECTOR FINISH/////////////////////////////////////
	flex_counter #(7) Data_read_counter (.clk(clk), .n_rst(n_rst), .clear(save_argument), .count_enable(data_read_enable), .rollover_val(data_rollover_val), .count_out(data_count), .rollover_flag(data_complete));
	flex_stp_sr #(104, 1) Data0_stp (.clk(clk), .n_rst(n_rst), .shift_enable(data_read_enable), .serial_in(Data[0]), .parallel_out(data0_parallel));
	flex_stp_sr #(104, 1) Data1_stp (.clk(clk), .n_rst(n_rst), .shift_enable(data_read_enable), .serial_in(Data[1]), .parallel_out(data1_parallel));
	flex_stp_sr #(104, 1) Data2_stp (.clk(clk), .n_rst(n_rst), .shift_enable(data_read_enable), .serial_in(Data[2]), .parallel_out(data2_parallel));
	flex_stp_sr #(104, 1) Data3_stp (.clk(clk), .n_rst(n_rst), .shift_enable(data_read_enable), .serial_in(Data[3]), .parallel_out(data3_parallel));
endmodule


	
