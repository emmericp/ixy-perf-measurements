#!/bin/bash
# USE THE CORRECT PCIE ADDRESSES OR THIS WILL CRASH YOUR SYSTEM

kill $(pidof ixy-fwd)

cd /root/ixy
for i in 1 2 4 8 16 32 64 128 256
do
	sed -i "s/BATCH_SIZE =.*/BATCH_SIZE = $i;/g" src/app/ixy-fwd.c
	make
	# adjust PCIe address here
	taskset -c 1 ./ixy-fwd 0000:XX:YY.Z 0000:XX:YY.Z > ./ixy-output-batch-$i.txt &
	sleep 60
	kill $(pidof ixy-fwd)
done

