/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

#define PKTGEN_PORT 36
#define PKTGEN_IP 0x0a1b3cd6

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
    Register<bit<16>, _>(1) n_packets_per_flow;
    Register<bit<16>, _>(1) base_port_flow;                    
    Register<bit<16>, _>(1) port_flow;
    Register<bit<16>, _>(1) max_port;
    Register<bit<16>, _>(1) flow_packet_counter;
    Register<bit<32>, _>(1) base_flow_ip;
    Register<bit<32>, _>(1) base_flow_ip_index;
    Register<bit<32>, _>(1) number_of_ip;
    Register<bit<16>, _>(1) consecutive_flows_number;
    Register<bit<16>, _>(1) flows_repetition;
    Register<bit<16>, _>(1) flows_repetition_index;
    
    bit<16> repetition;
    bit<16> consecutive_flows_num;

    bit<32> max_number_of_ip;
    bit<16> max_port_value;

    RegisterAction<bit<16>, _, bit<16>>(base_port_flow) base_port_flow_increment = {
        void apply(inout bit<16> value, out bit<16> read_value) {
            if (value == max_port_value) {
                value = 1;
            } else {
                value = value + consecutive_flows_num;
            }
            read_value = value;
        }
    };

    RegisterAction<bit<16>, _, bool>(flows_repetition_index) flows_repetition_index_read_and_increment = {
        void apply(inout bit<16> value, out bool read_value) {
            if (value == repetition) {
                value = 1;
                read_value = false;
            } else {
                value = value + 1;
                read_value = true;
            }
        }
    };

    RegisterAction<bit<16>, _, bit<16>>(port_flow) port_flow_increment = {
        void apply(inout bit<16> value, out bit<16> read_value) {
            if (value == consecutive_flows_num - 1) {
                value = 0;
            } else {
                value = value + 1;
            }
            read_value = value;
        }
    };

    bit<16> pkts_per_flow;
    RegisterAction<bit<16>, _, bool>(flow_packet_counter) flow_packet_counter_increment = {
        void apply(inout bit<16> value, out bool read_value) {
            if (value == pkts_per_flow) {
                value = 1;
                read_value = true;
            } else {
                value = value + 1;
                read_value = false;
            }
        }
    };

    RegisterAction<bit<32>, _, bit<32>>(base_flow_ip_index) base_flow_ip_index_increment = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            if (value == max_number_of_ip) {
                value = 0;
            } else {
                value = value + 1;
            }
            read_value = value;
        }
    };

    Random<bit<32>>() src_ip_gen;
    bit<32> src_ip_seed = src_ip_gen.get();
    RegisterAction<bit<32>, _, bit<32>>(base_flow_ip) base_flow_ip_update = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            value = src_ip_seed;
            read_value = value;
        }
    };

    apply {
        if (hdr.ipv4.isValid()) {
            if (ig_intr_md.ingress_port == PKTGEN_PORT) {
                /* Tag the packet with the ingress timestamp */
                hdr.ethernet.src_addr[31:0] = ig_prsr_md.global_tstamp[31:0];

                ig_tm_md.mcast_grp_a = 100;

                pkts_per_flow = n_packets_per_flow.read(0);
                consecutive_flows_num = consecutive_flows_number.read(0);
                repetition = flows_repetition.read(0);
                max_number_of_ip = number_of_ip.read(0);
                
                bit<16> base_port_flow_value;
                bit<16> port_flow_value;
                bit<32> base_ip_value;
                bit<32> ip_index_value;
                bool to_repeat = true;
                bool flow_packet_counter_value = flow_packet_counter_increment.execute(0);

                if (flow_packet_counter_value) {
                    max_port_value = max_port.read(0);
                    port_flow_value = port_flow_increment.execute(0);
                    if (port_flow_value == 0) {
                        to_repeat = flows_repetition_index_read_and_increment.execute(0);
                    }

                    if (to_repeat) {
                        base_port_flow_value = base_port_flow.read(0);
                    } else {
                        base_port_flow_value = base_port_flow_increment.execute(0);
                    }
                    
                    if (port_flow_value == 0 && !to_repeat) {
                        base_ip_value = base_flow_ip_update.execute(0);
                        ip_index_value = base_flow_ip_index_increment.execute(0);
                    } else {
                        base_ip_value = base_flow_ip.read(0);
                        ip_index_value = base_flow_ip_index.read(0);
                    }
                } else {
                    base_ip_value = base_flow_ip.read(0);
                    ip_index_value = base_flow_ip_index.read(0);
                    base_port_flow_value = base_port_flow.read(0);
                    port_flow_value = port_flow.read(0);
                }

                hdr.ipv4.src_addr = base_ip_value;
                hdr.ipv4.dst_addr = base_ip_value + ip_index_value;
                hdr.udp.src_port = 1111;
                hdr.udp.dst_port = base_port_flow_value + port_flow_value;
            } else {
                if (hdr.udp.src_port == 1111) {
                    /* Send back only original packets */
                    /* Compute the latency */
                    hdr.ethernet.src_addr[31:0] = ig_prsr_md.global_tstamp[31:0] - hdr.ethernet.src_addr[31:0];

                    ig_tm_md.ucast_egress_port = PKTGEN_PORT;
                } else {
                    /* Drop mcast copies */
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
    tcp_h tcp;
    udp_h udp;
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

control Egress(inout my_egress_headers_t hdr, inout my_egress_metadata_t meta,
               in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
               inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md, inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {
    apply {
        if (hdr.ipv4.isValid()) {
            if (eg_intr_md.egress_port == OUTPUT_PORT_2) {
                hdr.udp.src_port = 2222;
            } else if (eg_intr_md.egress_port == OUTPUT_PORT_3) {
                hdr.udp.src_port = 3333;
            } else if (eg_intr_md.egress_port == OUTPUT_PORT_4) {
                hdr.udp.src_port = 4444;
            }
        }
    }
}

control EgressDeparser(packet_out pkt, inout my_egress_headers_t hdr, in my_egress_metadata_t meta,
                       in egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md) {
    apply {
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
