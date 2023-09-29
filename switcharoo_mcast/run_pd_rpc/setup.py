N_MULTICAST = 4

PKTGEN_PORT = 36
MCAST_PORTS = [48, 52, 44, 40]

MCAST_GROUP_PORTS = MCAST_PORTS[:(N_MULTICAST if N_MULTICAST > 0 else 1)]


def increase_pool_size():
    print("Enlarging Queue Buffer Size")
    tm.set_app_pool_size(4, 20000000 // 80)


def set_ports():
    for p in MCAST_PORTS + [PKTGEN_PORT]:
        pal.port_add(p, pal.port_speed_t.BF_SPEED_100G, pal.fec_type_t.BF_FEC_TYP_REED_SOLOMON)
        pal.port_an_set(p, 1)
        pal.port_enable(p)


def set_mcast():
    node = mc.node_create(0, devports_to_mcbitmap(MCAST_GROUP_PORTS), lags_to_mcbitmap([]))
    mgrp = mc.mgrp_create(100)
    mc.associate_node(mgrp, node, False, 0)


increase_pool_size()
set_ports()
set_mcast()
