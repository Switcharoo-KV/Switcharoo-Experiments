/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

#define PKTGEN_PORT 36

#define OUTPUT_PORT_1 48
#define OUTPUT_PORT_2 52
#define OUTPUT_PORT_3 44
#define OUTPUT_PORT_4 40

/* INGRESS */
/* Types */
enum bit<16> ether_type_t {
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

/* IPv4 protocol type */
enum bit<8> ipv4_protocol_t {
    TCP = 0x06,
    UDP = 0x11
}

typedef bit<48> mac_addr_t;

typedef bit<32> ipv4_addr_t;

/* Standard headers */
header ethernet_h {
    bit<16> dst_addr_1;
    bit<32> dst_addr_2;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    ipv4_protocol_t protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_n;
    bit<32> ack_n;
    bit<4> data_offset;
    bit<4> res;
    bit<1> cwr;
    bit<1> ece;
    bit<1> urg;
    bit<1> ack;
    bit<1> psh;
    bit<1> rst;
    bit<1> syn;
    bit<1> fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

struct my_ingress_headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    tcp_h tcp;
    udp_h udp;
}

struct my_ingress_metadata_t {}

parser IngressParser(packet_in pkt, out my_ingress_headers_t hdr, out my_ingress_metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            ipv4_protocol_t.TCP: parse_tcp;
            ipv4_protocol_t.UDP: parse_udp;
            default: accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
}

control Ingress(inout my_ingress_headers_t hdr, inout my_ingress_metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    apply {
        if (hdr.ipv4.isValid()) {
            if (ig_intr_md.ingress_port == PKTGEN_PORT) {
                /* Tag the packet with the ingress timestamp */
                hdr.ethernet.src_addr[31:0] = ig_prsr_md.global_tstamp[31:0];

                ig_tm_md.mcast_grp_a = 100;
            } else {
                if (hdr.ipv4.identification == 0xffff) {
                    /* Send back only original packets */
                    /* Compute the latency */
                    hdr.ethernet.src_addr[31:0] = ig_prsr_md.global_tstamp[31:0] - hdr.ethernet.src_addr[31:0];

                    hdr.ipv4.identification = 0x0;

                    ig_tm_md.ucast_egress_port = PKTGEN_PORT;
                    ig_tm_md.bypass_egress = 0x1;
                } else {
                    ig_dprsr_md.drop_ctl = 0x1;
                }
            }
        }
    }
}

control IngressDeparser(packet_out pkt, inout my_ingress_headers_t hdr,
                        in my_ingress_metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr);
    }
}

/* EGRESS */
struct my_egress_headers_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
}

struct my_egress_metadata_t {}

parser EgressParser(packet_in pkt, out my_egress_headers_t hdr, out my_egress_metadata_t meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            ipv4_protocol_t.TCP: accept;
            ipv4_protocol_t.UDP: accept;
            default: accept;
        }
    }
}

control Egress(inout my_egress_headers_t hdr, inout my_egress_metadata_t meta,
               in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md, inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    apply {
        if (eg_intr_md.egress_port == OUTPUT_PORT_1) {
            hdr.ipv4.identification = 0xffff;
        } else if (eg_intr_md.egress_port == OUTPUT_PORT_2) {
            hdr.ipv4.src_addr = hdr.ipv4.src_addr + 1;
            hdr.ipv4.dst_addr = hdr.ipv4.dst_addr + 1;
        } else if (eg_intr_md.egress_port == OUTPUT_PORT_3) {
            hdr.ipv4.src_addr = hdr.ipv4.src_addr + 2;
            hdr.ipv4.dst_addr = hdr.ipv4.dst_addr + 2;
        } else if (eg_intr_md.egress_port == OUTPUT_PORT_4) {
            hdr.ipv4.src_addr = hdr.ipv4.src_addr + 3;
            hdr.ipv4.dst_addr = hdr.ipv4.dst_addr + 3;
        }
    }
}

control EgressDeparser(packet_out pkt, inout my_egress_headers_t hdr, in my_egress_metadata_t meta,
                       in egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.dscp,
            hdr.ipv4.ecn,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr
        });

        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
