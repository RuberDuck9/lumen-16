**Note: This project is currently in active development and is not feature complete**

This project is a continuation of [my former design](https://github.com/RuberDuck9/ryft-16), which I felt the need to rewrite after feature creep got to be too much. The goal of this isa is to be simple, but also powerful. Beyond simply being turing complete it also seeks to support: 
- Pre-emptive scheduling
- Hardware level memory protection
- Multiple operation modes (Ring 0, Ring 3)
- Hardware and software level interrupts
- Persistant bios

## Instructions 

### Format
The instruction word size is two bytes. There are four different formats of instructions depending on the type of operation they perform.
 
Format 1: Literal      
| 00 - 00000000 - UUUUUU |   

Format 2: Single Register    
| 01 - 00000000 - UUU - XXX |   
       
Format 3: Double Register      
| 10 - 00000000 - XXX - YYY |        

Format 4: Immediate    
| 11 - 00 - IIIIIIIIIIIIII |      
I = immediate value

### Opcodes

U = Unused Bit   
X,Y = Register or Memory Address   
F = Flag Register Address   
"*" = Privledged Instruction  

| Instruction | Format Type | Bit format | Description |
| ----------- | ----------- | ---------- | ----------- | 
| NOP | Literal | 00 - 00000000 - UUUUUU | Do nothing |
| SSF | Literal | 00 - 00000001 - UUUUUU | SF = 1 |
| SZF | Literal | 00 - 00000010 - UUUUUU | ZF = 1 |
| SCF | Literal | 00 - 00000011 - UUUUUU | CF = 1 |
| CSF | Literal | 00 - 00000100 - UUUUUU | SF = 0 |
| CZF | Literal | 00 - 00000101 - UUUUUU | ZF = 0 |
| CCF | Literal | 00 - 00000110 - UUUUUU | CF = 0 |
| RET | Literal | 00 - 00000111 - UUUUUU | Pop, store to PC | 
| *SIF | Literal | 00 - 00001000 - UUUUUU | IF = 1 | 
| *CIF | Literal | 00 - 00001001 - UUUUUU | IF = 0 | 
| *INN | Literal | 00 - 00001010 - UUUUUU | *IX = OX |
| *OUT | Literal | 00 - 00001011 - UUUUUU | *OX = IX |
| *IRT | Literal | 00 - 00001100 - UUUUUU | IF = 1, Mode = 0, Pop, store to PC | 
| *HLT | Literal | 00 - 11111111 - UUUUUU | Halt system clock |
| INC | Single Register | 01 - 00000000 - UUU - XXX | X + 1 |
| DEC | Single Register | 01 - 00000001 - UUU - XXX | X - 1 |
| PSH | Single Register | 01 - 00000010 - UUU - XXX | Push X |
| POP | Single Register | 01 - 00000011 - UUU - XXX | Pop, store to X |
| NOT | Single Register | 01 - 00000100 - UUU - XXX | ¬ X |
| JPR | Single Register | 01 - 00000101 - UUU - XXX | PC = *X |
| CLR | Single Register | 01 - 00000110 - UUU - XXX | Push PC to, PC = *X |
| *SMB | Single Register | 01 - 00000111 - UUU - XXX | MBR = X | 
| *SML | Single Register | 01 - 00001000 - UUU - XXX | MLR = X | 
| *STQ | Single Register | 01 - 00001001 - UUU - XXX | TQR = X | 
| *SSB | Single Register | 01 - 00001010 - UUU - XXX | SBR = X | 
| MOV | Double Register | 10 - 00000000 - XXX - YYY | X = Y |
| STR | Double Register | 10 - 00000001 - XXX - *YYY | X = Y |
| LOD | Double Register | 10 - 00000010 - *XXX - YYY | X = Y | 
| ADD | Double Register | 10 - 00000011 - XXX - YYY | X + Y | 
| ADC | Double Register | 01 - 00000100 - XXX - YYY | X + Y with carry | 
| SUB | Double Register | 01 - 00000101 - XXX - YYY | X - Y |
| SBB | Double Register | 01 - 00000110 - XXX - YYY | X - Y with borrow | 
| ORR | Double Register | 01 - 00000111 - XXX - YYY | X ∨ Y |
| AND | Double Register | 01 - 00001000 - XXX - YYY | X ∧ Y | 
| XOR | Double Register | 01 - 00001001 - XXX - YYY | X ⊕ Y |
| CMP | Double Register | 01 - 00001010 - XXX - YYY | Compare X to Y, set flags |
| JCR | Double Register | 01 - 00001011 - FFF - XXX | If F, jump to *X |
| JCN | Double Register | 01 - 00001100 - FFF - XXX | If ¬F, jump to *X |
| CLC | Double Register | 01 - 00001101 - FFF - XXX | If F, push PC, PC = X |
| CCN | Double Register | 01 - 00001110 - FFF - XXX | If ¬F, push PC, PC = X |
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
- Stack Base Register
- Stack Pointer
- Mode (1)
- Flags
    - 000 - Sign Flag
    - 001 - Zero Flag
    - 010 - Carry Flag
    - 100 - Interrupt Flag


