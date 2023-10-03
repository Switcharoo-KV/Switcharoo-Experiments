import matplotlib
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import numpy as np
import os
import statistics
import sys
from distutils.util import strtobool

figures_path = "figures"

THROUGHPUT_FOLDER_TO_RATE = {
    "600000-1": 20,
    "1200000-1": 40,
    "1800000-1": 60,
    "2400000-1": 80,
    "3000000-1": 100,
    "1800000-2": 120,
    "2100000-2": 140,
    "2400000-2": 160,
    "2700000-2": 180,
    "3000000-2": 200,
    "2190000-3": 220,
    "2400000-3": 240,
    "2650000-3": 260,
    "2790000-3": 280,
    "3000000-3": 300,
    "2400000-4": 320,
    "2600000-4": 340,
    "2700000-4": 360,
    "2790000-4": 380,
    "3000000-4": 400
}


class OOMFormatter(matplotlib.ticker.ScalarFormatter):
    def __init__(self, order=0, fformat="%1.1f", offset=True, mathText=False):
        self.oom = order
        self.fformat = fformat
        matplotlib.ticker.ScalarFormatter.__init__(self, useOffset=offset, useMathText=mathText)

    def _set_order_of_magnitude(self):
        self.orderOfMagnitude = self.oom

    def _set_format(self, vmin=None, vmax=None):
        self.format = self.fformat
        if self._useMathText:
            self.format = r'$\mathdefault{%s}$' % self.format


def parse_tofino32p_logs(directory, metric):
    data = {}

    directory = os.path.join(directory, "switcharoo-logs")

    for item in filter(lambda i: not i.startswith("."), os.listdir(directory)):
        table_size = int(item.split('-')[1])
        if table_size not in data:
            data[table_size] = []

        data[table_size].append([])
        full_path = os.path.join(directory, item)
        with open(full_path, "r") as log_file:
            content = log_file.readlines()

        for row in content:
            if "SWITCHAROO" not in row:
                continue

            row = row.strip()

            (_, ts, _, met_val) = row.split('-')
            (met, val, unit) = met_val.split(' ')
            val = float(val)

            if val != 0.0 and met == metric:
                data[table_size][-1].append((float(ts), val))

    return data


def parse_tofino64p_logs(directory, metric):
    data = []

    directory = os.path.join(directory, "mcast-logs")

    for item in filter(lambda i: not i.startswith("."), os.listdir(directory)):
        full_path = os.path.join(directory, item)
        with open(full_path, "r") as log_file:
            content = log_file.readlines()

        for row in content:
            if "MCAST" not in row:
                continue

            row = row.strip()

            (_, ts, _, met_val) = row.split('-')
            (met, val, unit) = met_val.split(' ')
            val = float(val)

            if val != 0.0 and met == metric:
                data.append((float(ts), val))

    return data


def parse_fastclick_logs(directory):
    data = {
        "LAT50": {},
        "LAT90": {},
        "LAT95": {},
        "LAT99": {},
        "OUTOFORDER": {},
        "recirculations": {},
        "recirculations2latency": {}
    }

    directory = os.path.join(directory, "fastclick-logs")

    for item in filter(lambda i: not i.startswith("."), os.listdir(directory)):
        table_size = int(item.split('-')[1])

        if table_size not in data["recirculations"]:
            data["recirculations"][table_size] = {}
            data["LAT50"][table_size] = []
            data["LAT90"][table_size] = []
            data["LAT95"][table_size] = []
            data["LAT99"][table_size] = []
            data["OUTOFORDER"][table_size] = []
            data["recirculations2latency"][table_size] = {}

        full_path = os.path.join(directory, item)

        with open(full_path, "r") as log_file:
            content = log_file.readlines()

        for row in content:
            row = row.strip()

            row = row.strip()
            (_, ts, _, met_val) = row.split('-')
            (met, val, unit) = met_val.split(' ')
            val = float(val)

            if "LAT50" in met:
                data["LAT50"][table_size].append(val)

            if "LAT90" in met:
                data["LAT90"][table_size].append(val)

            if "LAT95" in met:
                data["LAT95"][table_size].append(val)

            if "LAT99" in met:
                data["LAT99"][table_size].append(val)

            if "OUTOFORDER" in met:
                data["OUTOFORDER"][table_size].append(val)

            if "RECIRC_" in met:
                num = met.split("_")[1]
                if "MORE11" in num:
                    num = 12

                num = int(num)

                if num not in data["recirculations"][table_size]:
                    data["recirculations"][table_size][num] = []

                data["recirculations"][table_size][num].append(val)

            if "LAT_" in met:
                num = met.split("_")[1]
                if "MORE11" in num:
                    num = 12

                num = int(num)

                if num not in data["recirculations2latency"][table_size]:
                    data["recirculations2latency"][table_size][num] = []

                data["recirculations2latency"][table_size][num].append(val)

    return data


