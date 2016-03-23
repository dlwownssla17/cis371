@echo off
set xv_path=C:\\Users\\Hannes\\Documents\\Vivado\\2015.4\\bin
call %xv_path%/xsim lc4_system_behav -key {Behavioral:sim_1:Functional:lc4_system} -tclbatch lc4_system.tcl -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
