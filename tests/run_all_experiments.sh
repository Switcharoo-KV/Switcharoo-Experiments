#!/bin/bash

sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 600000 -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 1200000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 1800000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2400000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 3000000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 1800000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2100000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2400000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2700000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 3000000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2190000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2400000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2650000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2790000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 3000000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2400000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2600000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2700000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 2790000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c avg -r 3000000  -m 4 -s 32768
sleep 5

sh run_experiment_throughput.sh -p res-throughput/ -c best -r 600000 -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 1200000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 1800000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2400000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 3000000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 1800000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2100000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2400000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2700000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 3000000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2190000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2400000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2650000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2790000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 3000000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2400000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2600000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2700000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 2790000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c best -r 3000000  -m 4 -s 32768
sleep 5

sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 600000 -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 1200000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 1800000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2400000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 3000000  -m 1 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 1800000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2100000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2400000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2700000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 3000000  -m 2 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2190000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2400000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2650000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2790000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 3000000  -m 3 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2400000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2600000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2700000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 2790000  -m 4 -s 32768
sleep 5
sh run_experiment_throughput.sh -p res-throughput/ -c worst -r 3000000  -m 4 -s 32768
sleep 5

sh run_experiment_tablesize.sh -p all-tablesize/ -c worst -r 2600000
sleep 5
sh run_experiment_tablesize.sh -p all-tablesize/ -c avg -r 2600000
sleep 5
sh run_experiment_tablesize.sh -p all-tablesize/ -c best -r 2600000
sleep 5

sh run_experiment_bloomsize.sh -p all-bloomsize/ -c worst -r 2600000
sleep 5
sh run_experiment_bloomsize.sh -p all-bloomsize/ -c avg -r 2600000
sleep 5
sh run_experiment_bloomsize.sh -p all-bloomsize/ -c best -r 2600000
sleep 5

sh run_experiment_expiration.sh -p all-expirations/ -c worst -r 2600000
sleep 5
sh run_experiment_expiration.sh -p all-expirations/ -c avg -r 2600000
sleep 5
sh run_experiment_expiration.sh -p all-expirations/ -c best -r 2600000
sleep 5
