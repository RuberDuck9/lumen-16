module risc-v (

	input clk,
	input reset,
	
	input memory_read_busy,
	input memory_write_busy,
	input [31:0] memory_read_data,

	output load,
	output store,
	output [31:0] memory_access_address,
	output [31:0] memory_write_data,
	output [3:0] memory_write_mask,

	);

	// ********************************************
	// Instruction Decoder
	// ********************************************

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
	wire [4:0] rd_address                 = instruction_register[11:7];  // destination register
	wire [4:0] rs1_address                = instruction_register[19:15]; // operand register 1
	wire [4:0] rs2_address                = instruction_register[24:20]; // operand register 2

	// Function
	wire [2:0] funct3                     = instruction_register[14:12];
	wire [6:0] funct7                     = instruction_register[31:25];

	// Immediate Value
	wire [31:0] Uimm                      = {    instruction_register[31],  instruction_register[30:12], {12{1'b0}}};                                                  // zero extend bits 11-0
	wire [31:0] Iimm                      = {{21{instruction_register[31]}, instruction_register[30:20]};                                                              // sign extend bits 32-11
	wire [31:0] Simm                      = {{21{instruction_register[31]}, instruction_register[30:25], instruction_register[11:7]};                                  // sign extend bits 31-11 
	wire [31:0] Bimm                      = {{20{instruction_register[31]}, instruction_register[7], instruction_register[30:25], instruction_register[11:8], 1'b0};   // sign extend bits 31-12, bit 0 = 0 
	wire [31:0] Jimm                      = {{12{instruction_reigster[31]}, instruction_register[19:12], instruction_register[20], instruction_register[30:21], 1'b0}; // sign extend bits 31-20, bit 0 = 0

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

	assign memory_access_address = state[wait_instruction_bit] | state[fetch_instruction_bit] ? program_counter : load_store_address; 

	// ********************************************
	// Register File
	// ********************************************

	reg [31:0] register_file [0:31];

	// ********************************************
	// Control Logic
	// ********************************************
	
	reg [1:0] state = 2'b00;
	// 00 - Fetch
	// 01 - Execute
	// 10 & 11 - Reserved

	always @(posedge clk) begin
		case(state)
			2'b00: begin
				instruction_register <= memory_read_address;
				state <= 2'b01;
			end
			2'b01: begin
				program_counter = program_counter + 4;
				2'b00;
			end
		endcase
	end
	
	wire [31:0] reg_write_data = ... ;
	wire reg_write_enable = ... ;
	always @(posedge clk) begin
		if(reg_write_enable && (rd_address != 0)) begin
			register_file[rd_address] <= reg_write_data;
		end
	end

endmodule
