@echo off
set xv_path=C:\\Users\\Hannes\\Documents\\Vivado\\2015.4\\bin
call %xv_path%/xsim testbench_v_behav -key {Behavioral:sim_1:Functional:testbench_v} -tclbatch testbench_v.tcl -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
