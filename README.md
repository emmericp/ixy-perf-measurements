Work in Progress: Full paper
============================
The repository does not yet contain all scripts used for the full paper and this README is only partially updated for the new test setups.


Scripts used for the ixy paper
==============================
This repository contains all scripts used for the performance evaluation of ixy in the paper.


System Setup
------------
* Debian Stretch, Kernel 4.9
* ixy commit XXXXX checked out in /root/ixy
* Source code also included here in `ixy` TODO: UPDATE SOURCE
* Compile ixy following `ixy/README.md`

Used Hardware/Packet Generator
----------------------------------
* Multiple NICs of the Intel ixgbe family: X520 and X540
* Intel Xeon E5-2630 and E5-2620
* NICs directly connected to a server running MoonGen
* MoonGen commit 31af6e6 was used
* MoonGen command line: `./build/MoonGen examples/l2-load-latency.lua 0 1`, adjust port IDs


Batch Test
----------
* Adjust PCIe addresses (use lspci) in `batch-test/batch-test.sh` and run it
* Script will patch ixy-fwd and run it for batch sizes hardcoded in the script
* Leave MoonGen on the second server running the whole time

CPU Freq Test
------------
* Adjust PCIe addresses in `cpufreq-test/adjust-cpu-test`
* Adjust supported CPU frequencies in `cpufreq-test/supported-cpu-freqs.txt`, the file contains percentages of the specification rate
* CPUs only support a few discrete steps. You can use `perf stat --pid $(pidof ixy-fwd)` while ixy is running to get the frequency that the CPU is currently actually running at (cycle counter, this works because of busy waiting).
* Run the script while MoonGen is running on the second server, caution, reset the git repository if ixy-fwd was patched by `batch-test.sh` before

Perf Profiling
--------------
* Run ixy manually with the desired CPU speed/batching
* Run `perf record --pid $(pidof ixy-fwd)`, analyze results with `perf report`
* Apply `ixy-inline-mem.patch` for the evaluation with inline memory allocation

parse-results.sh
---------------
* Use `parse-result.sh` to calculate the average speed and stddev from ixy's output, script expects a folder name containing .txt files with ixy output
* Ixy outputs statistics from the NICs statistics registers
* Also compare the throughput reported by ixy with the throughput reported by MoonGen to not completely rely on the device under test!


Included Results
----------------
Included output files were used for the figures in the paper.

