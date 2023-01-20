#!/bin/bash

# ./curl.sh $PASS file.json

URI="v1/bdbs"
if [ $2 = "db_crdb.json" ]
then
  URI="v1/crdbs"
fi
echo $URI


curl -X POST \
  https://cluster.avasseur-default.demo.redislabs.com:9443/$URI \
  -H 'Content-Type:application/json' \
  -u admin@redis.io:$1 \
  -d @$2 \
  -k

