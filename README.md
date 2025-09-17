The goal of this isa is to be simple, but also powerful. Beyond simply being turing complete it also seeks to support: 
- Pre-emptive scheduling
- Hardware level memory protection
- Multiple operation modes (Ring 0, Ring 3)
- Hardware and software level interrupts
- Persistant bios

## Instructions 

### Format
 
Format 1: Literal      
| 00 - 00000000000000 |   

Format 2: Single Register    
| 01 - 00000000000 - XXX |   
       
Format 3: Double Register      
| 10 - 0000000 - XXX - Z - YYY |   

Bit Z is a specifier for whether to use a register's value, or its corresponding memory address      
Z = 0: register value         
Z = 1: memory address         

Format 4: Immediate    
| 11 - 00 - IIIIIIIIIIIIII |      
I = immediate value

### Opcodes


"*" = Privledged Instruction

| Instruction | Format Type | Bit format | Description |
| ----------- | ----------- | ---------- | ----------- | 
| NOP | Literal | 00 - 00000000000000 | Do nothing |
| INC, AX | Literal | 00 - 00000000000001 | AX + 1 | 
| INC, BX | Literal | 00 - 00000000000010 | BX + 1 |
| INC, CX | Literal | 00 - 00000000000011 | CX + 1 |
| INC, DX | Literal | 00 - 00000000000100 | DX + 1 |
| INC, EX | Literal | 00 - 00000000000101 | EX + 1 |
| INC, FX | Literal | 00 - 00000000000110 | FX + 1 |
| INC, GX | Literal | 00 - 00000000000111 | GX + 1 |
| INC, HX | Literal | 00 - 00000000001000 | HX + 1 |
| DEC, AX | Literal | 00 - 00000000001001 | AX - 1 | 
| DEC, BX | Literal | 00 - 00000000001010 | BX - 1 |
| DEC, CX | Literal | 00 - 00000000001011 | CX - 1 |
| DEC, DX | Literal | 00 - 00000000001100 | DX - 1 |
| DEC, EX | Literal | 00 - 00000000001101 | EX - 1 |
| DEC, FX | Literal | 00 - 00000000001110 | FX - 1 |
| DEC, GX | Literal | 00 - 00000000001111 | GX - 1 |
| DEC, HX | Literal | 00 - 00000000010000 | HX - 1 |
| SSF | Literal | 00 - 00000000010001 | SF = 1 |
| SZF | Literal | 00 - 00000000010010 | ZF = 1 |
| SCF | Literal | 00 - 00000000010011 | CF = 1 |
| *SIF | Literal | 00 - 00000000010100 | IF = 1 | 
| CSF | Literal | 00 - 00000000010101 | SF = 0 |
| CZF | Literal | 00 - 00000000010110 | ZF = 0 |
| CCF | Literal | 00 - 00000000010111 | CF = 0 |
| RET | Literal | 00 - 00000000011000 | Pop, store to PC | 
| *CIF | Literal | 00 - 00000000011001 | IF = 0 | 
| *INN | Literal | 00 - 00000000011010 | *IX = OX |
| *OUT | Literal | 00 - 00000000011011 | *OX = IX |
| *IRT | Literal | 00 - 00000000011100 | IF = 1, Mode = 0, Pop, store to PC | 
| *HLT | Literal | 00 - 11111111111111 | Halt system clock |
| PSH | Single Register | 01 - 00000000000 - XXX | Push X |
| POP | Single Register | 01 - 00000000001 - XXX | Pop, store to X |
| NOT | Single Register | 01 - 00000000010 - XXX | ¬ X |
| JPR | Single Register | 01 - 00000000011 - XXX | PC = *X |
| CLR | Single Register | 01 - 00000000100 - XXX | Push PC to, PC = *X |
| *SMB | Single Register | 01 - 00000000101 - XXX | MBR = X | 
| *SML | Single Register | 01 - 00000000110 - XXX | MLR = X | 
| *STQ | Single Register | 01 - 00000000111 - XXX | TQR = X | 
| MOV | Double Register | 10 - 0000000 - Z- XXX - YYY | Y = X |
| STR | Double Register | 10 - 0000001 - XXX - Z - YYY | Y = X |
| ADD | Double Register | 10 - 0000010 - XXX - Z - YYY | X + Y | 
| ADC | Double Register | 01 - 0000011 - XXX - Z - YYY | X + Y with carry | 
| SUB | Double Register | 01 - 0000100 - XXX - Z - YYY | X - Y |
| SBB | Double Register | 01 - 0000101 - XXX - Z - YYY | X - Y with borrow | 
| ORR | Double Register | 01 - 0000110 - XXX - Z - YYY | X ∨ Y |
| AND | Double Register | 01 - 0000111 - XXX - Z - YYY | X ∧ Y | 
| XOR | Double Register | 01 - 0001000 - XXX - Z - YYY | X ⊕ Y |
| CMP | Double Register | 01 - 0001001 - XXX - Z - YYY | Compare X to Y, set flags |
| JCR | Double Register | 01 - 0001010 - FFF - Z - XXX | If F, jump to *X |
| CLC | Double Register | 01 - 0001011 - FFF - Z - XXX | If F, push PC, PC = X |
| JMP | Immediate | 11 - 00 - IIIIIIIIIIIIII | PC = I |
| CAL | Immediate | 11 - 01 - IIIIIIIIIIIIII | Push PC, PC = I |
| INT | Immediate | 11 - 10 - IIIIIIIIIIIIII | IF = 0, Mode = 1, Push PC, PC = *I -> IVT | 


## Registers:

### General Purpose:

- AX - 000 - alu accumulator
- BX - 001 - immediate
- CX - 010 
- DX - 011
- EX - 100
- FX - 101
- IX - 110 - io in
- OX - 111 - io out

### Special:
Unlike gp registers, most of these cannot be written to directly, at least without privledged access.

- Instruction Register - holds the instruction which is currently being executed
- Program Counter - address of next instruction to be fetched
- Memory Address Register - holds the address of the memory location being accessed
- Memory Data Register - holds the data about to be written to memory
- Memory Base Register - the first memory address that an unprivledged process access is permited to 
- Memory Limit Register - the last memory address that an unprivledged process access is permited to
- Time Quantum Register - how many clocks until an interrupt will be triggered
- Stack Pointer
- Mode (1)
- Flags
    - 000 - Sign Flag
    - 001 - Zero Flag
    - 010 - Carry Flag
    - 100 - Interrupt Flag


