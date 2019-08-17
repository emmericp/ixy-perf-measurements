// stripped down DPDK l2fwd example. bidirectional single-core forwarding only
// all the includes. just copy & paste from dpdk l2fwd
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <inttypes.h>
#include <sys/types.h>
#include <sys/queue.h>
#include <netinet/in.h>
#include <setjmp.h>
#include <stdarg.h>
#include <ctype.h>
#include <errno.h>
#include <getopt.h>
#include <signal.h>
#include <stdbool.h>

#include <rte_common.h>
#include <rte_log.h>
#include <rte_malloc.h>
#include <rte_memory.h>
#include <rte_memcpy.h>
#include <rte_eal.h>
#include <rte_launch.h>
#include <rte_atomic.h>
#include <rte_cycles.h>
#include <rte_prefetch.h>
#include <rte_lcore.h>
#include <rte_per_lcore.h>
#include <rte_branch_prediction.h>
#include <rte_interrupts.h>
#include <rte_random.h>
#include <rte_debug.h>
#include <rte_ether.h>
#include <rte_ethdev.h>
#include <rte_mempool.h>
#include <rte_mbuf.h>


#define RTE_LOGTYPE_L2FWD RTE_LOGTYPE_USER1

#define BATCH_SIZE 32

#define RTE_TEST_RX_DESC_DEFAULT 512
#define RTE_TEST_TX_DESC_DEFAULT 512

static uint16_t nb_rxd = RTE_TEST_RX_DESC_DEFAULT;
static uint16_t nb_txd = RTE_TEST_TX_DESC_DEFAULT;


static struct rte_eth_conf port_conf = {
	.rxmode = {
		.split_hdr_size = 0,
		.ignore_offload_bitfield = 1,
		.offloads = DEV_RX_OFFLOAD_CRC_STRIP,
	},
	.txmode = {
		.mq_mode = ETH_MQ_TX_NONE,
	},
};


// basically ixy_init for DPDK. it's horrible.
static void dpdk_dev_init(int portid) {
	// copy & paste from dpdk-l2fwd
	struct rte_eth_rxconf rxq_conf;
	struct rte_eth_txconf txq_conf;
	struct rte_eth_conf local_port_conf = port_conf;
	struct rte_eth_dev_info dev_info;
	/* init port */
	printf("Initializing port %u...\n", portid);
	rte_eth_dev_info_get(portid, &dev_info);
	if (dev_info.tx_offload_capa & DEV_TX_OFFLOAD_MBUF_FAST_FREE)
		local_port_conf.txmode.offloads |=
			DEV_TX_OFFLOAD_MBUF_FAST_FREE;
	int ret = rte_eth_dev_configure(portid, 1, 1, &local_port_conf);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "Cannot configure device: err=%d, port=%u\n",
			  ret, portid);

	ret = rte_eth_dev_adjust_nb_rx_tx_desc(portid, &nb_rxd,
					       &nb_txd);
	if (ret < 0)
		rte_exit(EXIT_FAILURE,
			 "Cannot adjust number of descriptors: err=%d, port=%u\n",
			 ret, portid);


	/* init one RX queue */
	rxq_conf = dev_info.default_rxconf;
	rxq_conf.offloads = local_port_conf.rxmode.offloads;
	char buf[20];
	sprintf(buf, "pool%d", portid); // mempool names must be unique. stupid dpdk.
	struct rte_mempool* pool = rte_pktmbuf_pool_create(buf, 8191, 256, 0, 2048, rte_socket_id());
	ret = rte_eth_rx_queue_setup(portid, 0, nb_rxd,
				     rte_eth_dev_socket_id(portid),
				     &rxq_conf,
				     pool);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "rte_eth_rx_queue_setup:err=%d, port=%u\n",
			  ret, portid);

	/* init one TX queue on each port */
	fflush(stdout);
	txq_conf = dev_info.default_txconf;
	txq_conf.txq_flags = ETH_TXQ_FLAGS_IGNORE;
	txq_conf.offloads = local_port_conf.txmode.offloads;
	ret = rte_eth_tx_queue_setup(portid, 0, nb_txd,
			rte_eth_dev_socket_id(portid),
			&txq_conf);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "rte_eth_tx_queue_setup:err=%d, port=%u\n",
			ret, portid);

	/* Start device */
	ret = rte_eth_dev_start(portid);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "rte_eth_dev_start:err=%d, port=%u\n",
			  ret, portid);

	rte_eth_promiscuous_enable(portid);

}

