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