def plot_swaps_table_size_figure(results_path):
    global figures_path

    def plot_swaps_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        swaps = parse_tofino32p_logs(directory, "SWAPS")

        for size, results in sorted(swaps.items(), key=lambda item: int(item[0])):
            values = []
            for idx, value in enumerate(results):
                if value:
                    values.append(value[-1][1])

            to_plot['x'].append(size)
            to_plot['y'].append(statistics.mean(values) if values else 0)
            to_plot['dy'].append(statistics.stdev(values) if values else 0)

        plt.plot(
            to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker
        )

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_swaps_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_swaps_table_size_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flows", "darkblue")
    plot_swaps_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    ax.yaxis.set_major_formatter(OOMFormatter(8, "%.2f"))
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('N. Swaps')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "swaps_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_swaps_insertions_table_size_figure(results_path):
    global figures_path

    def plot_swaps_insertions_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        swaps = parse_tofino32p_logs(directory, "SWAPS")
        insertions = parse_tofino32p_logs(directory, "INSERTIONS")

        for size, results in sorted(swaps.items(), key=lambda item: int(item[0])):
            values = []
            for idx, value in enumerate(results):
                if value:
                    insertion_num = insertions[size][idx][-1][1]
                    percentage_of_swaps = (value[-1][1] / insertion_num) * 100
                    values.append(percentage_of_swaps)

            to_plot['x'].append(size)
            to_plot['y'].append(statistics.mean(values) if values else 0)
            to_plot['dy'].append(statistics.stdev(values) if values else 0)

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color,
                 marker=marker)

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_swaps_insertions_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_swaps_insertions_table_size_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flows", "darkblue")
    plot_swaps_insertions_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    ax.set_ylim([-10, 150])
    plt.yticks(range(0, 160, 20))

    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Swaps / Insertions [%]')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "swaps_insertions_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_swaps_inputpkts_table_size_figure(results_path):
    global figures_path

    def plot_swaps_inputpkts_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        swaps = parse_tofino32p_logs(directory, "SWAPS")
        input_pkts = parse_tofino32p_logs(directory, "INPUT_PKTS")

        for size, results in sorted(swaps.items(), key=lambda item: int(item[0])):
            values = []
            for idx, value in enumerate(results):
                if value:
                    input_pkts_num = input_pkts[size][idx][-1][1]
                    percentage_of_swaps = (value[-1][1] / input_pkts_num) * 100
                    values.append(percentage_of_swaps)

            to_plot['x'].append(size)
            to_plot['y'].append(statistics.mean(values) if values else 0)
            to_plot['dy'].append(statistics.stdev(values) if values else 0)

        plt.plot(
            to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker
        )

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_swaps_inputpkts_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_swaps_inputpkts_table_size_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flows", "darkblue")
    plot_swaps_inputpkts_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Swaps / Total Packets [%]')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "swaps_inputpkts_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_recirculation_bandwidth_table_size_figure(results_path):
    global figures_path

    def plot_recirculation_bandwidth_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        recirc_bps = parse_tofino32p_logs(directory, "RECIRC_BPS")

        for size, results in sorted(recirc_bps.items(), key=lambda item: int(item[0])):
            values = []
            for result in results:
                if result:
                    val = list(map(lambda item: item[1] / 1000000000, result))[1:][:-1]
                    values.append(statistics.mean(list(filter(lambda item: item > 1, val))))

            to_plot['x'].append(int(size))
            to_plot['y'].append(statistics.mean(values))
            to_plot['dy'].append(statistics.stdev(values))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color,
                 marker=marker)

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_recirculation_bandwidth_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows",
                                                 "darkred")
    plot_recirculation_bandwidth_table_size_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flows",
                                                 "darkblue")
    plot_recirculation_bandwidth_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows",
                                                 "darkgreen")

    ax.set_ylim([0, 260])
    ax.set_yticks(range(0, 260, 20))
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Recirculation Bandwidth\n[Gbps]')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "recirc_bps_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_ips_table_size_figure(results_path):
    global figures_path

    def plot_ips_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        ips = parse_tofino32p_logs(directory, "IPS")
        for size, results in sorted(ips.items(), key=lambda item: int(item[0])):
            values = []
            for result in results:
                if result:
                    val = list(map(lambda item: item[1], result))[1:-1]
                    values.append(statistics.mean(val))

            to_plot['x'].append(int(size))
            to_plot['y'].append(statistics.mean(values))
            to_plot['dy'].append(statistics.stdev(values))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color,
                 marker=marker)

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_ips_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_ips_table_size_line(os.path.join(results_path, "avg"), 'royalblue', "^", "2-Pkt Flows", "blue")
    plot_ips_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    ax.yaxis.set_major_formatter(OOMFormatter(6, "%d"))
    ax.set_ylim([0, 13000000])
    plt.yticks(range(0, 13000000, 1000000))
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Insertions per Second')
    plt.legend(loc=(0.65, 0.50), labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "ips_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_insertions_table_size_figure(results_path):
    global figures_path

    def plot_insertions_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        insertions = parse_tofino32p_logs(directory, "INSERTIONS")
        for size, results in sorted(insertions.items(), key=lambda item: int(item[0])):
            values = []
            for result in results:
                if result:
                    values.append(result[-1][1])

            to_plot['x'].append(int(size))
            to_plot['y'].append(statistics.mean(values))
            to_plot['dy'].append(statistics.stdev(values))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker='o')

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_insertions_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_insertions_table_size_line(os.path.join(results_path, "avg"), 'royalblue', "^", "2-Pkt Flows", "blue")
    plot_insertions_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    ax.yaxis.set_major_formatter(OOMFormatter(6, "%d"))
    ax.set_ylim([0, 160000000])
    plt.yticks(range(0, 160000000, 20000000))
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Total Insertions')
    plt.legend(loc=(0.65, 0.55), labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "insertions_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_ips_throughput_figure(results_path):
    global figures_path

    def plot_ips_throughput_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        for (folder, rate) in sorted(map(lambda i: (i, THROUGHPUT_FOLDER_TO_RATE[i]),
                                         filter(lambda i: not i.startswith("."), os.listdir(directory))),
                                     key=lambda i: i[1]):
            ips = parse_tofino32p_logs(os.path.join(directory, folder), "IPS")
            for size, results in sorted(ips.items(), key=lambda item: int(item[0])):
                values = []
                for result in results:
                    if result:
                        val = list(map(lambda item: item[1], result))[1:-1]
                        values.append(statistics.mean(val) / 1000000)

                to_plot['x'].append(rate)
                to_plot['y'].append(statistics.mean(values))
                to_plot['dy'].append(statistics.stdev(values))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color,
                 marker=marker)

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_ips_throughput_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_ips_throughput_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flows", "darkblue")
    plot_ips_throughput_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    ax.set_ylim([0, 54])
    plt.yticks(range(0, 54, 5))
    plt.xticks([0, 20, 40, 60, 80, 100,
                120, 140, 160, 180, 200,
                220, 240, 260, 280, 300,
                320, 340, 360, 380, 400, 420], rotation=90)

    plt.xlabel('Throughput [Gbps]')
    plt.ylabel('Millions of\nInsertions per Second')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "ips_throughput.pdf"), format="pdf", bbox_inches='tight')


