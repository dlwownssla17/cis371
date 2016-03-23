# 
# Synthesis run script generated by Vivado
# 

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7z020clg484-1

set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/Hannes/lab2/lab3/lab_3/lab3.cache/wt [current_project]
set_property parent.project_path C:/Users/Hannes/lab2/lab3/lab_3/lab3.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property vhdl_version vhdl_2k [current_fileset]
read_verilog C:/Users/Hannes/lab2/lab3/lab_3/set_testcase.v
set_property file_type "Verilog Header" [get_files C:/Users/Hannes/lab2/lab3/lab_3/set_testcase.v]
read_verilog -library xil_defaultlib {
  C:/Users/Hannes/lab2/lab3/lab_3/lc4_divider.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/register.v
  C:/Users/Hannes/lab2/lab3/lab_3/lc4_regfile.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/lc4_decoder.v
  C:/Users/Hannes/lab2/lab3/lab_3/lc4_alu.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/bram.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/delay_eight_cycles.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/svga_timing_generation.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/video_out.v
  C:/Users/Hannes/lab2/lab3/lab_3/lc4_pipeline.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/lc4_memory.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/fake_pb_kbd.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/one_pulse.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/clock_util.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/clkdiv.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/timer.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/clkgen.v
  C:/Users/Hannes/lab2/lab3/lab_3/include/vga_controller.v
  C:/Users/Hannes/lab2/lab3/lab_3/lc4_system.v
}
synth_design -top lc4_system -part xc7z020clg484-1
write_checkpoint -noxdef lc4_system.dcp
catch { report_utilization -file lc4_system_utilization_synth.rpt -pb lc4_system_utilization_synth.pb }
