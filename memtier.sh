#!/bin/bash

# -d: data size
# -c -t : client and thread per client

if [ "$1" == "" ]
then
        echo "$0 <auth>"
        exit 0
fi

memtier_benchmark --ratio=1:4 --test-time=3600 \
 -a $1 \
 -d 150 \
 -t 8 -c 2 \
 --pipeline=30 --key-pattern=S:S \
 --key-maximum=2000 \
 --hide-histogram -x 1000 \
 -s redis-16798.cluster.avasseur.demo.redislabs.com -p 16798