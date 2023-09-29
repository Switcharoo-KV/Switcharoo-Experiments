# Switcharoo Experiments
This repository contains the evaluation scripts used to measure Switcharoo performance.

## Repository Organization

This repository contains:
- `generator`: [FastClick](https://github.com/tbarbette/fastclick) elements and scripts used to generate traffic towards a Tofino switch;
- `switcharoo_mcast`: P4 program that takes incoming packets, manipulates their flow tuple to generate synthetic flows using some configuration paramters and multicast them towards Switcharoo;
- `tests`: evaluation scripts and results plotter.

The experiments require two Tofino switches and an external server that acts as a traffic generator and measurements gatherer.

### Traffic Generator

The traffic generator uses [FastClick](https://github.com/tbarbette/fastclick), in particular, it needs some additional elements to be compiled inside the vanilla version.

After pulling the FastClick repository, copy the `generator/elements` folder inside the root folder of FastClick and then build the project. You can find additional information on how to build it on the [official repository](https://github.com/tbarbette/fastclick).

### Multicast P4 Program

You need a Tofino to build and run the `switcharoo_mcast` program. This Tofino switch should be connected with some ports to the Switcharoo Tofino. The default configuration uses four ports.

To build the code, use the following command:
```bash 
./p4_build.sh /path/to/switcharoo_mcast.p4
```

### Tests

In this folder, you will find both the `bash` scripts to run the paper experiments and a `plot.py` to plot all the figures of the paper. 

The `plot.py` requires `matplotlib`:
```bash
python3 -m pip install matplotlib
```

## Configuration

### Change the FastClick directory

You need to specify the FastClick installation directory in the `gen-rated-mt-lat.sh` file.

Open the `gen-rated-mt-lat.sh` file with an editor and change the `/path/to/fastclick` with the root folder of the compiled FastClick.

### Change Ports in `switcharoo_mcast`

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

You can also run a single experiment by running the specific `run_experiment_*.sh` file. Check the content of the file for the specific parameters to pass.

## Plotting the results

After you gathered all the results, you can plot them by running the following command:
```bash
python3 plot.py <table_size_results> <bloom_size_results> <throughput_results> <figures_path>
```