#!/bin/bash

# ADJUST PCIE ADDRESSES OR THIS WILL CRASH YOUR SYSTEM
export PCIE_IN="XXXX:XX:XX.X"
export PCIE_OUT="YYYY:YY:YY.Y"

# specify directories for ixy and measurement results
export IXY_DIR="/path/to/ixy"
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

cd $IXY_DIR

# Specify CPU frequencies for your measurement (in %)
# Consider that available frequencies depend on your hardware
for CPU in 49 100 
do
	echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
	echo $CPU > /sys/devices/system/cpu/intel_pstate/min_perf_pct 
	echo $CPU > /sys/devices/system/cpu/intel_pstate/max_perf_pct
	echo -n "Set CPU freq to (% of spec rate):" 
	cat /sys/devices/system/cpu/intel_pstate/max_perf_pct

	kill $(pidof ixy-fwd)
	
	# Specify considered batch sizes (Default is 32)	
	for BATCH in 1 2 4 8 16 32 64 128 256
	do
		sed -i "s/BATCH_SIZE =.*/BATCH_SIZE = $BATCH;/g" src/app/ixy-fwd.c
		make
		taskset -c 1 ./ixy-fwd $PCIE_IN $PCIE_OUT > "$RESULTS_DIR/ixy-cpu_$CPU-batch_$BATCH.txt" & 
		
		if [[ $PERF_STAT == 1 ]] ; then
			sleep 5
			perf stat -d --pid $(pidof ixy-fwd) -x" " -o "$RESULTS_DIR/perf-stat-cpu_$CPU-batch_$BATCH.txt"  &
		fi
		
		sleep 60
		
		if [[ $PERF_STAT == 1 ]] ; then
			kill -s 2 $(pidof perf_4.9)
			sleep 1
		fi

		kill $(pidof ixy-fwd)
	done
done

# Reset ixy 
sed -i "s/BATCH_SIZE =.*/BATCH_SIZE = 32;/g" src/app/ixy-fwd.c
make

