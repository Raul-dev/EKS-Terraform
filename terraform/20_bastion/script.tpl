#!/bin/bash
sleep 1m
sudo su - root

sudo apt-get -y update && sudo apt-get -y upgrade
sudo apt install -y awscli
sudo apt-get install -y apache2

mkdir /tmp/ssm
cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent

#NFS 
#RH6: sudo apt install nfs-utils
#Ubuntu: sudo apt install nfs-common
#sudo mkdir -p ~/efs-mount-point
#sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 172.31.3.74:/   ~/efs-mount-point  