#ifndef CLICK_ETHERLATENCY_HH
#define CLICK_ETHERLATENCY_HH
#include <click/batchelement.hh>
#include <clicknet/ether.h>
CLICK_DECLS

/*
=c

EtherLatency()

=s ethernet

compute average latency based on the value written in the last 32bits of the Ethernet src address.

=item N
Size of the reservoir. Defaults to 0.

=item SAMPLE
How often the latency should be recorded.
*/
class EtherLatency : public BatchElement { public:

    EtherLatency() CLICK_COLD;
    ~EtherLatency() CLICK_COLD;

    const char *class_name() const override	{ return "EtherLatency"; }
    const char *port_count() const override	{ return PORTS_1_1; }

    int configure(Vector<String> &, ErrorHandler *) CLICK_COLD;
    bool can_live_reconfigure() const	{ return true; }

    static String read_handler(Element *, void *);
    void add_handlers() CLICK_COLD;

    inline int smaction(Packet *);
    void push(int, Packet *) override;

#if HAVE_BATCH
    void push_batch(int, PacketBatch *) override;
#endif

    bool should_aggregate();

  private:
    uint32_t _limit;
    uint64_t _sample;

    Vector<double> _latencies;
    uint64_t _packet_counter;
    atomic_uint32_t _curr_idx;

    double percentile(const double);
    double mean();
};

CLICK_ENDDECLS
#endif
