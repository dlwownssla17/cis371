/* Hannes Leipold, 84591119 */

`timescale 1ns / 1ps

/* Prevent implicit wire declaration
 *
 * This directive will cause Vivado to give an error if you
 * haven't declared a wire (including if you have a typo.
 * 
 * The price you pay for this is that you have to write
 * "input wire" and "output wire" for all your ports
 * instead of just "input" and "output".
 * 
 * All the provided infrastructure code has been updated.
*/

`default_nettype none

module lc4_alu( input wire [15:0] i_isn,
                input wire [15:0] i_pc,
                input wire [15:0] i_r1data,
                input wire [15:0] i_r2data,
                output wire [15:0] o_result);
                    
// opcode
wire [3:0] opcode = i_isn[15:12];
// most common subcode (not for compare & jumps)
wire [5:0] test = i_isn[5:0];
wire [2:0] subcode = i_isn[5:3];
wire add2_code = i_isn[5];
// Check for 0000 block branch set
wire is_br = (opcode == 4'b0000);
// Check for 0001 block airthmetic set
wire is_arith = (opcode == 4'b0001);
// ADD == 000
wire is_add = is_arith ? (subcode == 3'b000) : 0;
// MUL == 001
wire is_mul = is_arith ? (subcode == 3'b001) : 0;
// SUB == 010
wire is_sub = is_arith ? (subcode == 3'b010) : 0;
// DIV == 011 
wire is_div = is_arith ? (subcode == 3'b011) : 0;
// ADD2 == 1XX (instant!)
wire is_add2 = is_arith ? (subcode[2] == 1) : 0; 

// Check for 0010 block compare set (different subcode!)
wire is_com = (opcode == 4'b0010);
// Special subcode
wire [8:7] comcode = i_isn[8:7];
// CMP
wire is_cmp = is_com ? (comcode == 3'b00) : 0;
// CMPU
wire is_cmpu = is_com ? (comcode == 3'b01) : 0;
// CMPI (instant!)
wire is_cmpi = is_com ? (comcode == 3'b10) : 0;
// CMPIU (instant!)
wire is_cmpiu = is_com ? (comcode == 3'b11) : 0;

// Check for 0100 block subroutine set
wire is_subrout = (opcode == 4'b0100);
// JSRR 
wire is_jsrr = is_subrout ? (i_isn[11] == 0) : 0;
// JSR
wire is_jsr = is_subrout ? (i_isn[11] == 1) : 0;

// Check for 0101 block logic set
wire is_logic = (opcode == 4'b0101);
// AND == 000
wire is_and = is_logic ? (subcode == 3'b000) : 0;
// NOT == 001
wire is_not = is_logic ? (subcode == 3'b001) : 0;
// OR == 001
wire is_or = is_logic ? (subcode == 3'b010) : 0;
// XOR == 001
wire is_xor = is_logic ? (subcode == 3'b011) : 0;
// AND2 == 1XX (instant!)
wire is_and2 = is_logic ? (subcode[2] == 1) : 0;

// Check for 1010 block shifter set
wire is_shift = (opcode == 4'b1010);
wire [1:0] shift_code = subcode[2:1];
// SLL (instant!)
wire is_sll = is_shift ? (subcode[2:1] == 2'b00) : 0;
// SRA (instant!) 
wire is_sra = is_shift ? (shift_code == 2'b01) : 0;
// SRL (instant!)
wire is_srl = is_shift ? (shift_code == 2'b10) : 0;
// SRL
wire is_mod = is_shift ? (shift_code == 2'b11) : 0;

/* LOOSE LEAF OPERATORS */
// Check for 0110 LOAD instruction
wire is_ldr = (opcode == 4'b0110);
// Check for 0111 STORE instruction
wire is_str = (opcode == 4'b0111);
// Check for 1000 RTI instruction
wire is_rti = (opcode == 4'b1000);
// Check for 1001 CONST instruction
wire is_const = (opcode == 4'b1001);
// Check for 11000 JMPR instruction
wire is_jmpr = (opcode == 4'b1100) && (i_isn[11] == 0);
// Check for 11001 JMP instruction
wire is_jmp = (opcode == 4'b1100) && (i_isn[11] == 1);
// Check for 1101 HICONST instruction
wire is_hicon = (opcode == 4'b1101);
// Check for 1111 TRAP instruction
wire is_trap = (opcode == 4'b1111); 

/* ---------------------------------------- CALCULATIONS ------------------------------------------- */
// DIVIDER
wire [15:0] calc_div;
wire [15:0] calc_mod;
lc4_divider divider (i_r1data, i_r2data, calc_mod, calc_div);                                                

// COMPARISONS
wire [15:0] cmp_inst = {{9{i_isn[6]}},i_isn[6:0]};
wire [15:0] cmp_instu = {{9{1'b0}},i_isn[6:0]};
wire [15:0] calc_cmpu = (i_r1data > i_r2data) ? 1 :
                        (i_r2data > i_r1data) ? -1 :
                        0;
wire [15:0] calc_cmpiu =    (i_r1data > cmp_instu) ? 1 :
                            (cmp_instu > i_r1data) ? -1 :
                            0;
wire [15:0] calc_cmpii =   (i_r1data > cmp_inst) ? 1 :
                            (cmp_inst > i_r1data) ? -1 :
                            0;
wire [15:0] calc_cmpu_inv = (i_r2data > i_r1data) ? 1 :
                            (i_r1data > i_r2data) ? -1 :
                            0;                        
wire [15:0] calc_cmp = (i_r1data[15] == 0 && i_r2data[15] == 1) ? 1 :
                       (i_r1data[15] == 1 && i_r2data[15] == 0) ? -1 :
                       (i_r1data[15] == 0 && i_r2data[15] == 0) ? calc_cmpu : calc_cmpu;
wire [15:0] calc_cmpi = (i_r1data[15] == 0 && cmp_inst[15] == 1) ? 1 :
                        (i_r1data[15] == 1 && cmp_inst[15] == 0) ? -1 :
                        (i_r1data[15] == 0 && cmp_inst[15] == 0) ? (calc_cmpii) : calc_cmpii;

// JSR
wire [15:0] calc_jsr;
lc4_sll jsr_sll({{5{1'b0}},i_isn[10:0]},16'b0000000000000100, calc_jsr);

// SHIFTERS
wire [15:0] calc_sra;
lc4_sra sra(i_r1data,{{12{1'b0}},i_isn[3:0]},calc_sra);
wire [15:0] calc_srl;
lc4_srl srl(i_r1data,{{12{1'b0}},i_isn[3:0]},calc_srl);
wire [15:0] calc_sll;
lc4_sll sll(i_r1data,{{12{1'b0}},i_isn[3:0]},calc_sll);

// HICONST
wire [15:0] calc_hicon_sll;
lc4_sll hicon_sll({{8{1'b0}},i_isn[7:0]},16'b0000000000001000,calc_hicon_sll);

// BIG NESTED LOOP?
assign o_result =   (is_br)     ?   (i_pc + 1 + {{7{i_isn[8]}},i_isn[8:0]}) :
                    (is_add)    ?   (i_r1data + i_r2data) :
                    (is_mul)    ?   (i_r1data * i_r2data) :
                    (is_sub)    ?   (i_r1data - i_r2data) :
                    (is_div)    ?   (calc_div) :
                    (is_add2)   ?   (i_r1data + {{11{i_isn[4]}},i_isn[4:0]}) :                    
                    (is_cmp)    ?   (calc_cmp) :
                    (is_cmpu)   ?   (calc_cmpu) :
                    (is_cmpi)   ?   (calc_cmpi) :
                    (is_cmpiu)  ?   (calc_cmpiu) :
                    (is_jsrr)   ?   (i_r1data) :
                    (is_jsr)    ?   ({i_pc[15],calc_jsr[14:0]}) :
                    (is_and)    ?   (i_r1data & i_r2data) :
                    (is_not)    ?   (~ i_r1data) :
                    (is_or)     ?   (i_r1data | i_r2data) :
                    (is_xor)    ?   (i_r1data ^ i_r2data) :
                    (is_and2)   ?   (i_r1data & {{11{i_isn[4]}},i_isn[4:0]}) :
                    (is_ldr)    ?   (i_r1data + {{10{i_isn[5]}},i_isn[5:0]}) :
                    (is_str)    ?   (i_r1data + {{10{i_isn[5]}},i_isn[5:0]}) :
                    (is_rti)    ?   (i_r1data) :
                    (is_const)  ?   ({{7{i_isn[8]}},i_isn[8:0]}) :
                    (is_sll)    ?   (calc_sll) :
                    (is_sra)    ?   (calc_sra) :
                    (is_srl)    ?   (calc_srl) :  
                    (is_mod)    ?   (calc_mod) :
                    (is_jmpr)   ?   (i_r1data) :
                    (is_jmp)    ?   (i_pc + 1 + {{5{i_isn[10]}},i_isn[10:0]}) :
                    (is_hicon)  ?   ((i_r1data & 16'b0000000011111111) | calc_hicon_sll) :
                    (is_trap)   ?   (16'b1000000000000000 | {{8{1'b0}},i_isn[7:0]}) :
                        0;

endmodule

// SHIFT LEFT LOGICAL
module lc4_sll( input wire [15:0] i_val,
                input wire [15:0] i_bit,
                output wire [15:0] o_shift);

wire [15:0] b1 = i_bit[3] ? {i_val[7:0],{8{1'b0}}} : i_val;
wire [15:0] b2 = i_bit[2] ? {b1[11:0], {4{1'b0}}} : b1; 
wire [15:0] b3 = i_bit[1] ? {b2[13:0], {2{1'b0}}} : b2;
wire [15:0] b4 = i_bit[0] ? {b3[14:0], {1{1'b0}}} : b3;

assign o_shift = b4;

endmodule

// SHIFT RIGHT LOGICAL
module lc4_srl( input wire [15:0] i_val,
                input wire [15:0] i_bit,
                output wire [15:0] o_shift);

wire [15:0] b1 = i_bit[3] ? {{8{1'b0}}, i_val[15:8]} : i_val;
wire [15:0] b2 = i_bit[2] ? {{4{1'b0}}, b1[15:4]} : b1; 
wire [15:0] b3 = i_bit[1] ? {{2{1'b0}}, b2[15:2]} : b2;
wire [15:0] b4 = i_bit[0] ? {{1{1'b0}}, b3[15:1]} : b3;

assign o_shift = b4;

endmodule

// SHIFT RIGHT ARITHMETIC
module lc4_sra( input wire [15:0] i_val,
                input wire [15:0] i_bit,
                output wire [15:0] o_shift);

wire [15:0] b1 = i_bit[3] ? {{8{i_val[15]}}, i_val[15:8]} : i_val;
wire [15:0] b2 = i_bit[2] ? {{4{b1[15]}}, b1[15:4]} : b1; 
wire [15:0] b3 = i_bit[1] ? {{2{b2[15]}}, b2[15:2]} : b2;
wire [15:0] b4 = i_bit[0] ? {{1{b3[15]}}, b3[15:1]} : b3;

assign o_shift = b4;

endmodule
