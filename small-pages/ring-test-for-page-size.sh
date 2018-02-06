#!/bin/bash
# USE THE CORRECT PCIE ADDRESSES OR THIS WILL CRASH YOUR SYSTEM

# run this script with both the huge page version of ixy and the normal one. compare results.

kill $(pidof ixy-fwd)

# fixme: cleanup

cd /home/paul/ixy-git
for i in 64 128 256 512 1024 2048 4096
do
	echo "Running test for ring size $i"
	sed -i "s/NUM_RX_QUEUE_ENTRIES =.*/NUM_RX_QUEUE_ENTRIES = $i;/g" src/driver/ixgbe.c
	sed -i "s/NUM_TX_QUEUE_ENTRIES =.*/NUM_TX_QUEUE_ENTRIES = $i;/g" src/driver/ixgbe.c
	make
	# adjust PCIe address here
	taskset -c 1 ./ixy-fwd 0000:03:00.1 0000:05:00.1 > ./ixy-output-ring-$i-$i.txt &
	sleep 15 # x540 takes some time to establish link after reset
	perf stat -e dTLB-loads,dTLB-load-misses,dTLB-stores,dTLB-store-misses --pid $(pidof ixy-fwd) -o ./ixy-perf-stat-ring-$i-$i.txt sleep 40 & 
	sleep 60
	kill $(pidof ixy-fwd)
	sleep 3
done

