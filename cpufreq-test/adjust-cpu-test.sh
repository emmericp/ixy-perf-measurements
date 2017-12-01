#!/bin/bash
# run this script while moongen is running with l2-load-latency.lua at full load on both ports
# adjust PCIe addresses below.
# CAUTION: USING THE PCIE ADDRESSES WILL CRASH YOUR SYSTEM

kill $(pidof ixy-fwd)

for i in $(cat supported-cpu-freqs.txt); do
	./cpu-perf.sh $i
	taskset -c 1 /root/ixy/ixy-fwd 0000:XX:YY.Z 0000:XX:YY.Z > ixy-output-cpu-$i.txt &
	sleep 30
	kill $(pidof ixy-fwd)
	sleep 1
done
