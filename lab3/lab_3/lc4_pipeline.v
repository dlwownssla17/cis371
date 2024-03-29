`timescale 1ns / 1ps

// disable implicit wire declaration
`default_nettype none

module lc4_processor
(input  wire        clk,                // main clock
 input  wire        rst,                // global reset
 input  wire        gwe,                // global we for single-step clock

 output wire [15:0] o_cur_pc,           // Address to read from instruction memory
 input  wire [15:0] i_cur_insn,         // Output of instruction memory
 output wire [15:0] o_dmem_addr,        // Address to read/write from/to data memory
 input  wire [15:0] i_cur_dmem_data,    // Output of data memory
 output wire        o_dmem_we,          // Data memory write enable
 output wire [15:0] o_dmem_towrite,     // Value to write to data memory

 output wire [1:0]  test_stall,         // Testbench: is this is stall cycle? (don't compare the test values)
 output wire [15:0] test_cur_pc,        // Testbench: program counter
 output wire [15:0] test_cur_insn,      // Testbench: instruction bits
 output wire        test_regfile_we,    // Testbench: register file write enable
 output wire [2:0]  test_regfile_wsel,  // Testbench: which register to write in the register file 
 output wire [15:0] test_regfile_data,  // Testbench: value to write into the register file
 output wire        test_nzp_we,        // Testbench: NZP condition codes write enable
 output wire [2:0]  test_nzp_new_bits,  // Testbench: value to write to NZP bits
 output wire        test_dmem_we,       // Testbench: data memory write enable
 output wire [15:0] test_dmem_addr,     // Testbench: address to read/write memory
 output wire [15:0] test_dmem_data,     // Testbench: value read/writen from/to memory


 // State of the zedboard switches, LCD and LEDs
 // You are welcome to use the Zedboard's LCD number display and LEDs
 // for debugging purposes, but it isn't terribly useful.  Ditto for
 // reading the switch positions from the Zedboard

 input  wire [7:0]  switch_data,        // Current settings of the Zedboard switches
 output wire [15:0] seven_segment_data, // Data to display to the Zedboard LCD
 output wire [7:0]  led_data            // Which Zedboard LEDs should be turned on?

 );

