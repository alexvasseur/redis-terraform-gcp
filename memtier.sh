#!/bin/bash

## Not really a shell script as most of it is hardcoded right now.
## TODO - change to doc.


## Usefull arguments
# -d xxx: data size
# -c xxx -t xxx: client and thread per client
# for quick data loading
#       --ratio 4:0 --pipeline 40
# for OSS cluster API
# --cluster-mode
# --rate-limiting xxx
#       approximate rate limiting per connection or shard



#### Good example

## 20 millions keys x 1kB = 20 GB (of primary data)
memtier_benchmark --ratio 1:4 \
 --test-time 3600 \
 -d 1000 \
 --key-pattern P:P \
 --key-maximum=20000000 \
 --hide-histogram -x 1000 \
 --pipeline 1 \
 -s redis-12000.cluster.avasseur-default.demo.redislabs.com -p 12000 \
 -a adminRL123 \
 --cluster-mode \
 -t 20 -c 10 \
 --rate-limiting 100
 
# Run same as above without the --rate-limiting

# Run same as above and change pipeline to 50



#### Other example
 
## Load 3 millions keys x 3kB = 9 GB (of replicas data)
memtier_benchmark --ratio 1:4 \
 --test-time 20 \
 -d 3000 \
 --key-pattern P:P \
 --key-maximum=600000 \
 --hide-histogram -x 1 \
 --pipeline 1 \
 -s redis-12000.cluster.avasseur-default.demo.redislabs.com -p 12000 \
 -a adminRL123 \
 --cluster-mode \
 -t 20 -c 5 --rate-limiting 100


