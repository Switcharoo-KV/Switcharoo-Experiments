#!/bin/bash

/path/to/fastclick/bin/click --dpdk -l 0-15 -a 3b:00.1  -- gen-rated-mt-lat.click $@
