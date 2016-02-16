#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2015.4"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xsim testbench_v_behav -key {Behavioral:sim_1:Functional:testbench_v} -tclbatch testbench_v.tcl -log simulate.log
