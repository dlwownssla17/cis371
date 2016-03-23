@echo off
set xv_path=C:\\Users\\Hannes\\Documents\\Vivado\\2015.4\\bin
call %xv_path%/xelab  -wto 5fb18c868f1240bba1d47e12f6b14e9d -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot lc4_system_behav xil_defaultlib.lc4_system xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
