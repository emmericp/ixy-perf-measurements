#!/bin/bash
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
echo $1 > /sys/devices/system/cpu/intel_pstate/min_perf_pct
echo $1 > /sys/devices/system/cpu/intel_pstate/max_perf_pct

echo -n "Set CPU freq to (% of spec rate): "
cat /sys/devices/system/cpu/intel_pstate/max_perf_pct
echo "Caution: CPUs usually only implement a few discrete steps."
echo "Use perf stat --pid \$(pidof ixy-fwd) to check the cycle counter to get the actual frequency."
