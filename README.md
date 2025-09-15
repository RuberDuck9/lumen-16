16 Bit ISA 

Format 1: Literal   
| 00 | 00000000000000 |
       
Format 2: Register    
| 01 | 000000 | 0 | 000 | 0 | 000 |

Format 3: Immediate 
| 10 | 000 | 

| Instruction | Format Type | Bit format | Description |
| ----------- | ----------- | ---------- | ----------- | 
| NOP | Literal | 00 - 0000000000000000 | Do nothing |
| MOV | Register | 01 - 0000000 - XXX - Z - YYY | perform Y = X |
| ADD | Register | 01 - 0000001 - XXX - Z - YYY | perform X + Y | 
| ADC | Register | 01 - 0000010 - XXX - Z - YYY | perform with carry X + Y | 
| SUB | Register | 01 - 0000011 - XXX - Z - YYY | perform X - Y |
| SBB | Register | 01 - 0000100 - XXX - Z - YYY | perform with borrow X - Y | 
| ORR | Register | 01 - 0000101 - XXX - Z - YYY | perform X ∨ Y |
| AND | Register | 01 - 0000110 - XXX - Z - YYY | perform X ∧ Y | 
| XOR | Register | 01 - 0000111 - XXX - Z - YYY | perform X ⊕ Y |

