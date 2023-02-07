#!/bin/bash

# -d: data size
# -c -t : client and thread per client


# for quick data loading
# --ratio=4:0 --pipeline=40


# optional for OSS cluster API
# --cluster-mode


memtier_benchmark --ratio=4:0 --test-time=3600 \
 -d 150 \
 -t 12 -c 10 \
 --key-pattern=P:P \
 --key-maximum=20000000 \
 --hide-histogram -x 1000 \
 -a adminRL123 \
 --pipeline=40 \
 -s redis-12000.cluster.avasseur-default.demo.redislabs.com -p 12000