def plot_recirculated_packets_figure(results_path, size):
    global figures_path

    def plot_recirculated_packets_bars(directory, color, hatch, label, offset):
        to_plot = {'x': [], 'y': []}
        fastclick_res = parse_fastclick_logs(directory)["recirculations"]
        input_pkts = parse_tofino32p_logs(directory, "INPUT_PKTS")

        for recircs, results in fastclick_res[size].items():
            total_pkts = map(lambda x: x[-1][1], input_pkts[size])

            to_plot['x'].append(recircs + offset)
            values = list(filter(lambda item: item > 0, [(x / y) * 100 for x, y in zip(results, total_pkts)]))
            to_plot['y'].append(statistics.mean(values) if values else 0)

        plt.bar(to_plot['x'], to_plot['y'], label=label, fill=None, hatch=hatch, edgecolor=color, width=0.2)

    plt.clf()
    ax = plt.gca()
    plot_recirculated_packets_bars(os.path.join(results_path, "worst"), 'red', "////", "1-Pkt Flows", 0.2)
    plot_recirculated_packets_bars(os.path.join(results_path, "avg"), 'blue', "\\\\\\\\", "2-Pkt Flow", 0)
    plot_recirculated_packets_bars(os.path.join(results_path, "best"), 'green', "++++", "8-Pkt Flow", -0.2)

    ax.set_xlim([-0.5, 5.5])
    plt.xticks(range(0, 6, 1), labels=["0", "1", "2", "3", "4", "5"])

    ax.set_ylim([0.01, 200])
    plt.yscale('log', base=10)
    ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda y, _: '{:g}'.format(y)))

    plt.xlabel('N. Recirculations')
    plt.ylabel('% Packets')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, f"recirculated_packets_{size}.pdf"), format="pdf", bbox_inches='tight')


