# Switcharoo Experiments
This repository contains the evaluation scripts used to measure Switcharoo performance.

## Repository Organization

This repository contains:
- `generator`: [FastClick](https://github.com/tbarbette/fastclick) elements and scripts used to generate traffic towards a Tofino switch;
- `switcharoo_mcast`: P4 program that takes incoming packets, manipulates their flow tuple to generate synthetic flows using some configuration parameters and multicasts them towards Switcharoo;
- `tests`: evaluation scripts and results plotter.

The experiments require two Tofino switches and an external server that acts as a traffic generator and measurements gatherer.

### Traffic Generator

The traffic generator uses [FastClick](https://github.com/tbarbette/fastclick), in particular, it needs some additional elements to be compiled inside the vanilla version.

We used **Ubuntu 20.04.4 LTS** as the Operating System on the server.

First compile and install DPDK, following [this tutorial](https://doc.dpdk.org/guides/prog_guide/build-sdk-meson.html). We used **DPDK 21.08.0**, and it is the only tested version.

After installing DPDK, pull both this repository and FastClick:

```bash
$ git clone https://github.com/Switcharoo-P4/Switcharoo-Experiments.git
$ git clone https://github.com/tbarbette/fastclick.git
```

Checkout to the specific FastClick commit ([cf0f2b507c](https://github.com/tbarbette/fastclick/tree/cf0f2b507c6fcb1e4f99a834912f62a262fb8e9c)):
```bash
cd fastclick
git checkout cf0f2b507c6fcb1e4f99a834912f62a262fb8e9c
```
Enter the `Switcharoo-Experiments` folder and copy the `generator/fastclick/elements` folder inside the root folder of FastClick, where there is already an `elements` folder. Confirm to merge the two.

Install FastClick's dependencies by running the `deps.sh` script.

In our testbed, FastClick has been configured with the following command:
```bash
$ cd fastclick
$ PKG_CONFIG_PATH=/path/to/dpdk/install/lib/x86_64-linux-gnu/pkgconfig ./configure --enable-dpdk --enable-intel-cpu --verbose --enable-select=poll "CFLAGS=-O3" "CXXFLAGS=-std=c++17 -O3" --disable-dynamic-linking --enable-poll --enable-bound-port-transfer --enable-local --enable-flow --disable-task-stats --enable-cpu-load --enable-dpdk-packet --disable-clone --disable-dpdk-softqueue --enable-research --disable-sloppy --enable-user-timestamp
```
Replace the `PKG_CONFIG_PATH` with the path of your DPDK installation. 

Build the project:
```bash
$ make
```

**NOTE**: In order to run the CAIDA experiment, you need a CAIDA trace locally stored on the server. Providing such trace is out of the scope of this repository. However, if you have the trace, you need the change the trace path in the `generator/gen-trace.click` file (from line 17 to line 24). 

### Multicast P4 Program

You need a Tofino to build and run the `switcharoo_mcast` program. This Tofino switch should be connected with some ports to the Switcharoo Tofino. The default configuration uses four ports.

To build the code, use the following command:
```bash 
./p4_build.sh /path/to/switcharoo_mcast.p4
```

`switcharoo_mcast.p4` has been tested on **SDE 9.7.0**.

### Tests

In this folder, you will find both the `bash` scripts to run the paper experiments and a `plot.py` to plot all the figures of the paper. 

The `plot.py` requires `matplotlib`:
```bash
python3 -m pip install matplotlib
```

## Configuration

### Change the FastClick configuration

You need to specify the FastClick installation directory in the `gen-rated-mt-lat.sh` and `gen-trace.sh` files.
Also, you need to specify the interface PCI address of the NIC port to use to send traffic.

Open the `gen-*.sh` files with an editor and change the `/path/to/fastclick` with the root folder of the compiled FastClick.
To change the port, replace `-a 3b:00.1` with the interface PCI address of your NIC port.

FastClick is started using 16 threads, but the generator scripts only require 4 threads.
You can change the number of threads in the `gen-*.sh` files by changing the `-l 0-15` parameter to a different range.

### Change Ports in `switcharoo_mcast`

<p align="center">
    <img src=img/testbed.png?raw=true" alt="Testbed" />
</p>

The figure above depicts the Switcharoo's testbed with the associated port names.
For more information about the Switcharoo Tofino ports, please refer to the [dedicated repository](https://github.com/Switcharoo-P4/Switcharoo-P4).

To change the ports in the `switcharoo_mcast` program, you need to:
- Change the `switcharoo_mcast.p4` defines:
```p4
#define PKTGEN_PORT 36
#define PKTGEN_IP 0x0a1b3cd6

#define OUTPUT_PORT_1 48
#define OUTPUT_PORT_2 52
#define OUTPUT_PORT_3 44
#define OUTPUT_PORT_4 40
```

- Change the `setup*.py` files:
```python3
MCAST_PORTS = [48, 52, 44, 40]
```

- Change the `run_pd_rpc/setup.py` file:
```python3
PKTGEN_PORT = 36
MCAST_PORTS = [48, 52, 44, 40]
```

You then need to recompile the P4 program.

### Changing Traffic Patterns in `switcharoo_mcast`

`switcharoo_mcast` has three different traffic patterns (which are the ones described in the paper).

You can define a new traffic pattern by changing the following registers:
```python3
bfrt.switcharoo_mcast.pipe.Ingress.base_flow_ip.mod(f1=0x01000001, REGISTER_INDEX=0)
bfrt.switcharoo_mcast.pipe.Ingress.number_of_ip.mod(f1=65535, REGISTER_INDEX=0)
bfrt.switcharoo_mcast.pipe.Ingress.n_packets_per_flow.mod(f1=2, REGISTER_INDEX=0)
bfrt.switcharoo_mcast.pipe.Ingress.max_port.mod(f1=65535, REGISTER_INDEX=0)
bfrt.switcharoo_mcast.pipe.Ingress.consecutive_flows_number.mod(f1=125, REGISTER_INDEX=0)
bfrt.switcharoo_mcast.pipe.Ingress.flows_repetition.mod(f1=4, REGISTER_INDEX=0)
```

- `base_flow_ip`: base flow IP to start the generation;
- `number_of_ip`: number of IPs to generate;
- `n_packets_per_flow`: number of packets per each flow;
- `max_port`: maximum L4 port value;
- `consecutive_flows_number`: number of consecutive flows before changing values;
- `flows_repetition`: number of repetitions for each consecutive flow.

### Configure Test Scripts

You need to define some variables in the `bash` scripts to run the tests.
In each `run_experiment_*.sh` file, you will find the following variables:
```bash
SERVER_USERNAME="user"
SERVER_USER_PASS="pass"
TOFINO_USERNAME="tofino"
TOFINO_USER_PASS="tofino"
SWITCHAROO_TOFINO_NAME="tofino32p"
MCAST_TOFINO_NAME="tofino64p"
GENERATOR_SERVER_NAME="nslrack25"

SWITCHAROO_PATH="/absolute/path/to/switcharoo"
MULTICAST_PATH="/absolute/path/to/switcharoo_mcast"
GENERATOR_PATH="/absolute/path/to/generator"

MULTICAST_TOFINO_SDE="/home/tofino/bf-sde-9.7.0"
SWITCHAROO_TOFINO_SDE="/home/tofino/bf-sde-9.8.0"
```

- `SERVER_USERNAME`: the Linux user on the server used as a generator;
- `SERVER_USER_PASS`: the user password on the server used as a generator;
- `TOFINO_USERNAME`: the Linux user on both Tofinos;
- `TOFINO_USER_PASS`: the user password on both Tofinos;
- `SWITCHAROO_TOFINO_NAME`: the name/IP of the Tofino where Switcharoo is installed;
- `MCAST_TOFINO_NAME`: the name/IP of the Tofino where `switcharoo_mcast` is installed;
- `GENERATOR_SERVER_NAME`: the name/IP of the server used as a generator;
- `SWITCHAROO_PATH`: path in the Tofino to the Switcharoo code and `setup.py` file;
- `MULTICAST_PATH`: path in the Tofino to the `switcharoo_mcast` code and `setup*.py` files;
- `GENERATOR_PATH`: path in the server where the FastClick scripts contained in the `generator` folder are located;
- `MULTICAST_TOFINO_SDE`: SDE path in the Tofino where `switcharoo_mcast` is installed;
- `SWITCHAROO_TOFINO_SDE`: SDE path in the Tofino where Switcharoo is installed.

## Run The Experiments

After configuring the project, you can run all the experiments by typing the following command:
```bash
sh run_all_experiments.sh
```

You can also run a single experiment by running the specific `run_experiment_*.sh` file. 

Check the content of the file for the specific parameters to pass.

## Plotting the results

After you gathered all the results, you can plot them by running the following command:
```bash
python3 plot.py <table_size_results> <table_size_no_ordering_results> <bloom_size_results> <throughput_results> <figures_path>
```

**NOTE**: For Figure 7 (`<table_size_no_ordering_results>`), you need to recompile Switcharoo by replacing the `bloom_pipe/bloom.p4` with the `bloom_pipe/bloom_no_ordering.p4` and recompile the program.
