/*
 * etherlatencyagg.{cc,hh} -- aggregate handlers of EtherLatency elements
 * Mariano Scazzariello
 *
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
#include "etherlatencyagg.hh"
#include "../ethernet/etherlatency.hh"
#include <click/error.hh>
#include <click/confparse.hh>
#include <click/args.hh>

CLICK_DECLS

EtherLatencyAggregate::EtherLatencyAggregate()
{
}

EtherLatencyAggregate::~EtherLatencyAggregate()
{
}

int EtherLatencyAggregate::configure(Vector<String> &conf, ErrorHandler *errh)
{
    if (Args(conf, this, errh)
            .read_all("ELEMENT", _elements)
            .complete() < 0)
        return -1;

    return 0;
}

int EtherLatencyAggregate::initialize(ErrorHandler *errh)
{
    return 0;
}

enum {th_add = 0, th_avg};

int EtherLatencyAggregate::handler(int operation, String &data, Element *e,
			       const Handler *handler, ErrorHandler *errh)
{
    EtherLatencyAggregate *c = static_cast<EtherLatencyAggregate *>(e);

    double d = 0;
    uint64_t aggregated_elements = 0;

    int f = (intptr_t)handler->read_user_data();
    for (size_t i = 0; i < c->_elements.size(); i++) {
        EtherLatency *el = static_cast<EtherLatency *>(c->_elements[i]);
        if (el->should_aggregate()) {
            HandlerCall h(data);
            h.initialize_read(el, errh);
            d += atof(h.call_read().c_str());

            aggregated_elements++;
        }
    }

    switch (f) {
        case th_add:
            data = String( d );
            break;
        case th_avg:
            data = (aggregated_elements > 0) ? String( d / static_cast<double>(aggregated_elements) ) : String( 0.0 );
            break;
        default:
            data = "<error function "+String(f)+">" ;
            return 1;
    }

    return 0;
}

void EtherLatencyAggregate::add_handlers()
{
    set_handler("add", Handler::f_read | Handler::f_read_param, handler, th_add);
    set_handler("avg", Handler::f_read | Handler::f_read_param, handler, th_avg);
}

CLICK_ENDDECLS

EXPORT_ELEMENT(EtherLatencyAggregate)