// stats stuff, copied from ixy stats.c
// returns a timestamp in nanoseconds
struct device_stats {
	int device;
    size_t rx_pkts;
    size_t tx_pkts;
    size_t rx_bytes;
    size_t tx_bytes;
};


static double diff_mpps(uint64_t pkts_new, uint64_t pkts_old, uint64_t nanos) {
    return (double) (pkts_new - pkts_old) / 1000000.0 / ((double) nanos / 1000000000.0);
}

// too hard to get the real hardware counters from DPDK for packets, so no byte counters here
// stuff reported in rte_eth_stats is unfortunately completely inconsistent: packet counters count dropped packets, byte counters only count some of them
// it's of course completely different between different drivers. stuff like this is the reason why we re-implement these parts in libmoon/MoonGen
static void print_stats_diff(int device, struct rte_eth_stats* stats_new, struct rte_eth_stats* stats_old, uint64_t nanos) {
    printf("[%d] RX: %d Mbit/s %.2f Mpps\n", device,
		-1,
        diff_mpps(stats_new->ipackets + stats_new->imissed + stats_new->rx_nombuf, stats_old->ipackets + stats_old->imissed + stats_old->rx_nombuf, nanos)
    );
    printf("[%d] TX: %d Mbit/s %.2f Mpps\n", device,
		-1,
        diff_mpps(stats_new->opackets, stats_old->opackets, nanos)
    );
}


// based on rdtsc on reasonably configured systems and is hence fast
static uint64_t monotonic_time(void) {
	struct timespec timespec;
	clock_gettime(CLOCK_MONOTONIC, &timespec);
	return timespec.tv_sec * 1000 * 1000 * 1000 + timespec.tv_nsec;
}



static void forward(uint32_t rx_dev, uint16_t rx_queue, uint32_t tx_dev, uint16_t tx_queue) {
    struct rte_mbuf* bufs[BATCH_SIZE];
	int num_rx = rte_eth_rx_burst(rx_dev, rx_queue, bufs, BATCH_SIZE);
    if (num_rx > 0) {
		// touch packet to be somewhat realistic
        for (int i = 0; i < num_rx; i++) {
			uint8_t* data = rte_pktmbuf_mtod(bufs[i], uint8_t*);
			data[1]++;
		}
        int num_tx = rte_eth_tx_burst(tx_dev, tx_queue, bufs, num_rx);
        // there are two ways to handle the case that packets are not being sent out:
        // either wait on tx or drop them; in this case it's better to drop them, otherwise we accumulate latency
        for (int i = num_tx; i < num_rx; i++) {
            rte_pktmbuf_free(bufs[i]);
        }
    }
}



int main(int argc, char **argv) {
	// init DPDK
	int ret = rte_eal_init(argc, argv);
	if (ret < 0)
		rte_exit(EXIT_FAILURE, "Invalid EAL arguments\n");
	argc -= ret;
	argv += ret;

	// the rest is basically copy & paste from ixy-fwd with DPDK function calls

    if (argc != 3) {
        printf("%s forwards packets between two ports.\n", argv[0]);
        printf("Usage: %s <dpdk port 0> <dpdk port 1>\n", argv[0]);
        return 1;
    }

	uint32_t dev1 = atoi(argv[1]);
	uint32_t dev2 = atoi(argv[2]);

    dpdk_dev_init(dev1);
    dpdk_dev_init(dev2);

    uint64_t last_stats_printed = monotonic_time();
	uint32_t counter = 0;
    struct rte_eth_stats stats1 = {0};
    struct rte_eth_stats stats1_old = {0};
    struct rte_eth_stats stats2 = {0};
    struct rte_eth_stats stats2_old = {0};

	// main loop copy & paste from ixy-fwd for a fair comparison
    while (true) {
		forward(dev1, 0, dev2, 0);
		forward(dev2, 0, dev1, 0);
        if ((counter++ & 0xFFF) == 0) {
            uint64_t time = monotonic_time();
            if (time - last_stats_printed > 1000 * 1000 * 1000) {
                // every second
				rte_eth_stats_get(dev1, &stats1);
                print_stats_diff(dev1, &stats1, &stats1_old, time - last_stats_printed);
                stats1_old = stats1;
				rte_eth_stats_get(dev2, &stats2);
                print_stats_diff(dev2, &stats2, &stats2_old, time - last_stats_printed);
                stats2_old = stats2;
                last_stats_printed = time;
            }
        }
    }

}

