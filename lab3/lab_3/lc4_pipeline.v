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

 /*** YOUR CODE HERE ***/

 wire is_stall;
 wire is_flush;
 
  assign is_stall = (x_is_load == 1) && ( (x_wsel == d_r1sel) || ( (x_wsel == d_r2sel) && !(d_is_store) ) || d_is_branch);
  assign is_flush = ( x_is_control_insn ) ? ( 1 ) : 
                     ( !((( ( m_nzp_we ) ? ( m_nzp ) : 
                       ( w_nzp_we ) ? ( w_nzp ) : curr_nzp ) && 
                       x_insn[11:9] ) == 3'b000) && x_is_branch ); 
 
 /** FETCH **/
 wire [15:0] f_pc;
 wire [15:0]f_insn;
 wire [15:0] next_pc;

// PC REG
 Nbit_reg #(16, 16'h0000) f_pc_reg (.in(next_pc), .out(f_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  

 /** RETURN! **/
 assign o_cur_pc = (is_flush) ? x_pc : f_pc + 1;

 assign f_insn = (is_stall) ? (d_insn) : 
 (is_flush) ? (16'h0000) : i_cur_insn;


 /** DECODE **/
 // From the decoder
 wire [15:0] d_pc;
 wire [15:0] d_insn;
 
 wire [2:0] r1sel;
 wire [2:0] r2sel;
 wire r1re;
 wire r2re;
 wire select_pc_plus_one;
 wire is_load;
 wire is_store;
 wire is_control_insn;
 wire is_branch;
 wire [2:0] wsel;
 wire regfile_we;
 wire nzp_we;
 
 wire [2:0] d_r1sel;
 wire [2:0] d_r2sel;
 wire d_r1re;
 wire d_r2re;
 wire d_select_pc_plus_one;
 wire d_is_load;
 wire d_is_store;
 wire d_is_control_insn;
 wire d_is_branch;
 wire [2:0] d_wsel;
 wire d_regfile_we;
 wire d_nzp_we;
 wire d_r1data;
 wire d_r2data;
 
 wire flush_stall = is_flush || is_stall; // for stall, shouldn't we repeat old insn?
 // ( is_stall) ? (x_insn_vals) : (is_flush) ? 0 : decode_val

 lc4_decoder decoder (i_cur_insn, r1sel, r1re, r2sel, r2re, wsel, regfile_we, nzp_we, select_pc_plus_one, is_load, is_store, is_branch, is_control_insn);

 Nbit_reg #(16, 16'h0000) d_pc_reg (.in(f_pc), .out(d_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  
 Nbit_reg #(16, 16'h0000) d_insn_reg (.in(f_insn), .out(d_insn), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  

 assign d_r1sel = ( flush_stall ) ? r1sel : 3'b000;
 assign d_r2sel ( flush_stall ) ? r2sel : 3'b000;
 assign d_r1re = ( flush_stall ) ? r1re : 3'b000;
 assign d_r2re = ( flush_stall ) ? r1re : 3'b000;
 assign d_select_pc_plus_one = ( flush_stall ) ? select_pc_plus_one : 3'b000;
 assign d_is_load = ( flush_stall ) ? is_load : 3'b000;
 assign d_is_store = ( flush_stall ) ? is_store : 3'b000;
 assign d_is_control_insn = ( flush_stall ) ? is_control_insn : 3'b000;
 assign d_is_branch = ( flush_stall ) ? is_branch : 3'b000;
 assign d_wsel = ( flush_stall ) ? wsel : 3'b000;
 assign d_regfile_we = ( flush_stall ) ? regfile_we : 3'b000;
 assign d_nzp_we = ( flush_stall ) ? nzp_we : 3'b000;



 /** EXECUTE **/

 wire [15:0] x_pc;
 wire [15:0] x_insn;
 wire [15:0] x_r1sel;
 wire [15:0] x_r2sel;
 wire x_r1re;
 wire x_r2re;
 wire x_select_pc_plus_one;
 wire x_is_load;
 wire x_is_store;
 wire x_is_control_insn;
 wire x_is_branch;
 wire [2:0] x_wsel;
 wire x_regfile_we;
 wire x_nzp_we;
 wire x_r1data;
 wire x_r2data;
 Nbit_reg #(1, 1'b0) x_is_load_reg (.in(d_is_load), .out(x_is_load), .clk(clk), .we(x_nzp_we), .gwe(gwe), .rst(rst));  
 Nbit_reg #(1, 1'b0) x_is_store_reg (.in(d_is_store), .out(x_is_store), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
 Nbit_reg #(1, 1'b0) x_wsel_reg (.in(d_wsel), .out(x_wsel), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
 Nbit_reg #(16, 16'h0000) x_pc_reg (.in(d_pc), .out(x_pc), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));  

 wire [15:0] o_alu;
 
 // Reg_File
 wire [15:0] o_rs_data;
 wire [15:0] o_rt_data;
 wire [15:0] i_wdata = ( x_is_load  == 1 ) ? ( i_cur_dmem_data ) :
 ( x_is_control_insn) ? ( x_pc + 1 ) :
 ( o_alu );

 // this is both write from W stage and read from X stage
 lc4_regfile regfile (clk, gwe, rst, x_r1sel, x_r1data, x_r2sel, x_r2data, w_wsel, w_oresult, w_regfile_we);


 // BYPASS:
 wire [15:0] alu_1;
 assign alu_1 = ( (x_r1sel == m_wsel) && (m_regfile_we && m_is_load) ) ? m_oresult : 
 ( (x_r1sel == w_wsel) && (w_regfile_we) ) ? w_oresult : x_r1data;

 wire [15:0] alu_2;
 assign alu_2 = ( (x_r2sel == m_wsel) && (m_regfile_we && m_is_load) ) ? m_wdata : 
 ( (x_r2sel == w_wsel) && (w_regfile_we) ) ? w_oresult : x_r2data;

 // ALU
 lc4_alu alu (x_insn, x_pc, alu_1, alu_2, o_alu);

 wire [2:0]  x_nzp;
 assign x_nzp[2] = i_wdata[15];
 assign x_nzp[1] = (i_wdata == 16'h0000);
 assign x_nzp[0] = (!i_wdata[15]) & (!x_nzp[1]);

 assign x_oresult = ( x_select_pc_plus_one ) ? x_pc + 1 : o_alu;

 /** MEMORY **/
 wire [2:0] m_r1sel;
 wire [2:0] m_r2sel;
 wire m_r1re;
 wire m_r2re;
 wire m_select_pc_plus_one;
 wire m_is_load;
 wire m_is_store;
 wire m_is_control_insn;
 wire m_is_branch;
 wire [2:0] m_wsel;
 wire m_regfile_we;
 wire m_nzp_we;
 wire m_r1data;
 wire m_nzp;
 wire m_r2data;
 wire [15:0] m_oresult;
 wire [15:0] m_data_in;
 wire [15:0] m_addr;
 wire [15:0] m_data_out;
 wire [15:0] m_wdata;
 
  assign m_nzp[2] = i_cur_dmem_data[15];
  assign m_nzp[1] = (i_cur_dmem_data == 16'h0000);
  assign m_nzp[0] = (!i_cur_dmem_data[15]) & (!m_nzp[1]);
 
 
   Nbit_reg #(3, 3'b000) mem_reg (.in(nzp_new_bits), .out(curr_nzp), .clk(clk), .we(m_nzp_we), .gwe(gwe), .rst(rst));  
   
      Nbit_reg #(1, 1'b0) m_is_load_reg (.in(x_is_load), .out(m_is_load), .clk(clk), .we(x_nzp_we), .gwe(gwe), .rst(rst));  
      Nbit_reg #(1, 1'b0) m_is_store_reg (.in(x_is_store), .out(m_is_store), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
      Nbit_reg #(1, 1'b0) m_wsel_reg (.in(x_wsel), .out(m_wsel), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
      Nbit_reg #(3, 3'b000) m_nzp_reg (.in(x_nzp), .out(m_nzp), .clk(clk), .we(x_nzp_we), .gwe(gwe), .rst(rst));    
      Nbit_reg #(16, 3'b000) m_rt_reg (.in(x_r2data), .out(m_rt_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));    
      Nbit_reg #(16, 3'b000) m_input_reg (.in(x_oresult), .out(m_wdata), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));    

   assign m_addr = x_oresult;
   assign m_data_in = ( (w_is_load && m_is_store) && (w_wsel == m_r2sel) ) ? w_oresult : 
                      m_rt_data;
   
   assign o_dmem_addr = m_addr;
   assign o_dmem_to_write = m_data_in; 
   assign o_dmem_we = m_is_store;
      
   /** WRITEBACK **/
     wire [2:0] w_r1sel;
     wire [2:0] w_r2sel;
     wire w_r1re;
     wire w_r2re;
     wire w_select_pc_plus_one;
     wire w_is_load;
     wire w_is_store;
     wire w_is_control_insn;
     wire w_is_branch;
     wire [2:0] w_wsel;
     wire w_regfile_we;
     wire w_nzp_we;
     wire w_r1data;
     wire w_r2data;
     wire w_nzp;
     wire [15:0] w_alu_data;
     wire [15:0] w_mem_data;

     wire [15:0] w_oresult;
     
     
     assign w_oresult = ( w_is_load ) ? ( w_mem_data ) : ( w_alu_data );
     
     Nbit_reg #(1, 1'b0) w_is_load_reg (.in(m_is_load), .out(w_is_load), .clk(clk), .we(x_nzp_we), .gwe(gwe), .rst(rst));  
     Nbit_reg #(1, 1'b0) w_is_store_reg (.in(m_is_store), .out(w_is_store), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
     Nbit_reg #(1, 1'b0) w_wsel_reg (.in(m_wsel), .out(w_wsel), .clk(clk), .we(d_nzp_we), .gwe(gwe), .rst(rst));  
     Nbit_reg #(3, 3'b000) w_nzp_reg (.in(m_nzp), .out(w_nzp), .clk(clk), .we(m_nzp_we), .gwe(gwe), .rst(rst));    

     Nbit_reg #(3, 3'b000) write_reg (.in(nzp_new_bits), .out(curr_nzp), .clk(clk), .we(w_nzp_we), .gwe(gwe), .rst(rst));  
  
     Nbit_reg #(3, 3'b000) nzp_reg (.in(w_nzp), .out(curr_nzp), .clk(clk), .we(w_nzp_we), .gwe(gwe), .rst(rst));    
   
     Nbit_reg #(16, 4'h0000) w_alu_reg (.in(m_rt_data), .out(w_alu_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));    
     Nbit_reg #(16, 4'h0000) w_mem_reg (.in(m_data_out), .out(w_mem_data), .clk(clk), .we(1'b1), .gwe(gwe), .rst(rst));    

    
   /*
    assign o_dmem_towrite = //( is_load ) ? o_dmem_towrite :
                            ( m_is_store ) ? o_rt_data  :              
                            16'h0000;  // 0 if no load / store??? CHECK THIS
    assign o_dmem_addr = ( w_is_load | w_is_store ) ? o_alu : 16'h0000;
    assign o_dmem_we = w_is_store;
       */
            
    wire [2:0]  nzp_new_bits;
    assign nzp_new_bits[2] = i_wdata[15];
    assign nzp_new_bits[1] = (i_wdata == 16'h0000);
    assign nzp_new_bits[0] = (!i_wdata[15]) & (!nzp_new_bits[1]);
    
    // BRANCH LOGIC
    wire [2:0] curr_nzp; // TODO: change this
    wire o_branch = !( ( i_cur_insn[11:9] & curr_nzp ) == 3'b000);
        
    // PC_MUX
    assign next_pc = 16'h0000;//( (is_control_insn) ? 1 : (o_branch && is_branch) ) ? o_alu : pc + 1;
    //assign o_cur_pc = pc;
   
   
 
   
       // Set test wires to correct outputs
    assign  test_stall = is_stall;                                             // Testbench: is this a stall cycle? (don't compare the test values)
    assign  test_cur_pc = f_pc;                                               // Testbench: program counter
    assign  test_cur_insn = i_cur_insn;                                     // Testbench: instruction bits
    assign  test_regfile_we = w_regfile_we;                                   // Testbench: register file write enable
    assign  test_regfile_wsel = w_wsel;                                       // Testbench: which register to write in the register file 
    assign  test_regfile_data = 16'h0000;                                    // Testbench: value to write into the register file
    assign  test_nzp_we = w_nzp_we;                                           // Testbench: NZP condition codes write enable

    assign  test_nzp_new_bits[2] = w_nzp[2];                         // Testbench: value to write to NZP bits (Needs to be computed)
    assign  test_nzp_new_bits[1] = w_nzp[1];
    assign  test_nzp_new_bits[0] = w_nzp[0];                         // wrong in our schematic
    
    assign  test_dmem_we = o_dmem_we;                                       // Testbench: data memory write enable
    assign  test_dmem_addr = o_dmem_addr;                                   // Testbench: address to read/write memory
    assign  test_dmem_data = 16'h0000;  // Testbench: value read/writen from/to memory
   
   
   

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
      // $display("%d %h %b", $time, test_cur_pc, test_cur_insn);
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
