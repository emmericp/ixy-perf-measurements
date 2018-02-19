#!/bin/bash

# ADJUST PCIE IDs (IDs NOT addresses )
export PCIE_IN="X"
export PCIE_OUT="Y"

# specify directories for ixy and measurement results
export L2FWD_DIR="/path/to/ixy"
export RESULTS_DIR="path/to/resultdir"

if [[ -d $RESULTS_DIR ]] ; then 
	echo "Result directory: $RESULTS_DIR"
else
	mkdir "$RESULTS_DIR"
	echo "Result directory: $RESULTS_DIR"
fi	

if [[ $1 == "--perf-stat" ]] ; then
	echo "enabling perf stat"
	PERF_STAT=1
else
	echo "run with --perf-stat to enble perf stat"
fi

cd $L2FWD_DIR

# Specify CPU frequencies for your measurement (in %)
# Consider that available frequencies depend on your hardware
for CPU in 49 55 64 70 79 85 94 100 
do
	echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
	echo $CPU > /sys/devices/system/cpu/intel_pstate/min_perf_pct 
	echo $CPU > /sys/devices/system/cpu/intel_pstate/max_perf_pct
	echo -n "Set CPU freq to (% of spec rate):" 
	cat /sys/devices/system/cpu/intel_pstate/max_perf_pct

	kill $(pidof ./build/l2fwd)
    export RTE_TARGET=build
	export RTE_SDK=/home/bauersi/dpdk_fwd/dpdk-fwd/dpdk
	make
	sleep 3
	taskset -c 1 ./build/l2fwd 2 3 > "$RESULTS_DIR/dpdk-cpu_$CPU.txt" & 
		
	if [[ $PERF_STAT == 1 ]] ; then
		sleep 5
		perf stat -d --pid $(./build/l2fwd) -o "$RESULTS_DIR/perf-stat-cpu_$CPU.txt"  &
	fi
		
	sleep 60
		
	if [[ $PERF_STAT == 1 ]] ; then
		kill -s 2 $(pidof perf_4.9)
		sleep 1
	fi

	kill $(pidof ./build/l2fwd)
done
