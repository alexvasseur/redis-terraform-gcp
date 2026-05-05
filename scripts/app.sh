#!/bin/bash

MEMVIZ_ENABLED="${memviz_enabled}"
MEMVIZ_PORT="${memviz_port}"
MEMVIZ_REPO_URL="${memviz_repo_url}"
MEMVIZ_REPO_REF="${memviz_repo_ref}"

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
## we are getting the main latest
## if unstable change to
## wget -O memtier.tar.gz https://github.com/RedisLabs/memtier_benchmark/archive/refs/tags/2.2.0.tar.gz
wget -O memtier.tar.gz https://github.com/RedisLabs/memtier_benchmark/archive/refs/heads/master.tar.gz
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

if [ "$MEMVIZ_ENABLED" = "true" ]; then
  apt-get install -y curl ca-certificates gnupg git

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
  apt-get -y update
  apt-get install -y nodejs

  install -d -o ubuntu -g ubuntu /opt
  if [ ! -d /opt/memviz/.git ]; then
    rm -rf /opt/memviz
    sudo -u ubuntu git clone "$MEMVIZ_REPO_URL" /opt/memviz
  fi

  cd /opt/memviz
  sudo -u ubuntu git remote set-url origin "$MEMVIZ_REPO_URL"
  sudo -u ubuntu git fetch --all --tags
  if sudo -u ubuntu git show-ref --verify --quiet "refs/remotes/origin/$MEMVIZ_REPO_REF"; then
    sudo -u ubuntu git checkout -B "$MEMVIZ_REPO_REF" "origin/$MEMVIZ_REPO_REF"
  else
    sudo -u ubuntu git checkout "$MEMVIZ_REPO_REF"
  fi
  sudo -u ubuntu npm install
  sudo -u ubuntu npm run build

  cat >/etc/systemd/system/memviz.service <<EOF
[Unit]
Description=memviz
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/memviz
Environment=NODE_ENV=production
Environment=PORT=$MEMVIZ_PORT
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable memviz
  systemctl restart memviz
fi
