#ifndef CLICK_FLOWORDERING_HH
#define CLICK_FLOWORDERING_HH
#include <click/batchelement.hh>
extern "C" {
    #include <cuckoopp/rte_hash_bloom.h>
}
CLICK_DECLS

/*
=c

FlowOrdering()

=s flow

Check flow ordering based on the monotonically packet number assigned to each packet.

=item OFFSET

Offset where packet number is written. Default to 40.

=item SAMPLE

How often the flow should be recorded to check ordering.

=item CAPACITY

Size of the cuckoo that holds the packet numbers.
*/
class FlowOrdering : public BatchElement { public:

    FlowOrdering() CLICK_COLD;
    ~FlowOrdering() CLICK_COLD;

    const char *class_name() const override	{ return "FlowOrdering"; }
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

    uint64_t wrong_order;

  private:
    uint32_t _offset;
    bool _net_order;
    uint64_t _sample;
    std::size_t _capacity;

    rte_hash_hvariant *_table;
    uint64_t _flow_counter;
    
    uint64_t _read_number_of_packet(Packet *);

};

CLICK_ENDDECLS
#endif
