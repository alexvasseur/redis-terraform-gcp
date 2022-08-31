#!/bin/bash

rladmin tune proxy all max_threads 32
rladmin tune proxy all threads 32
rladmin tune cluster default_shards_placement sparse
rladmin tune cluster redis_upgrade_policy latest
rladmin tune cluster default_redis_version 6.2
#TODO slave HA recovery