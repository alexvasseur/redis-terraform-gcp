#!/bin/bash

# -d: data size
# -c -t : client and thread per client

memtier_benchmark --ratio=1:4 --test-time=3600 \
 -d 150 \
 -t 12 -c 10 \
 --key-pattern=S:S \
 --key-maximum=2000 \
 --hide-histogram -x 1000 \
 -a pass \
 --pipeline=1 \
 -s redis-12000.cluster.avasseur.demo.redislabs.com -p 12000