def plot_latency_table_size_line(directory, percentile, color, marker, label, errorbar_color):
    to_plot = {'x': [], 'y': [], 'dy': []}
    latencies = parse_fastclick_logs(directory)[percentile]
    for size, results in sorted(latencies.items(), key=lambda item: int(item[0])):
        if results:
            to_plot['x'].append(size)
            to_plot['y'].append(statistics.mean(results))
            to_plot['dy'].append(statistics.stdev(results))

    plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker)

    for idx, x in enumerate(to_plot['x']):
        plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)


def plot_latency_table_size_figure(results_path):
    global figures_path

    plt.clf()
    ax = plt.gca()
    plot_latency_table_size_line(os.path.join(results_path, "worst"), "LAT50", 'red', "o", "1-Pkt Flow", "darkred")
    plot_latency_table_size_line(os.path.join(results_path, "avg"), "LAT50", 'blue', "^", "2-Pkt Flow", "darkblue")
    plot_latency_table_size_line(os.path.join(results_path, "best"), "LAT50", 'green', "s", "8-Pkt Flow", "darkgreen")

    ax.set_ylim([0, 8])
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Latency [μs]')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "latency_50_tablesize.pdf"), format="pdf", bbox_inches='tight')

    plt.clf()
    ax = plt.gca()
    plot_latency_table_size_line(os.path.join(results_path, "worst"), "LAT99", 'red', "o", "1-Pkt Flow", "darkred")
    plot_latency_table_size_line(os.path.join(results_path, "avg"), "LAT99", 'blue', "^", "2-Pkt Flow ", "darkblue")
    plot_latency_table_size_line(os.path.join(results_path, "best"), "LAT99", 'green', "s", "8-Pkt Flow", "darkgreen")

    ax.set_ylim([0, 8])
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Latency [μs]')
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "latency_99_tablesize.pdf"), format="pdf", bbox_inches='tight')


