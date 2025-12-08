// **************************************************
// Memory
// **************************************************

module instructio_memory (
	input clk,
	input [31:0] program_counter,
	output reg [31:0] instruction_memory_read_data
);

reg [31:0] memory_block [0:255];

always @(posedge clk) begin
	instruction_memory_read_data <= memory_block[program_counter];
end

endmodule

module data_memory (
	input clk,
	input store,
	input [31:0] data_memory_access_address,
	input [31:0] data_memory_write_data,
	output reg [31:0] data_memory_read_data
);

reg [31:0] memory_block [0:255];

always @(posedge clk) begin
	if (store) begin
		memory_block[data_memory_access_address] <= data_memory_write_data;
	end
	data_memory_read_data <= memory_block[data_memory_access_address];
end

endmodule

// **************************************************
// WaveRV Core
// **************************************************

module program_counter(
	input clk,
	input next_pc,
	input wire execute,
	output reg [31:0] program_counter
);

always @(posedge clk) begin
	if (execute) begin
		program_counter <= program_counter + next_pc;
	end
end

endmodule

module instruction_register(
	input wire clk,
	input wire fetch,
	input wire [31:0] instruction_memory_read_data,
	output reg [31:0] instruction_register
);

always @(posedge clk) begin
	if (fetch) begin
		instruction_register <= instruction_memory_read_data;
	end
end

endmodule

module instruction_decoder(
	input wire [31:0] instruction_register,
	output wire alu_register_operation,
	output wire alu_immediate_operation,
	output wire branch_operation,
	output wire jump_and_link_pc_operation,
	output wire jump_and_link_register_operation,
	output wire add_upper_immediate_pc_operation,
	output wire load_upper_immediate_operation,
	output wire load_operation,
	output wire store_operation,
	output wire system_operation,
	output wire [4:0] rd_address,
	output wire [4:0] rs1_address,
	output wire [4:0] rs2_address,
	output wire [2:0] funct3,
	output wire [6:0] funct7,
	output wire [31:0] Uimm,
	output wire [31:0] Iimm,
	output wire [31:0] Simm,
	output wire [31:0] Bimm,
	output wire [31:0] Jimm
);

