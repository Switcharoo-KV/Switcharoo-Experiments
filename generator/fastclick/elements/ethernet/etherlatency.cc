/*
 * EtherLatency.{cc,hh} -- computes latency from Ethernet header
 * Mariano Scazzariello & Tommaso Caiazzi
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
#include "etherlatency.hh"
#include <click/etheraddress.hh>
#include <click/args.hh>
#include <click/error.hh>
#include <click/glue.hh>

#include <algorithm>

CLICK_DECLS

EtherLatency::EtherLatency() : 
    _latencies()
{
    _packet_counter = 0;
    _curr_idx = 0;
}

EtherLatency::~EtherLatency()
{
}

int EtherLatency::configure(Vector<String> &conf, ErrorHandler *errh)
{
    if (Args(conf, this, errh)
            .read("N", _limit)
            .read_or_set("SAMPLE", _sample, 1)
            .complete() < 0)
        return -1;

    if (_limit) {
        _latencies.resize(_limit, 0);
    }

    return 0;
}

inline int EtherLatency::smaction(Packet *p)
{
    _packet_counter++;

    if (_sample != 1) {
        if (((_packet_counter - 1) % _sample) != 0) {
            return 0;
        }
    }

    auto etherPkt = p->mac_header();
    etherPkt += 8;

    uint32_t latencyVal;
    memcpy(&latencyVal, etherPkt, sizeof(uint32_t));
    latencyVal = ntohl(latencyVal);

    uint32_t _idx = _curr_idx.fetch_and_add(1);
    _latencies[_idx] = static_cast<double>(latencyVal) / 1000.0;

    return 0;
}

inline void EtherLatency::push(int, Packet *p)
{
    int o = smaction(p);
    checked_output_push(o, p);
}

#if HAVE_BATCH
void EtherLatency::push_batch(int, PacketBatch *batch)
{
    CLASSIFY_EACH_PACKET(2, smaction, batch, checked_output_push_batch);
}
#endif

enum {
    EL_AVG_HANDLER,
    EL_MED_HANDLER,
    EL_PERC_90_HANDLER,
    EL_PERC_95_HANDLER,
    EL_PERC_99_HANDLER
};

String EtherLatency::read_handler(Element *e, void *thunk)
{
    EtherLatency *emt = static_cast<EtherLatency *>(e);

    switch ((uintptr_t) thunk) {
        case EL_AVG_HANDLER: {
            return String(emt->mean());
        }

        case EL_MED_HANDLER: {
            return String(emt->percentile(50));
        }
        
        case EL_PERC_90_HANDLER: {
            return String(emt->percentile(90));
        }

        case EL_PERC_95_HANDLER: {
            return String(emt->percentile(95));
        }

        case EL_PERC_99_HANDLER: {
            return String(emt->percentile(99));
        }

        default:
	        return String("<error>");
    }
}

void EtherLatency::add_handlers()
{
    add_read_handler("avg", read_handler, EL_AVG_HANDLER);
    add_read_handler("median", read_handler, EL_MED_HANDLER);
    add_read_handler("perc90", read_handler, EL_PERC_90_HANDLER);
    add_read_handler("perc95", read_handler, EL_PERC_95_HANDLER);
    add_read_handler("perc99", read_handler, EL_PERC_99_HANDLER);
}

bool EtherLatency::should_aggregate()
{
    return _curr_idx.value() > 0;
}

double EtherLatency::mean()
{
    const uint32_t current_vector_length = static_cast<const uint32_t>(_curr_idx.value());
    double sum = 0.0;
    double n = 0;

    if (current_vector_length == 0) {
        return 0.0;
    }

    for (uint32_t i=0; i<current_vector_length; i++) {
        sum += _latencies[i];
        n++;
    }

    return sum / static_cast<double>(n);
}

double EtherLatency::percentile(const double percent)
{
    double perc = 0;
    const uint32_t current_vector_length = static_cast<const uint32_t>(_curr_idx.value());

    if (current_vector_length == 0) {
        return 0.0;
    }

    size_t idx = (percent * (current_vector_length)) / 100;

    if (idx <= 0) {
        return (*std::min_element(_latencies.begin(), _latencies.begin() + current_vector_length));
    } else if (idx >= current_vector_length) {
        return (*std::max_element(_latencies.begin(), _latencies.begin() + current_vector_length));
    }

    auto nth = _latencies.begin() + idx;
    std::nth_element(_latencies.begin(), nth, _latencies.begin() + current_vector_length);
    perc = (*nth);

    return perc;
}

CLICK_ENDDECLS
EXPORT_ELEMENT(EtherLatency)
