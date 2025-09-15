16 Bit ISA 

## Instructions 

### Format

Format 1: Literal   
| 00 | 00000000000000 |
       
Format 2: Register    
| 01 | 0000000 | XXX | Z | YYY |

Bit Z is a specifier for whether to use a register's value, or its corresponding memory address      
Z = 0: register value         
Z = 1: memory address         

Format 3: Immediate    
| 10 | 00 | 000000000000 |        

### Opcodes

| Instruction | Format Type | Bit format | Description |
| ----------- | ----------- | ---------- | ----------- | 
| NOP | Literal | 00 - 00000000000000 | Do nothing |
| INC, AX | Literal | 00 - 00000000000001 | Perform AX + 1 | 
| INC, BX | Literal | 00 - 00000000000010 | Perform BX + 1 |
| INC, CX | Literal | 00 - 00000000000011 | Perform CX + 1 |
| INC, DX | Literal | 00 - 00000000000100 | Perform DX + 1 |
| INC, EX | Literal | 00 - 00000000000101 | Perform EX + 1 |
| INC, FX | Literal | 00 - 00000000000110 | Perform FX + 1 |
| INC, GX | Literal | 00 - 00000000000111 | Perform GX + 1 |
| INC, HX | Literal | 00 - 00000000001000 | Perform HX + 1 |
| MOV | Register | 01 - 0000000 - XXX - Z - YYY | perform Y = X |
| ADD | Register | 01 - 0000001 - XXX - Z - YYY | perform X + Y | 
| ADC | Register | 01 - 0000010 - XXX - Z - YYY | perform with carry X + Y | 
| SUB | Register | 01 - 0000011 - XXX - Z - YYY | perform X - Y |
| SBB | Register | 01 - 0000100 - XXX - Z - YYY | perform with borrow X - Y | 
| ORR | Register | 01 - 0000101 - XXX - Z - YYY | perform X ∨ Y |
| AND | Register | 01 - 0000110 - XXX - Z - YYY | perform X ∧ Y | 
| XOR | Register | 01 - 0000111 - XXX - Z - YYY | perform X ⊕ Y |
| CMP | Register | 01 - 0001000 - XXX - Z - YYY | compare X to Y, set flags |


## Registers:

### General Purpose (16):

- AX - 000 - alu accumulator
- BX - 001 - immediate
- CX - 010 
- DX - 011 
- EX - 100
- FX - 101
- GX - 110 
- HX - 111

### Special:

- Instruction Register - holds the instruction which is currently being executed
- Program Counter - address of next instruction to be fetched
- Memory Address Register - holds the address of the memory location being accessed
- Memory Data Register - holds the data about to be written to memory
- Stack Pointer
- Stack Base
- Memory Base Register - the first memory address the running process is allowed to access
- Memory Limit Register - how many memory address the process is allocated
- Mode (1)
- Flags
    - 000 - Sign Flag
    - 001 - Zero Flag
    - 010 - Auxiliary Carry Flag
    - 011 - Parity Flag
    - 100 - Carry Flag
    - 101 - Overflow Flag
    - 110 - Interrupt Flag
    - 111 - Trap Flag


