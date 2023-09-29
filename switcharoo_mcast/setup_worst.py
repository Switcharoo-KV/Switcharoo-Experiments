import os
import logging
import sys
import time

p4 = bfrt.switcharoo_mcast

PIPE_NUM = 0

MCAST_PORTS = [48, 52, 44, 40]

previous_received_pkts_count = 0
previous_received_bytes_count = 0
previous_sent_pkts_count = 0
previous_sent_bytes_count = 0

start_ts = time.time()


def run_pd_rpc(cmd_or_code, no_print=False):
    """
    This function invokes run_pd_rpc.py tool. It has a single string argument
    cmd_or_code that works as follows:
       If it is a string:
            * if the string starts with os.sep, then it is a filename
            * otherwise it is a piece of code (passed via "--eval"
       Else it is a list/tuple and it is passed "as-is"

    Note: do not attempt to run the tool in the interactive mode!
    """
    import subprocess

    path = os.path.join("/home", "tofino", "tools", "run_pd_rpc.py")

    command = [path]
    if isinstance(cmd_or_code, str):
        if cmd_or_code.startswith(os.sep):
            command.extend(["--no-wait", cmd_or_code])
        else:
            command.extend(["--no-wait", "--eval", cmd_or_code])
    else:
        command.extend(cmd_or_code)

    result = subprocess.check_output(command).decode("utf-8")[:-1]
    if not no_print:
        print(result)

    return result


def port_stats():
    import struct, logging

    global bfrt, previous_received_pkts_count, previous_received_bytes_count, previous_sent_pkts_count, \
        previous_sent_bytes_count, time, start_ts, MCAST_PORTS

    mcast_ports_stats = []
    for port in MCAST_PORTS:
        mcast_ports_stats.append(bfrt.port.port_stat.get(DEV_PORT=port, print_ents=False))

    total_pkts_received = 0
    total_bytes_received = 0
    total_pkts_sent = 0
    total_bytes_sent = 0
    for port_stat in mcast_ports_stats:
        total_pkts_received += port_stat.data[b'$FramesReceivedOK']
        total_bytes_received += port_stat.data[b'$OctetsReceived']
        total_pkts_sent += port_stat.data[b'$FramesTransmittedOK']
        total_bytes_sent += port_stat.data[b'$OctetsTransmittedTotal']

    ts = time.time() - start_ts

    logging.info("=====================================================================")
    delta_recv_bytes = total_bytes_received - previous_received_bytes_count
    delta_recv_pkts = total_pkts_received - previous_received_pkts_count
    logging.info("MCAST-%f-RESULT-MC_RCV_BPS %f bps" % (ts, delta_recv_bytes * 8))
    logging.info("MCAST-%f-RESULT-MC_RCV_PPS %f pps" % (ts, delta_recv_pkts))
    previous_received_pkts_count = total_pkts_received
    previous_received_bytes_count = total_bytes_received

    delta_sent_bytes = total_bytes_sent - previous_sent_bytes_count
    delta_sent_pkts = total_pkts_sent - previous_sent_pkts_count
    logging.info("MCAST-%f-RESULT-MC_SENT_BPS %f bps" % (ts, delta_sent_bytes * 8))
    logging.info("MCAST-%f-RESULT-MC_SENT_PPS %f pps" % (ts, delta_sent_pkts))
    previous_sent_pkts_count = total_pkts_sent
    previous_sent_bytes_count = total_bytes_sent
    logging.info("=====================================================================")


def port_stats_timer():
    import threading

    global port_stats_timer, port_stats
    port_stats()
    threading.Timer(1, port_stats_timer).start()


def set_worst():
    global bfrt

    bfrt.switcharoo_mcast.pipe.Ingress.base_flow_ip.mod(f1=0x01000001, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.base_flow_ip_index.mod(f1=0, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.number_of_ip.mod(f1=65535, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.n_packets_per_flow.mod(f1=1, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.flow_packet_counter.mod(f1=1, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.base_port_flow.mod(f1=1, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.port_flow.mod(f1=0, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.max_port.mod(f1=65535, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.consecutive_flows_number.mod(f1=1, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.flows_repetition.mod(f1=1, REGISTER_INDEX=0)
    bfrt.switcharoo_mcast.pipe.Ingress.flows_repetition_index.mod(f1=1, REGISTER_INDEX=0)


lab_path = os.path.join(os.environ['HOME'], "labs/switcharoo_mcast")

# Setup Logging
logging.basicConfig(
    format='%(message)s',
    level=logging.INFO,
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

(year, month, day, hour, minutes, _, _, _, _) = time.localtime(time.time())
log_path = os.path.join(lab_path, "logs")
log_timestamped_name = '64p-log-%d-%s-%s_%s-%s' % (
    year, str(month).zfill(2), str(day).zfill(2), str(hour).zfill(2), str(minutes).zfill(2))
os.makedirs(log_path, exist_ok=True)
file_handler = logging.FileHandler(os.path.join(log_path, "%s.log" % log_timestamped_name))
file_handler.setFormatter(logging.Formatter('%(message)s'))
logging.root.addHandler(file_handler)

# Run configurations
run_pd_rpc(os.path.join(lab_path, "run_pd_rpc/setup.py"))

set_worst()

port_stats_timer()
