/*
 * FlowOrdering.{cc,hh} -- check flow ordering based on the monotonically packet number assigned to each packet.
 * Mariano Scazzariello
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, subject to the conditions
 * listed in the Click LICENSE file. These conditions include: you must
 * preserve this copyright notice, and you cannot mention the copyright
 * holders in advertising related to the Software without their permission.
 * The Software is provided WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED. This
 * notice is a summary of the Click LICENSE file; the license in that file is
 * legally binding.
 */

#include <click/config.h>
#include "flowordering.hh"
#include <clicknet/ip.h>
#include <clicknet/udp.h>
#include <clicknet/tcp.h>
#include <click/args.hh>
#include <click/error.hh>
#include <click/glue.hh>

CLICK_DECLS

FlowOrdering::FlowOrdering() : _offset(40), _net_order(false), wrong_order(0), _flow_counter(0)
{
}

FlowOrdering::~FlowOrdering() 
{
}

int FlowOrdering::configure(Vector<String> &conf, ErrorHandler *errh) 
{
    if (Args(conf, this, errh)
        .read("OFFSET", _offset)
        .read("NET_ORDER", _net_order)
        .read_or_set("SAMPLE", _sample, 1)
        .read_or_set("CAPACITY", _capacity, 65535)
        .complete() < 0)
        return -1;

    struct rte_hash_hvariant_parameters hash_params = {0};
    hash_params.entries = _capacity;
    _table = rte_hash_bloom_create(&hash_params);
    if (unlikely(_table == nullptr)) {
	    click_chatter("Could not init table!");
	    return -1;
    }

    return 0;
}

inline int FlowOrdering::smaction(Packet *p)
{
    auto iph = reinterpret_cast<const click_ip *>(p->data());

    uint16_t src_port = 0;
    uint16_t dst_port = 0;
    if (iph->ip_p == IP_PROTO_UDP) {
        auto udph = reinterpret_cast<const click_udp *>(p->data() + 20);
        src_port = udph->uh_sport;
        dst_port = udph->uh_dport;
    } else if (iph->ip_p == IP_PROTO_TCP) {
        auto tcph = reinterpret_cast<const click_tcp *>(p->data() + 20);
        src_port = tcph->th_sport;
        dst_port = tcph->th_dport;
    } else {
        return 0;
    }

    hash_key_t key = {0};
    key.a = ((uint64_t) iph->ip_src.s_addr << 32) | ((uint64_t) iph->ip_dst.s_addr);
    key.b = ((uint64_t) iph->ip_p << 32) | ((uint64_t) src_port << 16) | ((uint64_t) dst_port);

    hash_data_t data = {0};
    int ret = rte_hash_bloom_lookup_data(_table, key, &data, 0);
    if (ret >= 0) {
        uint64_t pkt_num = this->_read_number_of_packet(p);

        if (pkt_num < data.a) {
            wrong_order++;
        }

        data.a = pkt_num;
        rte_hash_bloom_lookup_update_data(_table, key, &data, 0, 0);
    } else {
        _flow_counter++;

        if (_sample != 1) {
            if (((_flow_counter - 1) % _sample) != 0) {
                return 0;
            }
        }

        hash_data_t new_data = {0};
        new_data.a = this->_read_number_of_packet(p);
        rte_hash_bloom_add_key_data(_table, key, new_data, 0, 0);
    }   
        
    return 0;
}

inline void FlowOrdering::push(int, Packet *p)
{
    int o = smaction(p);
    checked_output_push(o, p);
}

#if HAVE_BATCH
void FlowOrdering::push_batch(int, PacketBatch *batch)
{
    CLASSIFY_EACH_PACKET(2, smaction, batch, checked_output_push_batch);
}
#endif

enum {
    EL_COUNT_HANDLER
};

String FlowOrdering::read_handler(Element *e, void *thunk)
{
    FlowOrdering *emt = static_cast<FlowOrdering *>(e);

    switch ((uintptr_t) thunk) {
        case EL_COUNT_HANDLER: {
            return String(emt->wrong_order);
        }

        default:
	        return String("<error>");
    }
}

void FlowOrdering::add_handlers()
{
    add_read_handler("count", read_handler, EL_COUNT_HANDLER);
}

uint64_t FlowOrdering::_read_number_of_packet(Packet *p)
{
    if (this->_net_order) {
        return htonll(*(reinterpret_cast<const uint64_t *>(p->data() + this->_offset)));
    }

    return *(reinterpret_cast<const uint64_t *>(p->data() + this->_offset));
}

CLICK_ENDDECLS
EXPORT_ELEMENT(FlowOrdering)
