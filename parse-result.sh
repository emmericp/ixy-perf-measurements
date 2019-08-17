#!/bin/bash
echo "usage: $0 <folder containing .txt output files>"

# Evaluate profiling results? 
PERF_STAT=1
# Specify file to gather profiling results
PERF_RESULTS="/path/ro/results"
THROUGHPUTS=""
L1DCACHELOADS=""
L1DCACHEMISSES=""
LLCLOADS=""
LLCLOADMISSES=""

rm $PERF_RESULTS 
touch $PERF_RESULTS


for file in $1/*.txt
do
	echo $file
	# we sometimes get truncated lines when stopping, so filter for Mpps
	grep " TX: " $file | grep Mpps |  awk 'NR > 30 {sum += $5; stddev += $5^2 } END {print "Average: " 2* sum/(NR-30); print "StdDev: " 2 * sqrt(stddev/NR - (sum/NR)^2) }'
	THROUGHPUT=$(grep " TX: " $file | grep Mpps |  awk 'NR > 30 {sum += $5;} END {print 2* sum/(NR-30);}')	
	
	if [[ $THROUGHPUT != -nan ]]; then
		THROUGHPUTS="$THROUGHPUTS"", $THROUGHPUT"
		echo "THROUGHPUT:"
        	echo "$THROUGHPUT"
	fi
	echo " "
	if [[ $PERF_STAT == 1 ]] ; then 
		TMP_CYCLES=$(grep cycles -m 1 $file | awk '{ print $1;}')
		TMP_INSTRUCTIONS=$(grep instructions -m 1 $file | awk '{ print $1;}')
		TMP_BRANCHES=$(grep branches -m 1 $file | awk '{ print $1;}')
		TMP_BRANCHMISSES=$(grep branch-misses -m 1 $file | awk '{ print $1;}')
		TMP_L1DCACHELOADS=$(grep L1-dcache-loads -m 1 $file | awk '{ print $1;}')
		TMP_L1DCACHEMISSES=$(grep L1-dcache-load-misses -m 1 $file | awk '{ print $1;}')
		TMP_LLCLOADS=$(grep LLC-loads -m 1 $file | awk '{ print $1;}')
		TMP_LLCLOADMISSES=$(grep LLC-load-misses -m 1 $file | awk '{ print $1;}')
		
		L1DCACHELOADS="$L1DCACHELOADS"", $TMP_L1DCACHELOADS" 
		L1DCACHEMISSES="$L1DCACHEMISSES"", $TMP_L1DCACHEMISSES" 
		LLCLOADS="$LLCLOADS"", $TMP_LLCLOADS" 
		LLCLOADMISSES="$LLCLOADMISSES"", $TMP_LLCLOADMISSES" 
	fi
	done
echo "######################"

echo "THROUGHPUTS:"
echo "$THROUGHPUTS"

echo "######################"
echo "L1DCACHELOADS:"
echo "$L1DCACHELOADS"

echo "######################"
echo "L1DCACHEMISSES:"
echo "$L1DCACHEMISSES"

echo "######################"
echo "LLCLOADS:"
echo "$LLCLOADS"

echo "######################"
echo "LLCLOADMISSES:"
echo "$LLCLOADMISSES"

echo "######################"

		#echo "Perf stat profiling results (cycles, instr, branches, branch misses, L1 dcache loads, l1 dcache misses, llc loads, llc load misses, llc hits):" 

