// **************************************************
// Memory (24 bit block)
// **************************************************

module instruction_memory (
	input clk,
	input [31:0] program_counter,
	output reg [31:0] instruction_memory_read_data
);

reg [31:0] memory_block [0:16777215];

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

reg [31:0] memory_block [0:16777215];

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
	input wire clk,
	input wire execute,
	input wire[31:0] next_pc,
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

module control_unit(
	input clk,
	input wire [31:0] program_counter,
	input wire [31:0] instruction_register,
	input wire [31:0] rs1,
	input wire [31:0] rs2,
	output wire [4:0] rd_address,
	output wire [4:0] rs1_address,
	output wire [4:0] rs2_address,
	output wire [2:0] funct3,
	output wire [6:0] funct7,
	output wire write_back_enable,
	output wire register_write,
	output reg fetch,
	output reg execute,
	output reg take_branch,
	output reg [31:0] write_back_data,
	output reg [31:0] next_pc
);

// Instruction
wire alu_register_operation           = (instruction_register[6:2] == 5'b01100); // rd <- rs1 OP rs2
wire alu_immediate_operation          = (instruction_register[6:2] == 5'b00100); // rd <- rs1 OP Iimm
wire branch_operation                 = (instruction_register[6:2] == 5'b11000); // (rs1 OP rs2) ? PC <- PC + Bimm : nothing
wire jump_and_link_pc_operation       = (instruction_register[6:2] == 5'b01111); // rd <- PC + 4; PC <- PC + Jimm
wire jump_and_link_register_operation = (instruction_register[6:2] == 5'b11001); // rd <- PC + 4; PC <- rs1 + Iimm
wire add_upper_immediate_pc_operation = (instruction_register[6:2] == 5'b00101); // rd <- PC + Uimm 
wire load_upper_immediate_operation   = (instruction_register[6:2] == 5'b01101); // rd <- Uimm
wire load_operation                   = (instruction_register[6:2] == 5'b00000); // rd <- memory[rs1 + Iimm]
wire store_operation                  = (instruction_register[6:2] == 5'b01000); // memory[rs1 + Simm] <- rs2
wire system_operation                 = (instruction_register[6:2] == 5'b11100); // witchcraft

// Register
assign rd_address                 = instruction_register[11:7];  // destination register
assign rs1_address                = instruction_register[19:15]; // operand register 1
assign rs2_address                = instruction_register[24:20]; // operand register 2

// Function
assign funct3                     = instruction_register[14:12];
assign funct7                     = instruction_register[31:25];

reg [2:0] state = 3'b000;
// 000 - Fetch
// 001 - Execute
// 010, 011, 100, 101, 110, 111 - Reserved

always @(posedge clk) begin
	case(state)
		3'b000: begin // fetch
			fetch <= 1;
			execute <= 0;
			state <= 3'b001;
		end
		3'b001: begin // execute
		fetch <= 1;
			execute = 1;
			state <= 3'b000;
		end
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

assign write_back_enable = ((state == 2'b01) && 
	(alu_register_operation              || 
		alu_immediate_operation          || 
		jump_and_link_pc_operation       || 
		jump_and_link_register_operation || 
		load_upper_immediate_operation   ||
		add_upper_immediate_pc_operation
	));

endmodule

module next_pc(
	input wire [31:0] program_counter
);

always @(posedge clk) begin
	write_back_data = (jump_and_link_pc_operation || jump_and_link_register_operation) ? (program_counter + 4) : 
		(load_upper_immediate_operation) ? Uimm :
		(add_upper_immediate_pc_operation) ? (program_counter + Uimm) : 
		alu_out;
end

endmodule

module immediate_generator(
	input wire [31:0] instruction_register,
	input wire [31:0] 
	output wire [31:0] imm_out
);

assign Uimm = {    instruction_register[31],   instruction_register[30:12], {12{1'b0}}};                                                   // zero extend bits 11-0
assign Iimm = {{21{instruction_register[31]}}, instruction_register[30:20]};                                                              // sign extend bits 32-11
assign Simm = {{21{instruction_register[31]}}, instruction_register[30:25], instruction_register[11:7]};                                  // sign extend bits 31-11 
assign Bimm = {{20{instruction_register[31]}}, instruction_register[7], instruction_register[30:25], instruction_register[11:8], 1'b0};   // sign extend bits 31-12, bit 0 = 0 
assign Jimm = {{12{instruction_register[31]}}, instruction_register[19:12], instruction_register[20], instruction_register[30:21], 1'b0}; // sign extend bits 31-20, bit 0 = 0

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
	output reg [31:0] alu_out
);

always @(*) begin
	case(funct3)
		3'b000: alu_out = (funct7[5] & instruction_register[5]) ? (alu_in_1 - alu_in_2) : (alu_in_1 + alu_in_2); // if bit 5 of funct7 and the instruction register are high it must be a reg-reg operation, otherwise it must be a reg-imm operation (and also and add)
		3'b001: alu_out = alu_in_1 << shamt; // register-shift left
		3'b010: alu_out = ($signed(alu_in_1) < $signed(alu_in_2)); // set less than
		3'b011: alu_out = (alu_in_1 < alu_in_2); // set less than unsigned
		3'b100: alu_out = (alu_in_1 ^ alu_in_2); // xor
		3'b101: alu_out = funct7[5] ? ($signed(alu_in_1) >>> shamt) : (alu_in_1 >> shamt); // register-shift right logical or arthimetic depdning on funct7 bit 5
		3'b110: alu_out = (alu_in_1 | alu_in_2); // or
		3'b111: alu_out = (alu_in_1 & alu_in_2); // and
	endcase
end

endmodule

module register_file(
	input wire clk,
	input wire register_write,
	input wire [4:0] read_register_1,
	input wire [4:0] read_register_2,
	input wire [4:0] write_register,
	input wire [31:0] register_write_data,
	output wire [31:0] read_data_1,
	output wire [31:0] read_data_2
);

reg [31:0] register_file [0:31];

always @(posedge clk) begin
	if (register_write) begin
		register_file[write_register] <= register_write_data;
	end 
end

assign read_data_1 = register_file[read_register_1]; 
assign read_data_2 = register_file[read_register_2]; 

endmodule
