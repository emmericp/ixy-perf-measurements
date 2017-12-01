#!/bin/bash
echo "usage: $0 <folder containing .txt output files>"
for file in $1/*.txt
do
	echo $file
	# we sometimes get truncated lines when stopping, so filter for Mpps
	grep " TX: " $file | grep Mpps |  awk '{ sum += $5; stddev += $5^2 } END {print "Average: " 2* sum/NR; print "StdDev: " 2 * sqrt(stddev/NR - (sum/NR)^2) }'
	echo " "
done