def plot_expired_table_size_figure(results_path, table_number):
    global figures_path

    def plot_expired_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        expired_1 = parse_tofino32p_logs(directory, "EXPIRED_1")
        expired_2 = parse_tofino32p_logs(directory, "EXPIRED_2")

        for size, results in sorted(expired_1.items(), key=lambda item: int(item[0])):
            values = []
            for idx, value in enumerate(results):
                if value:
                    expired_1_num = value[-1][1]
                    expired_2_num = expired_2[size][idx][-1][1]

                    if table_number == 0:
                        values.append(expired_2_num + expired_1_num)
                    elif table_number == 1:
                        values.append(expired_1_num)
                    elif table_number == 2:
                        values.append(expired_2_num)

            to_plot['x'].append(size)
            to_plot['y'].append(statistics.mean(values))
            to_plot['dy'].append(statistics.stdev(values))

        plt.plot(
            to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker
        )

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    ax = plt.gca()
    plot_expired_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flow", "darkred")
    plot_expired_table_size_line(os.path.join(results_path, "avg"), 'blue', "^", "2-Pkt Flow ", "darkblue")
    plot_expired_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flow", "darkgreen")

    ax.yaxis.set_major_formatter(OOMFormatter(6, "%d"))
    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Expired Entries' + (f' Table {table_number}' if table_number > 0 else ''))
    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(
        os.path.join(figures_path, 'expired_tablesize_' + (str(table_number) if table_number > 0 else 'all') + '.pdf'),
        format="pdf", bbox_inches='tight'
    )


def plot_latency_recirculations_figure(results_path, size):
    global figures_path

    def plot_latency_recirculations_bars(directory, color, hatch, label, offset):
        to_plot = {'x': [], 'y': []}
        fastclick_res = parse_fastclick_logs(directory)["recirculations2latency"]
        for recircs, results in fastclick_res[size].items():
            to_plot['x'].append(recircs + offset)
            values = list(filter(lambda item: item > 0, results))
            to_plot['y'].append(statistics.mean(values) if values else 0)

        plt.bar(to_plot['x'], to_plot['y'], label=label, fill=None, edgecolor=color, hatch=hatch, width=0.2)

    plt.clf()
    ax = plt.gca()
    plot_latency_recirculations_bars(os.path.join(results_path, "worst"), 'red', "////", "1-Pkt Flows", 0.2)
    plot_latency_recirculations_bars(os.path.join(results_path, "avg"), 'blue', "\\\\\\\\", "2-Pkt Flows", 0)
    plot_latency_recirculations_bars(os.path.join(results_path, "best"), 'green', "++++", "8-Pkt Flows", -0.2)

    ax.set_xlim([-0.5, 5.5])
    plt.xticks(range(0, 6, 1), labels=["0", "1", "2", "3", "4", "5"])
    plt.xlabel('N. Recirculations')
    plt.ylabel('Latency [us]')

    plt.legend(loc='best', labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, f"latency_recirculations_{size}.pdf"), format="pdf", bbox_inches='tight')


