#!/bin/bash
echo "elk" >> /home/ubuntu/slave.txt


sudo apt update
#sudo apt install openjdk-8-jdk -y
sudo apt-get update
#sudo apt install npm -y

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$PATH:$JAVA_HOME

### Linux(CentOs)
#https://www.elastic.co/guide/en/elasticsearch/reference/current/getting-started-install.html
#curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.0-linux-x86_64.tar.gz
#tar -xvf elasticsearch-6.7.0-linux-x86_64.tar.gz
#cd elasticsearch-6.7.0/bin
#./elasticsearch


### debian (ubuntu)
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.0-amd64.deb
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.0-amd64.deb.sha512
shasum -a 512 -c elasticsearch-7.1.0-amd64.deb.sha512 
lsof /var/lib/dpkg/lock > testlock.txt
sleep 20
sudo dpkg -i elasticsearch-7.1.0-amd64.deb

echo "
-Xms256m 
-Xmx256m 
" > myjvm.options
sudo cp /etc/elasticsearch/jvm.options jvm.options
sudo cp myjvm.options /etc/elasticsearch/jvm.options 

sudo sh -c " echo 'network.bind_host: 0.0.0.0
node.master: true
node.data: true
transport.host: localhost
transport.tcp.port: 9300
' >> /etc/elasticsearch/elasticsearch.yml "


sudo service elasticsearch start
#sudo nano /etc/elasticsearch/elasticsearch.yml
#curl -X GET "172.31.2.15:9200"
#curl -X GET "localhost:9200"

#install kibana (ubuntu)
wget https://artifacts.elastic.co/downloads/kibana/kibana-7.1.0-amd64.deb
shasum -a 512 kibana-7.1.0-amd64.deb
sudo dpkg -i kibana-7.1.0-amd64.deb
sudo cp myjvm.options /etc/kibana/jvm.options

sudo sh -c " echo 'server.host: 0.0.0.0
' >> /etc/kibana/kibana.yml"

#sudo systemctl start kibana.service
sudo service kibana start
#sudo service kibana status
#curl -X GET "172.31.2.15:5601/status"
#curl -X GET "localhost:5601/status"

exit 0





