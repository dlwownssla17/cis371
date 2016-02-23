@echo off
set xv_path=C:\\Users\\Hannes\\Documents\\Vivado\\2015.4\\bin
call %xv_path%/xelab  -wto 420eb0f6520b452394b3fec2c2426dec -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot testbench_v_behav xil_defaultlib.testbench_v xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
