#!/bin/bash

# ./curl.sh password file.json

curl -X POST \
  https://cluster.avasseur-default.demo.redislabs.com:9443/v1/bdbs \
  -H 'Content-Type:application/json' \
  -u admin@redis.io:$1 \
  -d @$2 \
  -k

