
* Make sure to check out the DPDK submodule or clone DPDK at tag 17.11 somewhere
* Compile and install DPDK
```
make config T=x86_64-native-linuxapp-gcc 
make
```

* Bind DPDK drivers and setup system, see [DPDK documentation](http://dpdk.org/doc/guides/linux_gsg/quick_start.html)
* Setup DPDK build environment variables
```
export RTE_TARGET=x86_64-native-linuxapp-gcc
export RTE_SDK=/path/to/dpdk/dir
```

* Build it
```
make
```

* Run it, adjust PCIe addresses
```
./build/l2fwd --pci-whitelist 03:00.0 --pci-whitelist 03:00.1 -- 1 0
```

Note that this forwarder, unlike ixy-fwd, does not print statistics. No output means everything's up and running.