`include "include/lc4_prettyprint_errors.v"

 /*** YOUR CODE HERE ***/
 // IMPLEMENT STALL AND FLUSH LOGIC NEXT WEEK
 wire [1:0] is_stall = 0;
 wire is_flush ; //= 0; 
 wire [1:0] f_stall = 0;
 wire load_to_use_stall;
 
 wire [2:0]     w_wsel;
 wire           x_is_load;
 wire [2:0]     m_wsel;
 wire           m_nzp_we;
 wire           w_nzp_we;
 wire           w_regfile_we;

 /*********************************************************************************************************************/
 /****************************************************** FETCH   ******************************************************/
 /*********************************************************************************************************************/
 /********** FETCH STAGE PREAMBLE **********/
 wire [15:0] f_pc;
 wire [15:0] f_insn;
 wire [15:0] next_pc;

 Nbit_reg #(16, 16'h8200) f_pc_reg       (.in(next_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  

 /********** FETCH STAGE IMPLEMENTATION **********/
 assign next_pc = (load_to_use_stall) ? f_pc : (is_flush) ? o_alu : f_pc + 1;  // i think this is wrong, changed from x_pc to o_alu
 assign f_insn = (is_stall || load_to_use_stall) ? (d_insn) : 
 (is_flush) ? (16'h0000) : i_cur_insn;
 wire [15:0] f_temp_pc = (is_stall || load_to_use_stall) ? d_pc : f_pc;
 assign o_cur_pc = f_pc;
  
 /*********************************************************************************************************************/
 /****************************************************** DECODE  ******************************************************/
 /*********************************************************************************************************************/
 /********** DECODE STAGE PREAMBLE **********/
 wire [15:0] d_pc;
 wire [15:0] d_insn;    
 wire [1:0] d_stall;

 /** FROM FETCH TO DECODE **/    
 Nbit_reg #(16, 16'h0000)    d_pc_reg    (.in(f_temp_pc), .out(d_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    d_insn_reg  (.in(f_insn), .out(d_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // MIGHT NEED TO CHANGE THIS NEXT WEEK

 wire [1:0] f_temp_stall = ( is_flush ) ? 2'd2 : f_stall;

 Nbit_reg #(2, 2'b10)        d_stall_reg (.in(f_temp_stall), .out(d_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // From the decoder
 wire [2:0]     d_r1sel;
 wire [2:0]     d_r2sel;
 wire           d_r1re;
 wire           d_r2re;
 wire           d_select_pc_plus_one;
 wire           d_is_load;
 wire           d_is_store;
 wire           d_is_control_insn;
 wire           d_is_branch;
 wire [2:0]     d_wsel;
 wire           d_regfile_we;
 wire           d_nzp_we;
 wire [0:15]    d_ort_data;
 wire [0:15]    d_ors_data;
 wire [0:15]    d_rt_data;
 wire [0:15]    d_rs_data;

 /********** DECODE STAGE IMPLEMENTATION **********/
 lc4_decoder decoder (d_insn, d_r1sel, d_r1re, d_r2sel, d_r2re, d_wsel, d_regfile_we, d_nzp_we, d_select_pc_plus_one, d_is_load, d_is_store, d_is_branch, d_is_control_insn);
 lc4_regfile regfile (clk, gwe, rst, d_r1sel, d_ors_data, d_r2sel, d_ort_data, w_wsel, w_result, w_regfile_we);

 assign d_rs_data = (d_r1sel == w_wsel && w_regfile_we) ? w_result : d_ors_data;
 assign d_rt_data = (d_r2sel == w_wsel && w_regfile_we) ? w_result : d_ort_data;

 //assign alu_1 =  ( (x_r1sel == m_wsel) && (m_regfile_we) ) ? m_oresult : 
 //                    ( (x_r1sel == w_wsel) && (w_regfile_we) ) ? w_oresult : x_r1data;

 assign load_to_use_stall = ( x_is_load ) && (( d_r1sel == x_wsel && d_r1re ) || (( d_r2sel == x_wsel && d_r2re ) && (!d_is_store)));
 /*********************************************************************************************************************/
 /****************************************************** EXECUTE ******************************************************/
 /*********************************************************************************************************************/
 /********** EXECUTE STAGE PREAMBLE **********/
 wire [15:0]    x_pc;
 wire [15:0]    x_insn;
 wire [2:0]     x_r1sel;
 wire [2:0]     x_r2sel;
 wire           x_r1re;
 wire           x_r2re;
 wire           x_select_pc_plus_one;
// wire           x_is_load;
 wire           x_is_store;
 wire           x_is_control_insn;
 wire           x_is_branch;
 wire [2:0]     x_wsel;
 wire           x_regfile_we;
 wire           x_nzp_we;
 wire [15:0]    x_r1data;
 wire [15:0]    x_r2data;

 wire [1:0]     x_stall;

 wire [15:0] d_temp_insn =  ( d_stall ) ? (x_insn) : 
 (is_flush || load_to_use_stall) ? (16'h0000) : d_insn;


 wire xt_r1re = (is_flush || load_to_use_stall) ? 1'b0 : d_r1re;
 wire xt_r2re = (is_flush || load_to_use_stall) ? 1'b0 : d_r2re;
 wire xt_select_pc_plus_one  = (is_flush || load_to_use_stall) ? 1'b0 : d_select_pc_plus_one;
 wire xt_is_load = (is_flush || load_to_use_stall) ? 1'b0 : d_is_load;
 wire xt_is_store = (is_flush || load_to_use_stall) ? 1'b0 : d_is_store;
 wire xt_is_control_insn = (is_flush || load_to_use_stall) ? 1'b0 : d_is_control_insn;
 wire xt_is_branch = (is_flush || load_to_use_stall) ? 1'b0 : d_is_branch;

 wire xt_regfile_we = (is_flush || load_to_use_stall) ? 1'b0 : d_regfile_we;
 wire xt_nzp_we = (is_flush || load_to_use_stall) ? 1'b0 : d_nzp_we;


 /** FROM DECODE TO EXECUTE **/ 
 Nbit_reg #(16, 16'h0000)    x_pc_reg                    (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_insn_reg                  (.in(d_temp_insn), .out(x_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r1sel_reg                 (.in(d_r1sel), .out(x_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_r2sel_reg                 (.in(d_r2sel), .out(x_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r1re_reg                  (.in(xt_r1re), .out(x_r1re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_r2re_reg                  (.in(xt_r2re), .out(x_r2re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_select_pc_plus_one_reg    (.in(xt_select_pc_plus_one), .out(x_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_load_reg               (.in(xt_is_load), .out(x_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_store_reg              (.in(xt_is_store), .out(x_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_control_insn_reg       (.in(xt_is_control_insn), .out(x_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_is_branch_reg             (.in(xt_is_branch), .out(x_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_wsel_reg                  (.in(d_wsel), .out(x_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       x_regfile_we_reg            (.in(xt_regfile_we), .out(x_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         x_nzp_we_reg                (.in(xt_nzp_we), .out(x_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r1data_reg                (.in(d_rs_data), .out(x_r1data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    x_r2data_reg                (.in(d_rt_data), .out(x_r2data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // MIGHT NEED TO CHANGE THIS NEXT WEEK 
 wire [1:0] d_temp_stall = ( load_to_use_stall ) ? 2'd3 : ( is_flush ) ? 2'd2 : d_stall;
 Nbit_reg #(2, 2'b10)         x_stall_reg                 (.in(d_temp_stall), .out(x_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 wire [2:0] curr_nzp; // FROM REGFILE

 /********** EXECUTE STAGE IMPLEMENTATION **********/

 wire [15:0] x_pc_plus_one = x_pc+1;
 wire [15:0] o_alu;
 // BYPASS:
 wire [15:0] alu_1;
 assign alu_1 =  ( (x_r1sel == m_wsel) && (m_regfile_we) ) ? m_oresult : 
                 ( (x_r1sel == w_wsel) && (w_regfile_we) ) ? w_result : x_r1data;

 wire [15:0] alu_2;
 assign alu_2 = ( (x_r2sel == m_wsel) && (m_regfile_we) ) ? m_oresult :
                ( (x_r2sel == w_wsel) && (w_regfile_we) ) ? w_result : x_r2data;

 // ALU
 lc4_alu alu (x_insn, x_pc, alu_1, alu_2, o_alu);
 wire [15:0] x_oresult = ( x_select_pc_plus_one ) ? ( x_pc_plus_one ) : ( o_alu ); 

 // BRANCH LOGIC
 wire [2:0] br_nzp; // TODO: change this
 assign br_nzp = ( m_nzp_we ) ? ( m_nzp_bits ) : 
 ( w_nzp_we ) ? ( w_nzp_bits ) : ( curr_nzp );

 wire o_branch = !( ( x_insn[11:9] & br_nzp ) == 3'b000);
 assign is_flush = (( o_branch & x_is_branch ) | x_is_control_insn); // if we are taking a branch, flush old instrucions

 // PC_MUX
 //    assign  next_pc = 16'h0000;//( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
 //assign o_cur_pc = pc;

 // COMPUTE EXECUTE NZP BITS    
 wire [2:0] x_nzp_bits;
 assign x_nzp_bits[2] = x_oresult[15];
 assign x_nzp_bits[1] = (x_oresult == 16'h0000);
 assign x_nzp_bits[0] = (!x_oresult[15]) & (!x_nzp_bits[1]);
 
 wire [15:0] x_temp_r2data = (x_is_store && x_r2sel == m_wsel && m_regfile_we) ? w_result : x_r2data;

 /*********************************************************************************************************************/
 /****************************************************** MEMORY  ******************************************************/
 /*********************************************************************************************************************/
 /********** MEMORY STAGE PREAMBLE **********/
 wire [15:0]    m_pc;
 wire [15:0]    m_insn;
 wire [2:0]     m_r1sel;
 wire [2:0]     m_r2sel;
// wire           m_r1re;
// wire           m_r2re;
// wire           m_select_pc_plus_one;
 wire           m_is_load;
 wire           m_is_store;
// wire           m_is_control_insn;
// wire           m_is_branch;
 //wire [2:0]     m_wsel;
  wire           m_regfile_we;
 //wire           m_nzp_we;
 wire [15:0]    m_r1data;
 wire [15:0]    m_r2data;
 wire [2:0]     m_nzp_bits;
 wire [15:0]    m_oresult;
 wire [15:0]    m_oalu;
 wire [15:0]    m_wdata;
 wire [1:0]     m_stall;

 /** FROM EXECUTE TO MEMORY **/
 Nbit_reg #(16, 16'h0000)    m_pc_reg                   (.in(x_pc), .out(m_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_insn_reg                 (.in(x_insn), .out(m_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r1sel_reg                (.in(x_r1sel), .out(m_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_r2sel_reg                (.in(x_r2sel), .out(m_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         m_r1re_reg                 (.in(x_r1re), .out(m_r1re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         m_r2re_reg                 (.in(x_r2re), .out(m_r2re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         m_select_pc_plus_one_reg   (.in(x_select_pc_plus_one), .out(m_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_load_reg              (.in(x_is_load), .out(m_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_is_store_reg             (.in(x_is_store), .out(m_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
// Nbit_reg #(1, 1'b0)         m_is_control_insn_reg      (.in(x_is_control_insn), .out(m_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
// Nbit_reg #(1, 1'b0)         m_is_branch_reg            (.in(x_is_branch), .out(m_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_wsel_reg                 (.in(x_wsel), .out(m_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_regfile_we_reg           (.in(x_regfile_we), .out(m_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         m_nzp_we_reg               (.in(x_nzp_we), .out(m_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r1data_reg               (.in(alu_1), .out(m_r1data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_r2data_reg               (.in(alu_2), .out(m_r2data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       m_nzp_reg                  (.in(x_nzp_bits), .out(m_nzp_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 // MIGHT NEED TO CHANGE THIS NEXT WEEK 
 Nbit_reg #(2, 2'b10)        m_stall_reg                (.in(x_stall), .out(m_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 /** SPECIAL FROM EXECUTE **/
 Nbit_reg #(16, 16'h0000)    m_oresult_reg              (.in(x_oresult), .out(m_oresult), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    m_oalu_reg                 (.in(o_alu), .out(m_oalu), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(3, 3'b000) mem_reg (.in(nzp_new_bits), .out(curr_nzp), .clk(clk), .we(m_nzp_we), .gwe(gwe), .rst(rst));  

 /********** MEMORY STAGE IMPLEMENTATION **********/ 
 wire [15:0]    m_dmem_data; 
 wire [15:0]    m_dmem_addr;
 wire [15:0]    m_dmem_towrite;
 wire           m_dmem_we;

 // 0 if no load / store??? CHECK THIS
 assign o_dmem_towrite = ( m_is_store ) ? ( ( w_regfile_we && ( w_wsel == m_r2sel ) ) ? w_result : m_r2data ) : 16'h0000;
 assign o_dmem_addr = ( m_is_load | m_is_store ) ? m_oalu : 16'h0000;
 assign o_dmem_we = m_is_store;
 assign m_dmem_towrite = o_dmem_towrite;
 assign m_dmem_data = ( m_is_load ) ? i_cur_dmem_data : 16'h0000;
 assign m_dmem_addr = o_dmem_addr;
 assign m_dmem_we = o_dmem_we;
 
 /*************************************************************************************************************************/
 /****************************************************** WRITEBACK   ******************************************************/
 /*************************************************************************************************************************/
 /********** WRITEBACK STAGE PREAMBLE **********/
 wire [15:0]    w_pc;
 wire [15:0]    w_insn;
 wire [2:0]     w_r1sel;
 wire [2:0]     w_r2sel;
 // wire           w_r1re;
 // wire           w_r2re;
 // wire           w_select_pc_plus_one;
 wire           w_is_load;
 // wire           w_is_store;
 // wire           w_is_control_insn;
 // wire           w_is_branch;
 //wire [2:0]     w_wsel;
// wire           w_regfile_we;
// wire           w_nzp_we;
 wire [15:0]    w_r1data;
 wire [15:0]    w_r2data;
 wire [15:0]    w_wdata;
 wire [15:0]    w_oresult;
 wire [15:0]    w_result;
 wire [2:0]     w_nzp_bits;

 wire [15:0]    w_dmem_data; 
 wire [15:0]    w_dmem_towrite; 
 wire [15:0]    w_dmem_addr;
 wire           w_dmem_we;
 wire [1:0]     w_stall;

 /** FROM MEMORY TO WRITEBACK **/
 Nbit_reg #(16, 16'h0000)    w_pc_reg                   (.in(m_pc), .out(w_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_insn_reg                 (.in(m_insn), .out(w_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r1sel_reg                (.in(m_r1sel), .out(w_r1sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_r2sel_reg                (.in(m_r2sel), .out(w_r2sel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_r1re_reg                 (.in(m_r1re), .out(w_r1re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_r2re_reg                 (.in(m_r2re), .out(w_r2re), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_select_pc_plus_one_reg   (.in(m_select_pc_plus_one), .out(w_select_pc_plus_one), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_is_load_reg              (.in(m_is_load), .out(w_is_load), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_is_store_reg             (.in(m_is_store), .out(w_is_store), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_is_control_insn_reg      (.in(m_is_control_insn), .out(w_is_control_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 // Nbit_reg #(1, 1'b0)         w_is_branch_reg            (.in(m_is_branch), .out(w_is_branch), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_wsel_reg                 (.in(m_wsel), .out(w_wsel), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_regfile_we_reg           (.in(m_regfile_we), .out(w_regfile_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)         w_nzp_we_reg               (.in(m_nzp_we), .out(w_nzp_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r1data_reg               (.in(m_r1data), .out(w_r1data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)    w_r2data_reg               (.in(m_r2data), .out(w_r2data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(3, 3'b000)       w_nzp_reg                  (.in(m_nzp_bits), .out(w_nzp_bits), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
 Nbit_reg #(2, 2'b10)        w_stall_reg                (.in(m_stall), .out(w_stall), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));

 /** SPECIAL FROM MEMORY **/
 Nbit_reg #(16, 16'h0000)   w_oresult_reg               (.in(m_oresult), .out(w_oresult), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_data_reg             (.in(m_dmem_data), .out(w_dmem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_towrite_reg          (.in(m_dmem_towrite), .out(w_dmem_towrite), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(16, 16'h0000)   w_dmem_addr_reg             (.in(m_dmem_addr), .out(w_dmem_addr), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 Nbit_reg #(1, 1'b0)        w_dmem_we_reg               (.in(m_dmem_we), .out(w_dmem_we), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));
 
 assign w_result = ( w_is_load ) ? w_dmem_data : w_oresult;
 
 wire [2:0] w_temp_nzp_bits;
 assign w_temp_nzp_bits[2] = ( w_is_load ) ? (w_result[15]) : (w_nzp_bits[2]);
 assign w_temp_nzp_bits[1] = ( w_is_load ) ? (w_result == 16'h0000) : w_nzp_bits[1];
 assign w_temp_nzp_bits[0] = ( w_is_load ) ? ((!w_result[15]) & (!w_temp_nzp_bits[1])) : w_nzp_bits[0];
 
 /********** WRITEBACK STAGE IMPLEMENTATION **********/    
 // Assign curr_nzp
 Nbit_reg #(3, 3'b000) nzp_reg (.in(w_temp_nzp_bits), .out(curr_nzp), .clk(clk), .we(w_nzp_we), .gwe(gwe), .rst(rst));    
 // Write to regfile (see code in the decode stage)
 // BRANCH LOGIC
 //    wire [2:0] curr_nzp; // TODO: change this
 //    wire o_branch = !( ( i_cur_insn[11:9] & curr_nzp ) == 3'b000);

 // PC_MUX
 //    assign  next_pc = 16'h0000;//( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
 //assign o_cur_pc = pc;


 // Set test wires to correct outputs
 assign  test_stall = w_stall;                                      // Testbench: is this a stall cycle? (don't compare the test values)
 assign  test_cur_pc = w_pc;                                        // Testbench: program counter
 assign  test_cur_insn = w_insn;                                    // Testbench: instruction bits
 assign  test_regfile_we = w_regfile_we;                            // Testbench: register file write enable
 assign  test_regfile_wsel = w_wsel;                                // Testbench: which register to write in the register file 
 assign  test_regfile_data = w_result;                              // Testbench: value to write into the register file
 assign  test_nzp_we = w_nzp_we;                                    // Testbench: NZP condition codes write enable

 assign  test_nzp_new_bits[2] = w_temp_nzp_bits[2];                      // Testbench: value to write to NZP bits (Needs to be computed)
 assign  test_nzp_new_bits[1] = w_temp_nzp_bits[1];
 assign  test_nzp_new_bits[0] = w_temp_nzp_bits[0];

 assign  test_dmem_we = w_dmem_we;                                  // Testbench: data memory write enable
 assign  test_dmem_addr = w_dmem_addr;                              // Testbench: address to read/write memory
 assign  test_dmem_data = w_is_load ? w_dmem_data : w_dmem_towrite; // Testbench: value read/writen from/to memory


 /* Add $display(...) calls in the always block below to
  * print out debug information at the end of every cycle.
  * 
  * You may also use if statements inside the always block
  * to conditionally print out information.
  *
  * You do not need to resynthesize and re-implement if this is all you change;
  * just restart the simulation.
  */
 `ifndef NDEBUG
 always @(posedge gwe) begin
 // $display("%d %h %h %h %h %h", $time, f_pc, d_pc, e_pc, m_pc, test_cur_pc);
 // $display("PC: %d %h %h %h %h %h", $time, f_pc, d_pc, x_pc, m_pc, w_pc);
 // $display("INSN: %d %h %h %h %h %h", $time, f_insn, d_insn, x_insn, m_insn, w_insn);
 $write("f_pc: %h f_insn: %h (", f_pc, f_insn); pinstr(f_insn); $display(")");
 $write("d_pc: %h d_insn: %h (", d_pc, d_insn); pinstr(d_insn); $display(")");
 $write("x_pc: %h x_insn: %h (", x_pc, x_insn); pinstr(x_insn); $display(")");
 $write("m_pc: %h m_insn: %h (", m_pc, m_insn); pinstr(m_insn); $display(")");
 $write("w_pc: %h w_insn: %h (", w_pc, w_insn); pinstr(w_insn); $display(")");
 $display("flush: %d load_to_use: %d", is_flush, load_to_use_stall);
 // $display("%d,M_DATA is %h, M_R1 is %h, M_R2 is %h", $time, m_dmem_data, m_r1data, m_r2data);
 $display("%d,W_REG is %h, W_FROM_DATA is %h, W_TO_WRITE %h, W_ALU is %h, %b", $time, w_result, w_dmem_data, w_dmem_towrite, w_oresult, w_is_load);
 $display("");
 // --- $display("%d", $time);
 // $display("%d %h %b", $time, f_pc, f_insn);
 // $display("%d %h %b", $time, d_pc, d_insn);
 // if (o_dmem_we)
 //   $display("%d STORE %h <= %h", $time, o_dmem_addr, o_dmem_towrite);

 // Start each $display() format string with a %d argument for time
 // it will make the output easier to read.  Use %b, %h, and %d
 // for binary, hex, and decimal output of additional variables.
 // You do not need to add a \n at the end of your format string.
 // $display("%d ...", $time);

 // Try adding a $display() call that prints out the PCs of
 // each pipeline stage in hex.  Then you can easily look up the
 // instructions in the .asm files in test_data.

 // basic if syntax:
 // if (cond) begin
 //    ...;
 //    ...;
 // end

 // Set a breakpoint on the empty $display() below
 // to step through your pipeline cycle-by-cycle.
 // You'll need to rewind the simulation to start
 // stepping from the beginning.

 // You can also simulate for XXX ns, then set the
 // breakpoint to start stepping midway through the
 // testbench.  Use the $time printouts you added above (!)
 // to figure out when your problem instruction first
 // enters the fetch stage.  Rewind your simulation,
 // run it for that many nano-seconds, then set
 // the breakpoint.

 // In the objects view, you can change the values to
 // hexadecimal by selecting all signals (Ctrl-A),
 // then right-click, and select Radix->Hexadecial.

 // To see the values of wires within a module, select
 // the module in the hierarchy in the "Scopes" pane.
 // The Objects pane will update to display the wires
 // in that module.

 $display(); 
 end
 `endif
 endmodule

