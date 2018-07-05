// $Id: $
// File name:   tb_sd_edge_detection.sv
// Created:     4/23/2018
// Author:      Daniel Gilmore
// Lab Section: 337-02
// Version:     1.0  Initial Design Entry
// Description: Test bench for full module sd_edge_detection

`timescale 1ns / 10ps

module tb_sd_edge_detection();

	//Define local constants
	localparam CLK_PERIOD		= 2.5;

	reg tb_test_case_num;

	//Test bench DUT port signals
	reg tb_clk;
	reg tb_n_rst;
	wire [3:0] tb_DAT;
	wire tb_CMD;
	wire input_CMD;
	wire [3:0]input_DAT;
	reg [3:0] output_DAT;
	reg output_CMD;
	reg prev_CMD;
	wire tb_done;
	wire tb_error;
	
	//SRAM port signals
	wire tb_sram_read;
	wire tb_sram_write;
	wire [15:0] tb_sram_address;
	wire [7:0] tb_output_data;
	wire [7:0] tb_new_pixel;

	//Simulated file data
	reg [431:0] tb_header_data; //Fill with data from xxd test_image.bmp | vim -
	reg [71:0] tb_three_pixels; //Value determined by address received from SD_Card_Interface's READ CMD

	//Test bench variables
	reg [6:0] sd_cmd_count;
	reg [45:0] sd_cmd;
	reg [431:0] saved_header;
	wire cmd_detect;
	reg [5:0] sd_cmd_index;
	reg [32:0] sd_cmd_argument;
	reg [6:0] crc;
	reg busy;
	reg output_valid;
	reg [31:0] i;
	reg block_size;
	//reg [18431:0] pixels;

	
		
	//positive edge detector for CMD
	always_ff @(posedge tb_clk, negedge tb_n_rst) begin
		if(tb_n_rst == 0) begin
			prev_CMD <= 0;
		end else begin
			prev_CMD <= tb_CMD;
		end
	end
	assign cmd_detect = !prev_CMD && tb_CMD;
	//Generate DUT
	sd_edge_detection DUT(
				.clk(tb_clk),
				.n_rst(tb_n_rst),
				.DAT(tb_DAT),
				.CMD(tb_CMD),
				.done(tb_done),
				.error(tb_error),
				.sram_read(tb_sram_read),
				.sram_write(tb_sram_write),
				.sram_address(tb_sram_address),
				.new_pixel(tb_new_pixel),
				.output_data(tb_output_data)
	);
	
	assign input_DAT = tb_DAT;
	assign tb_DAT = (output_valid==1'b1)? output_DAT : 4'hZ;
	assign input_CMD = tb_CMD;
	assign tb_CMD = (output_valid==1'b1)? output_CMD : 1'bz;

	on_chip_sram_wrapper SRAM
	(
		// Test bench control signals
		.mem_clr(!tb_n_rst),
		.mem_init(1'b0),
		.mem_dump(1'b0),
		.verbose(1'b1),
		.init_file_number(32'h00000000),
		.dump_file_number(32'h00000000),
		.start_address(16'h0000),
		.last_address(16'hFFFF),
		// Memory interface signals
		.read_enable(tb_sram_read),
		.write_enable(tb_sram_write),
		.address(tb_sram_address),
		.read_data(tb_output_data),
		.write_data(tb_new_pixel)
	);
	

// Clock gen block
	always
	begin : CLK_GEN
		tb_clk = 1'b0;
		#(CLK_PERIOD / 2.0);
		tb_clk = 1'b1;
		#(CLK_PERIOD / 2.0);
	end

//Command detect block
	always_comb
	begin
		if (cmd_detect == 1 & !busy)
			read_command(sd_cmd_count);
	end
		

//Reset task
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

	//Task to read command
	task read_command;
		input [6:0] cmd_count;
	begin
		busy = 1'b1;
		if (cmd_count < 6'd46)
		begin
			#(CLK_PERIOD);
			sd_cmd[cmd_count] = tb_CMD;
			sd_cmd_count = sd_cmd_count+1;
			read_command(sd_cmd_count);
		end
		else
		begin
			sd_cmd_count = 0;
			sd_cmd_index = sd_cmd[45:40];
			sd_cmd_argument = sd_cmd[39:8];
			crc = sd_cmd[7:1];
			run_command(sd_cmd_index, sd_cmd_argument);
			busy = 1'b0;
		end
	end
	endtask

	//Task to run received command
	task run_command;
		input [5:0] index;
		input [31:0] argument;
	begin
		if (index == 5'd17)
		begin
			send_bytes[argument];
		end
		else
			busy = 1'b0;
	end
	endtask

	task send_bytes;
		input [31:0] address;
	begin
		output_valid = 1'b1;
		for (i = 0; i < block_size; i = i + 1)
		begin
			output_DAT[3] = header_data[i*8 + 7];
			output_DAT[2] = header_data[i*8 + 6];
			output_DAT[1] = header_data[i*8 + 5];
			output_DAT[0] = header_data[i*8 + 4];
			#(CLK_PERIOD);
			output_DAT[3] = header_data[i*8 + 3];
			output_DAT[2] = header_data[i*8 + 2];
			output_DAT[1] = header_data[i*8 + 1];
			output_DAT[0] = header_data[i*8 + 0];
			#(CLK_PERIOD);
		end
		output_valid = 1'b0;
	end
	endtask	
			

	initial
	begin
		// Initial values
		tb_test_case_num = 0;
		tb_n_rst = 1'b1;
		output_DAT= '0;
		output_CMD = 0;
		tb_header_data = 432'h424d360d00000000000036040000280000003000000030000000010008000000000000090000130b0000130b00000000000000000000;
		tb_three_pixels = 23'h000000;
		//pixels[18431:10928] = 15700'h00000000000080000080000000808000800000008000800080800000c0c0c000c0dcc000f0caa6000020400000206000002080000020a0000020c0000020e00000400000004020000040400000406000004080000040a0000040c0000040e00000600000006020000060400000606000006080000060a0000060c0000060e00000800000008020000080400000806000008080000080a0000080c0000080e00000a0000000a0200000a0400000a0600000a0800000a0a00000a0c00000a0e00000c0000000c0200000c0400000c0600000c0800000c0a00000c0c00000c0e00000e0000000e0200000e0400000e0600000e0800000e0a00000e0c00000e0e00040000000400020004000400040006000400080004000a0004000c0004000e00040200000402020004020400040206000402080004020a0004020c0004020e00040400000404020004040400040406000404080004040a0004040c0004040e00040600000406020004060400040606000406080004060a0004060c0004060e00040800000408020004080400040806000408080004080a0004080c0004080e00040a0000040a0200040a0400040a0600040a0800040a0a00040a0c00040a0e00040c0000040c0200040c0400040c0600040c0800040c0a00040c0c00040c0e00040e0000040e0200040e0400040e0600040e0800040e0a00040e0c00040e0e00080000000800020008000400080006000800080008000a0008000c0008000e00080200000802020008020400080206000802080008020a0008020c0008020e00080400000804020008040400080406000804080008040a0008040c0008040e00080600000806020008060400080606000806080008060a0008060c0008060e00080800000808020008080400080806000808080008080a0008080c0008080e00080a0000080a0200080a0400080a0600080a0800080a0a00080a0c00080a0e00080c0000080c0200080c0400080c0600080c0800080c0a00080c0c00080c0e00080e0000080e0200080e0400080e0600080e0800080e0a00080e0c00080e0e000c0000000c0002000c0004000c0006000c0008000c000a000c000c000c000e000c0200000c0202000c0204000c0206000c0208000c020a000c020c000c020e000c0400000c0402000c0404000c0406000c0408000c040a000c040c000c040e000c0600000c0602000c0604000c0606000c0608000c060a000c060c000c060e000c0800000c0802000c0804000c0806000c0808000c080a000c080c000c080e000c0a00000c0a02000c0a04000c0a06000c0a08000c0a0a000c0a0c000c0a0e000c0c00000c0c02000c0c04000c0c06000c0c08000c0c0a000f0fbff00a4a0a000808080000000ff0000ff000000ffff00ff000000ff00ff00ffff0000ffffff00f7a4525b9ba4f75200009ba452009ba49ba4a4a45b004949000000005252000000529b005ba4a45b49a49b0052529b0007f79b9b5ba45bf7490052a45b005bf7a4a4a4a45200000000000049000000490000a44900a45b9b529ba4525b495b52f6a45b9b52a452f79b0000a49b0052a4a452a4520000000000000000000000000000000049a4529b52a4a45b525252a4ff079ba45ba449a4f752009b9b0000a45252520000000000490000000000000000000000005b499b5ba4529b525b525bfffff7a4a4a452a4f7a40049a4000052520000000049a4f707a40000000000000000000000520052a49b52a4525b5b00ffffff07a4a45ba4f7f7520052a400524900000049a4070707f79b00000000000000000000000049a45b52a4a45b5b52fffffff607a49b5ba4a4a45b49f7a4490000004952a407070707f79b0000000000000000000000005b5b52a49ba45b52ffffffffffff07f7a45ba4a4529bf7f79b52005249f7070707f7f7f79b0000000000000000000049525252525ba49b52ffffffffffffffff0807a49b9bf7a4f707f7a4009b0708f60707f7f7f79b004949000000004900495252529ba49b9ba4ffffffffffffffffffff0807a49bf7a407f79b00f708f6f6f607f7f7a4f75b000000000000000000529b9ba4070707f6fffffffffffffffff6fffffff6f7f7a4a4075b4907f6f6f608f7f7a4a4a4a40000000000000000499b07f6f6ffffffffffffffffffffffffffffffffffffff0807f7a45208f6f6f608f7a4a45ba4a45200000000490000a408fffffffffffffffffffffffffffffffffffffffff6ffffffffa4a4ff08f607f7a4a4524952a45200000052a408f6fffffffffffff6fffffffffffffffffffffff6ffffffffffffffff07a4fff608f79b520000000052a40000f7fff6fffff6fff6fffffffffffffffffffffffffffffffff6fffff6fffff6fff607f607a4f7f7a4a4490000005b4952fffffffff6fffffffff6ffffffffffffffffffffffffffffffffffffffffffffffff080707070707f7f75b49000052f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0707f6f60807f7f7f75b00005bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff60708f6f6f6f60807a49b524952fffffffff6fffffffffffffffffffffffffffffffffffffffffffffffffffff6fff6f6f6f6f6f6f60707f7a4a4a45249f6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff60807f6f608f7;
		//pixels[10927:0] = 2732'ha4a4a4f7a45200f7fffffffff6fffffffffffffffffffffffffffffffffffffffffffffffffffffff6f6080708f6080707a452a4a45b529bfff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6f607a4a4a4f7a49b525bf79b525bf6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6f6f6f6080708080707f7f7f7f79b495207fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff608f60808f6f6f79b009b07f7a45252a407fffffff6fffffffffffffffffffffffffffffffffffffffffffffffffff6f6f6f6080708f7f79b005b07f7f75b005b9b08fffffffffffffffffffffffffffffffffffffffffffffffffffffffff6f6f6f6f60707f6ff07a4a4f707f7f752529ba4fffffffffffffffffffffffffffffffffffffffffffffffffffffff608f6f6f6f60808f6ff08f7a4070707f7a45b9ba4f6fffffffffffffffffffffffffffffffffffffffffffffffffffff60808f608f6f6f6f6ff07a4a407070707f7a400a407ffffffffffffffffffffffffffffffffffffffffffffffffffff0807f6f6f6f6f6f6f6fff6f7a4f7a4a4a4f7a4529b08fffffffffffffffffffffffffffffffffffffffffffffffffffff608f6f60807f7f7f707ffa452a45b49009ba40052f6f6fffffffffffffffffffffffffffffffffffffffffffffffffff60708f6f7f752525b07f6a4004952520052a40007ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0708f607f7a45b9bf7f7f79b00495b9b9ba449f6ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0807f6f60807070707070707f7f7f7f7a45b00f6ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0807f6f6f6f6f6f608f6f608070707f7f75200f6fffffffffffffffffffffffffffffffffffffffffffffffffffffffff60708f6f6f6f6f6f6f6f6f6f607f7f7a44900ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0707f6f6f608f608f6f6f6f60707f7f70000f6fff6ffffffffffffffffffffffffffffffffffffffffffffffffffffff0707f6f6f6f6f6f6f6f608070707f7a40000fff6ffffffffffffffffffffffffffffffffffffffffffffffffffffffff0707f6f608f6f6f608f6f607070707f7005bfffffff6fffffffffffffffffffffffffffffffffffffffffffffffff6ff08f708fff6f6f6f6f6f6f6070707f7a400f7fff6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07f708fff608f6f607f7f7f75b5b0049f6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff08a4f707f7f7f7a4a45b4952000000f7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff07f7f7f7a45b5b5b5252495b00f7f6fff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffff6ffffff07f7a4f79b9bf7529b5ba4f7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6070707f79ba4a45bf707f6fff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6fffffff60807f7a4f707ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
		sd_cmd_count = '0;
		sd_cmd_index = '0;
		sd_cmd_argument = '0;
		crc = '0;
		block_size = 3;
		sd_data[431:0] = tb_header_data;
		
	end
endmodule