def plot_drops_tm_table_size_figure(results_path):
    def plot_drops_tm_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        ig_drops = parse_tofino32p_logs(directory, "IG_DROP")
        eg_drops = parse_tofino32p_logs(directory, "EG_DROP")
        for size, results in sorted(ig_drops.items(), key=lambda item: int(item[0])):
            values = []
            for idx, result in enumerate(results):
                val = 0

                if eg_drops[size][idx]:
                    val += eg_drops[size][idx][-1][1]

                if result:
                    val += result[-1][1]
                    values.append(val)

            to_plot['x'].append(size)
            to_plot['y'].append(0 if not values else statistics.mean(values))
            to_plot['dy'].append(0 if not values else statistics.stdev(values))

        plt.plot(
            to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker
        )

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    plot_drops_tm_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_drops_tm_table_size_line(os.path.join(results_path, "avg"), 'royalblue', "^", "2-Pkt Flows", "blue")
    plot_drops_tm_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Total TM Drops')
    plt.legend(loc=(0.65, 0.55), labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "drops_tm_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_drops_wire_table_size_figure(results_path):
    def plot_drops_wire_table_size_line(directory, color, marker, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        input_pkts = parse_tofino32p_logs(directory, "INPUT_PKTS")
        output_pkts = parse_tofino32p_logs(directory, "OUTPUT_PKTS")
        for size, results in sorted(input_pkts.items(), key=lambda item: int(item[0])):
            values = []
            for idx, result in enumerate(results):
                val = result[-1][1]
                val -= output_pkts[size][idx][-1][1]

                values.append(val)

            to_plot['x'].append(size)
            to_plot['y'].append(0 if not values else statistics.mean(values))
            to_plot['dy'].append(0 if not values else statistics.stdev(values))

        plt.plot(
            to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker=marker
        )

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    plot_drops_wire_table_size_line(os.path.join(results_path, "worst"), 'red', "o", "1-Pkt Flows", "darkred")
    plot_drops_wire_table_size_line(os.path.join(results_path, "avg"), 'royalblue', "^", "2-Pkt Flows", "blue")
    plot_drops_wire_table_size_line(os.path.join(results_path, "best"), 'green', "s", "8-Pkt Flows", "darkgreen")

    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Total Wire Drops')
    plt.legend(loc=(0.65, 0.55), labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "drops_wire_table_size.pdf"), format="pdf", bbox_inches='tight')


def plot_outoforder_table_size_figure(results_path, results_no_ordering_path):
    def plot_outoforder_table_size_line(directory, color, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        outoforder = parse_fastclick_logs(directory)["OUTOFORDER"]
        output_pkts = parse_tofino32p_logs(directory, "OUTPUT_PKTS")

        for size, results in sorted(outoforder.items(), key=lambda item: int(item[0])):
            output_pkts_experiment = list(map(lambda x: x[-1][1], output_pkts[size]))
            results_perc = [] if not results else list(
                map(lambda x: (x[0] / x[1]) * 100, zip(results, output_pkts_experiment)))

            to_plot['x'].append(size)
            to_plot['y'].append(0 if not results_perc else statistics.mean(results_perc))
            to_plot['dy'].append(0 if not results_perc else statistics.stdev(results_perc))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker='o')

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    def plot_outoforder_no_ordering_table_size_line(directory_no_ordering, color, label, errorbar_color):
        to_plot = {'x': [], 'y': [], 'dy': []}
        outoforder_no_ordering = parse_fastclick_logs(directory_no_ordering)["OUTOFORDER"]
        output_pkts = parse_tofino32p_logs(directory_no_ordering, "OUTPUT_PKTS")

        for size, results in sorted(outoforder_no_ordering.items(), key=lambda item: int(item[0])):
            output_pkts_experiment = list(map(lambda x: x[-1][1], output_pkts[size]))
            results_perc = [] if not results else list(
                map(lambda x: (x[0] / x[1]) * 100, zip(results, output_pkts_experiment)))

            to_plot['x'].append(size)
            to_plot['y'].append(0 if not results_perc else statistics.mean(results_perc))
            to_plot['dy'].append(0 if not results_perc else statistics.stdev(results_perc))

        plt.plot(to_plot['x'], to_plot['y'], label=label, linestyle='dashed', fillstyle='none', color=color, marker='^')

        for idx, x in enumerate(to_plot['x']):
            plt.errorbar(x, to_plot['y'][idx], yerr=to_plot['dy'][idx], color=errorbar_color, elinewidth=1, capsize=1)

    plt.clf()
    plot_outoforder_table_size_line(os.path.join(results_path, "best"), 'green', "8-Pkt Flows (w/ Ordering)",
                                    "darkgreen")
    plot_outoforder_no_ordering_table_size_line(os.path.join(results_no_ordering_path, "best"), 'springgreen',
                                                "8-Pkt Flows (w/o Ordering)", "springgreen")

    set_x_axis_table_size()

    plt.xlabel('N. Cuckoo Table Entries')
    plt.ylabel('Out-of-Order Pkts / Total Pkts [%]')
    plt.legend(loc="best", labelspacing=0.2, prop={'size': 8})
    plt.savefig(os.path.join(figures_path, "outoforder_table_size.pdf"), format="pdf", bbox_inches='tight')


def set_x_axis_table_size():
    plt.xscale('log', base=2)
    plt.xticks([1024, 2048, 4096, 8192, 16336, 32768, 65536],
               labels=["1k", "2k", "4k", "8k", "16k", "32k", "65k"], rotation=45)


if __name__ == "__main__":
    if len(sys.argv) < 6:
        print(
            "Usage: plot.py <table_size_results> <table_size_no_ordering_results> <bloom_size_results> <throughput_results> <figures_path>"
        )
        exit(1)

    results_per_table_size_path = os.path.abspath(sys.argv[1])
    results_per_table_size_no_ordering_path = os.path.abspath(sys.argv[2])
    results_per_bloom_size_path = os.path.abspath(sys.argv[3])
    results_per_throughput_path = os.path.abspath(sys.argv[4])
    figures_path = os.path.abspath(sys.argv[5])

    os.makedirs(figures_path, exist_ok=True)

    plt.figure(figsize=(4, 2))
    matplotlib.rc('font', size=8)
    matplotlib.rcParams['hatch.linewidth'] = 0.3
    matplotlib.rcParams['pdf.fonttype'] = 42
    matplotlib.rcParams['ps.fonttype'] = 42

    # Figure 4
    plot_ips_throughput_figure(results_per_throughput_path)

    # Figure 5a
    plot_recirculation_bandwidth_table_size_figure(results_per_table_size_path)
    # Figure 5b
    plot_swaps_insertions_table_size_figure(results_per_table_size_path)

    # Figure 6
    plot_latency_table_size_figure(results_per_table_size_path)

    # Figure 7
    plot_outoforder_table_size_figure(results_per_table_size_path, results_per_table_size_no_ordering_path)

    # Figure 8a
    plot_recirculated_packets_figure(results_per_table_size_path, 32768)
    # Figure 8b
    plot_latency_recirculations_figure(results_per_table_size_path, 32768)

    # Additional Plots (not in the paper)
    plot_swaps_table_size_figure(results_per_table_size_path)
    plot_swaps_inputpkts_table_size_figure(results_per_table_size_path)
    plot_ips_table_size_figure(results_per_table_size_path)
    plot_insertions_table_size_figure(results_per_table_size_path)

    plot_recirculated_packets_figure(results_per_table_size_path, 1024)
    plot_recirculated_packets_figure(results_per_table_size_path, 2048)
    plot_recirculated_packets_figure(results_per_table_size_path, 4096)
    plot_recirculated_packets_figure(results_per_table_size_path, 8192)
    plot_recirculated_packets_figure(results_per_table_size_path, 16384)
    plot_recirculated_packets_figure(results_per_table_size_path, 65536)

    plot_latency_recirculations_figure(results_per_table_size_path, 1024)
    plot_latency_recirculations_figure(results_per_table_size_path, 2048)
    plot_latency_recirculations_figure(results_per_table_size_path, 4096)
    plot_latency_recirculations_figure(results_per_table_size_path, 8192)
    plot_latency_recirculations_figure(results_per_table_size_path, 16384)
    plot_latency_recirculations_figure(results_per_table_size_path, 65536)

    plot_expired_table_size_figure(results_per_table_size_path, 0)
    plot_expired_table_size_figure(results_per_table_size_path, 1)
    plot_expired_table_size_figure(results_per_table_size_path, 2)

    plot_drops_tm_table_size_figure(results_per_table_size_path)
    plot_drops_wire_table_size_figure(results_per_table_size_path)
