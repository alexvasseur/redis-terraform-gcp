#!/bin/bash

################
# PREREQ 


echo "$(date) - PREPARING machine node" >> /home/ubuntu/install.log

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

# cloud instance have no swap anyway
#swapoff -a
#sed -i.bak '/ swap / s/^(.*)$/#1/g' /etc/fstab
echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
mv /etc/resolv.conf /etc/resolv.conf.orig
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
service systemd-resolved restart
sysctl -w net.ipv4.ip_local_port_range="40000 65535"
echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

echo "$(date) - PREPARE done" >> /home/ubuntu/install.log

################
# RS

echo "$(date) - INSTALLING Redis Enterprise" >> /home/ubuntu/install.log

mkdir /home/ubuntu/install
wget "${RS_release}" -P /home/ubuntu/install
tar xvf /home/ubuntu/install/redislabs*.tar -C /home/ubuntu/install

echo "$(date) - INSTALLING Redis Enterprise - silent installation" >> /home/ubuntu/install.log

cd /home/ubuntu/install
sudo /home/ubuntu/install/install.sh -y 2>&1 >> /home/ubuntu/install_rs.log
sudo adduser ubuntu redislabs

echo "$(date) - INSTALL done" >> /home/ubuntu/install.log

################
# FLASH
if [ $(lsblk | grep nvme0n1 | wc -l) -eq 1 ]; then
    echo "$(date) - SETTING UP Redis on Flash NVMe disks" >> /home/ubuntu/install.log
    mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/nvme0n1 /dev/nvme0n2
    mkfs.ext4 -F /dev/md0
    mkdir -p /mnt/nvme
    mount /dev/md0 /var/opt/redislabs/flash/
    chmod a+w /var/opt/redislabs/flash/
    apt-get install -y fio util-linux
    # fio --name=writefile --size=100G --filesize=100G --filename=/var/opt/redislabs/flash/fio --bs=1M --nrfiles=1 --direct=1 --sync=0 --randrepeat=0 --rw=write --refill_buffers --end_fsync=1 --iodepth=200 --ioengine=libaio
    # fio --time_based --name=benchmark --size=100G --runtime=30 --filename=/dev/md0 --ioengine=libaio --randrepeat=0 --iodepth=128 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=32 --rw=randread --blocksize=4k --group_reporting --norandommap
    # fio --time_based --name=benchmark --size=100G --runtime=30 --filename=/dev/md0 --ioengine=libaio --randrepeat=0 --iodepth=128 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=32 --rw=randwrite --blocksize=4k --group_reporting --norandommap

    # see also for remount upon restart
    # https://cloud.google.com/compute/docs/disks/add-local-ssd#gcloud
fi

################
# NODE

node_external_addr=`curl ifconfig.me/ip`
echo "Node ${node_id} : $node_external_addr" >> /home/ubuntu/install.log
if [ ${node_id} -eq 1 ]; then
    echo "create cluster" >> /home/ubuntu/install.log
    echo "rladmin cluster create name ${cluster_dns} username ${RS_admin} password '${RS_password}' external_addr $node_external_addr flash_enabled " >> /home/ubuntu/install.log
    /opt/redislabs/bin/rladmin cluster create name ${cluster_dns} username ${RS_admin} password '${RS_password}' external_addr $node_external_addr flash_enabled 2>&1 >> /home/ubuntu/install.log
else
    echo "joining cluster " >> /home/ubuntu/install.log
    echo "/opt/redislabs/bin/rladmin cluster join username ${RS_admin} password '${RS_password}' nodes ${node_1_ip} external_addr $node_external_addr flash_enabled replace_node ${node_id}" >> /home/ubuntu/install.log
    for i in {1..10}
    do
	    /opt/redislabs/bin/rladmin cluster join username ${RS_admin} password '${RS_password}' nodes ${node_1_ip} external_addr $node_external_addr flash_enabled replace_node ${node_id} 2>&1 >> /home/ubuntu/install.log
    	if [ $? -eq 0 ]; then
	        break
    	else
            echo "master node not available, trying again in 30s..."  >> /home/ubuntu/install.log
	        sleep 30
    	fi
    done
fi
echo "$(date) - DONE creating cluster node" >> /home/ubuntu/install.log

################
# NODE external_addr - it runs at each reboot to update it
echo "${node_id}" > /home/ubuntu/node_index.terraform
cat <<EOF > /home/ubuntu/node_externaladdr.sh
#!/bin/bash
node_external_addr=\$(curl -s ifconfig.me/ip)

# Terraform node_id may not be Redis Enterprise node id
myip=\$(ifconfig | grep 10.26 | cut -d' ' -f10)
rs_node_id=\$(/opt/redislabs/bin/rladmin info node all | grep -1 \$myip | grep node | cut -d':' -f2)
/opt/redislabs/bin/rladmin node \$rs_node_id external_addr set \$node_external_addr
EOF
chown ubuntu /home/ubuntu/node_externaladdr.sh
chmod u+x /home/ubuntu/node_externaladdr.sh
/home/ubuntu/node_externaladdr.sh

echo "$(date) - DONE updating RS external_addr" >> /home/ubuntu/install.log