// Instruction
assign alu_register_operation           = (instruction_register[6:2] == 5'b01100); // rd <- rs1 OP rs2
assign alu_immediate_operation          = (instruction_register[6:2] == 5'b00100); // rd <- rs1 OP Iimm
assign branch_operation                 = (instruction_register[6:2] == 5'b11000); // (rs1 OP rs2) ? PC <- PC + Bimm : nothing
assign jump_and_link_pc_operation       = (instruction_register[6:2] == 5'b01111); // rd <- PC + 4; PC <- PC + Jimm
assign jump_and_link_register_operation = (instruction_register[6:2] == 5'b11001); // rd <- PC + 4; PC <- rs1 + Iimm
assign add_upper_immediate_pc_operation = (instruction_register[6:2] == 5'b00101); // rd <- PC + Uimm 
assign load_upper_immediate_operation   = (instruction_register[6:2] == 5'b01101); // rd <- Uimm
assign load_operation                   = (instruction_register[6:2] == 5'b00000); // rd <- memory[rs1 + Iimm]
assign store_operation                  = (instruction_register[6:2] == 5'b01000); // memory[rs1 + Simm] <- rs2
assign system_operation                 = (instruction_register[6:2] == 5'b11100); // witchcraft

// Register
assign rd_address                 = instruction_register[11:7];  // destination register
assign rs1_address                = instruction_register[19:15]; // operand register 1
assign rs2_address                = instruction_register[24:20]; // operand register 2

// Function
assign funct3                     = instruction_register[14:12];
assign funct7                     = instruction_register[31:25];

// Immediate Value
assign Uimm                      = {    instruction_register[31],  instruction_register[30:12], {12{1'b0}}};                                                   // zero extend bits 11-0
assign Iimm                      = {{21{instruction_register[31]}}, instruction_register[30:20]};                                                              // sign extend bits 32-11
assign Simm                      = {{21{instruction_register[31]}}, instruction_register[30:25], instruction_register[11:7]};                                  // sign extend bits 31-11 
assign Bimm                      = {{20{instruction_register[31]}}, instruction_register[7], instruction_register[30:25], instruction_register[11:8], 1'b0};   // sign extend bits 31-12, bit 0 = 0 
assign Jimm                      = {{12{instruction_register[31]}}, instruction_register[19:12], instruction_register[20], instruction_register[30:21], 1'b0}; // sign extend bits 31-20, bit 0 = 0

endmodule

module control_logic(
	input clk,
	input wire [31:0] instruction_register,
	input wire alu_register_operation,
	input wire alu_immediate_operation,
	input wire branch_operation,
	input wire jump_and_link_pc_operation,
	input wire jump_and_link_register_operation,
	input wire add_upper_immediate_pc_operation,
	input wire load_upper_immediate_operation,
	input wire load_operation,
	input wire store_operation,
	input wire system_operation,
	output wire write_back_enable,
	output reg [31:0] write_back_data,
	output reg [31:0] next_pc,
	output wire fetch,
	output wire execute
);

reg [1:0] state = 2'b00;
// 00 - Fetch
// 01 - Execute
// 10 & 11 - Reserved

always @(posedge clk) begin
	case(state)
		2'b00: begin // fetch
			assign fetch = 1;
		end
		2'b01: begin // execute
			program_counter = next_pc;
			state <= 2'b00;
		end
	endcase
end

always @(posedge clk) begin
	if(reg_write_enable && (rd_address != 0)) begin
		register_file[rd_address] <= reg_write_data;
	end
end

always @(posedge clk) begin
	write_back_data = (jump_and_link_pc_operation || jump_and_link_register_operation) ? (PC + 4) : 
		(load_upper_immediate_operation) ? Uimm :
		(add_upper_immediate_pc_operation) ? (program_counter + Uimm) : 
		alu_out;
end

assign write_back_enable = ((state == 2'b01) && 
	(alu_register_operation           || 
		alu_immediate_operation          || 
		jump_and_link_pc_operation       || 
		jump_and_link_register_operation || 
		load_upper_immediate_operation   ||
		add_upper_immediate_pc_operation
	));

always @(posedge clk) begin
	next_pc = (branch_operation && take_branch) ? program_counter + Bimm:
		jump_and_link_register_operation                ? program_counter + Jimm :
		jump_and_link_immediate_operation               ? rs1 + Iimm :
		program_counter + 4;
end

endmodule

module alu(
	input wire [31:0] alu_in_1,
	input wire [31:0] alu_in_2,
	input wire [31:0] rs1,
	input wire [31:0] rs2,
	input wire [4:0] shamt,
	input wire [31:0] instruction_register,
	input wire [2:0] funct3,
	input wire [6:0] funct7,
	output reg take_branch,
	output reg [31:0] alu_out
);

always @(*) begin
	case(funct3)
		3'b000: alu_out = (funct7[5] & instruction_register[5]) ? (alu_in_1 - alu_in_2) : (alu_in_1 + alu_in_2); // if bit 5 of funct7 and the instruction register are high it must be a reg-reg operation, otherwise it must be a reg-imm operation (and also and add)
		3'b001: alu_out = alu_in_1 << shamt; // register-shift left
		3'b010: alu_out = ($signed(alu_in_1) < $signed(alu_in_2)); // set less than
		3'b011: alu_out = (alu_in_1 < alu_in_2); // set less than unsigned
		3'b100: alu_out = (alu_in_1 ^ alu_in_2); // xor
		3'b101: alu_out = funct[7] ? ($signed(alu_in_1) >>> shamt) : (alu_in_1 >> shamt); // register-shift right logical or arthimetic depdning on funct7 bit 5
		3'b110: alu_out = (alu_in_1 | alu_in_2); // or
		3'b111: alu_out = (alu_in_1 & alu_in_2); // and
	endcase
end

always @(*) begin
	case(funct3)
		3'b000: take_branch = (rs1 == rs2);
		3'b001: take_branch = (rs1 != rs2);
		3'b100: take_branch = ($signed(rs1) < $signed(rs2));
		3'b101: take_branch = ($signed(rs1) >= $signed(rs2));
		3'b110: take_branch = (rs1 < rs2);
		3'b111: take_branch = (rs1 >= rs2);
		default: take_branch = 1'b0;
	endcase
end

endmodule

module register_file(
	input wire clk,
	input wire register_store,
	input wire [4:0] read_register_1,
	input wire [4:0] read_register_2,
	input wire [4:0] write_register,
	input wire [31:0] register_write_data,
	output wire [31:0] read_data_1,
	output wire [31:0] read_data_2
);

reg [31:0] register_file [0:31];

always @(posedge clk) begin
	if (register_store) begin
		register_file[write_register] <= register_write_data;
	end 
end

assign read_data_1 = register_file[read_register_1]; 
assign read_data_2 = register_file[read_register_2]; 

endmodule

module waverv_core (
	input clk,
	input reset,
	input [31:0] memory_read_data,
	output store,
	output [31:0] memory_access_address,
	output [31:0] memory_write_data,
	output [3:0] memory_write_mask

	);

	// ********************************************
	// Program Counter
	// ********************************************

	reg [31:0] program_counter;
	reg [31:0] instruction_register;

	wire [31:0] pc_plus_4 = program_counter + 4;
	wire [31:0] pc_plus_immediate = program_counter + ( 
	jump_and_link_pc_operation ? Jimm :
	add_upper_immediate_pc_operation ? Uimm : 
	Bimm );

	wire [31:0] load_store_address = rs1 + (
	store_operation ? Simm :
	Iimm );

	wire [15:0] load_halfword = load_store_address[1] ? memory_read_data[31:16] : memory_read_data[15:0];

	wire [7:0] load_byte = load_store_address[0] ? load_halfword[15:8] : load_halfword[7:0];

	wire memory_byte_access = funct3[1:0] == 2'b00;
	wire memory_halfword_access = funct3[1:0] == 2'b01;

	wire load_sign = !funct3[2] & (memory_byte_access ? load_byte[7] : load_halfword[15]);

	wire [31:0] load_data = 
		memory_byte_access ? {{24{load_sign}}, load_byte} :
		memory_halfword_access ? {{16{load_sign}}, load_halfword} :
		memory_read_data;
 
	assign memory_access_address = (state[wait_instruction_bit] | state[fetch_instruction_bit]) ? program_counter : load_store_address; 

	assign memory_write_data[ 7: 0] = rs2[7:0];
	assign memory_write_data[15: 8] = load_store_address[0] ? rs2[7:0] : rs2[15:8];
	assign memory_write_data[23:16] = load_store_address[1] ? rs2[7:0] : rs2[23:16];
	assign memory_write_data[31:24] = load_store_address[0] ? rs2[7:0] : load_store_address[1] ? rs2[15:8] : rs2[31:24];

	wire [3:0] write_mask = 
		memory_byte_access ? 
			(load_store_address[1] ? (load_store_address[0] ? 4'b1000 : 4'b0100) :
				(load_store_address[0] ? 4'b0010 : 4'b0001)
			) :
		memory_byte_access ?
			(load_store_address[1] ? 4'b1100 : 4'b0011) :
			4'b1111;

endmodule
