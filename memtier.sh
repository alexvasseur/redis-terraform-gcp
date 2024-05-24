#!/bin/bash

if [ "$1" == "" ] 
then
        echo Usage: $0 <database_ip:port >&2
        exit 1
fi

IP=${1%%:*}
PORT=${1##*:}

## Usefull arguments
# -d xxx: data size
# -c xxx -t xxx: client and thread per client
# for quick data loading
#       --ratio 4:0 --pipeline 40
# for OSS cluster API
# --cluster-mode
# --rate-limiting xxx
#       approximate rate limiting per connection or shard

memtier_benchmark --ratio 4:0 \
 --test-time 3600 \
 -d 150 \
 --key-pattern P:P \
 --key-maximum=20000000 \
 --hide-histogram -x 1000 \
 --pipeline 40 \
 -s ${IP} -p ${PORT} \
 -t 12 -c 10 --rate-limiting 2000
