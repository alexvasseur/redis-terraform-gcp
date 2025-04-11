#!/bin/bash

## commons

apt-get -y update
apt-get -y install vim
apt-get -y install iotop
apt-get -y install iputils-ping

apt-get install -y netcat
apt-get install -y dnsutils
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

## memtier (this will install it for all users)
mkdir /home/ubuntu/install
cd /home/ubuntu/install
apt-get -y install build-essential autoconf automake libpcre3-dev libevent-dev pkg-config zlib1g-dev libssl-dev
wget -O memtier.tar.gz https://github.com/RedisLabs/memtier_benchmark/archive/refs/tags/2.1.0.tar.gz
tar xfz memtier.tar.gz
mv memtier_benchmark-* memtier
pushd memtier
 autoreconf -ivf
 ./configure
 make
 make install
popd

echo "${nodes}" >> install.log
echo "${cluster_dns_suffix}" >> install.log
#TODO /etc/hosts

## on Ubuntu22 we need libssl for redis-server and redis-stack-server to run
wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

## redis-benchmark and redis-cli
wget -O redis-stack.tar.gz https://packages.redis.io/redis-stack/redis-stack-server-7.2.0-v10.bionic.x86_64.tar.gz
tar xfz redis-stack.tar.gz
mv redis-stack-* redis-stack
mkdir -p /home/ubuntu/.local/bin
ln -s /home/ubuntu/install/redis-stack/bin/redis-benchmark /home/ubuntu/.local/bin/redis-benchmark
ln -s /home/ubuntu/install/redis-stack/bin/redis-cli /home/ubuntu/.local/bin/redis-cli

## utility scripts from the Git repo ./scripts folder
apt-get -y install unzip
wget https://github.com/alexvasseur/redis-terraform-gcp/archive/refs/heads/main.zip
unzip main.zip
mv redis-terraform-gcp-main/scripts/ .
chmod u+x scripts/*.sh

# for "sudo su - ubuntu"
chown -R ubuntu:ubuntu /home/ubuntu/install
chown -R ubuntu:ubuntu /home/ubuntu/.local
