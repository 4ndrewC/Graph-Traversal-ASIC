`ifndef __FMT__
`define __FMT__ 

`define PC 3'b000
`define SREG 3'b001
`define ra 3'b010
`define rb 3'b011
`define rc 3'b100
`define rn 3'b101
`define sp 3'b110
`define rp 3'b111

`define WORD 32
`define MEMSIZE 4200448
`define REGISTERS 8
`define OPSIZE 6
`define NODE_BITS 15
`define NODES 2048
`define VIS_OFFSET 4196352
`define STACK_OFFSET 4198400

`define Cf 0
`define Zf 1
`define If 2
`define Nf 3

`define ADD 6'b000000
`define ADDI 6'b000001
`define SUB 6'b000010
`define SUBI 6'b000011
`define AND 6'b000100
`define ANDI 6'b000101
`define OR 6'b000110
`define ORI 6'b000111
`define XOR 6'b001000
`define XORI 6'b001001

`define CMP 6'b001010
`define CMPI 6'b001011
`define LDI 6'b001100
`define LDA 6'b001101
`define LDW 6'b001110
`define JMP 6'b001111
`define RJMP 6'b010000
`define BREQ 6'b010001
`define MOV 6'b010010
`define CLR 6'b010011
`define CLC 6'b010100
`define CLZ 6'b010101
`define CLN 6'b010110
`define CLS 6'b010111
`define CLI 6'b011000
`define SLC 6'b011001
`define SLZ 6'b011010
`define SLN 6'b011011
`define SLS 6'b011100
`define SLI 6'b011101

`define STRN 6'b011110
`define SVS 6'b011111
`define CVS 6'b100000
`define ADG 6'b100001
`define RDG 6'b100010
`define STW 6'b100011
`define LDWR 6'b100100
`define SCN 6'b100101
`define STYP 6'b100110
`define STEP 6'b100111


`endif
