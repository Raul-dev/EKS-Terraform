#!/bin/bash
echo "vault" >> /home/ubuntu/vault.txt


sudo apt update
#sudo apt install openjdk-8-jdk -y
sudo apt-get update
#sudo apt install npm -y

curl -O https://releases.hashicorp.com/vault/1.2.2/vault_1.2.2_linux_amd64.zip

sudo apt-get install unzip

unzip vault_1.2.2_linux_amd64.zip

sudo mv vault /usr/local/bin

vault -autocomplete-install

complete -C /usr/local/bin/vault vault
#-- configure
sudo mkdir /etc/vault
sudo mkdir -p /var/lib/vault/data
sudo useradd --system --home /etc/vault --shell /bin/false vault
sudo chown -R vault:vault /etc/vault /var/lib/vault/

cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault/config.hcl

[Service]
User=vault
Group=vault
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill --signal HUP 
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitBurst=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

touch /etc/vault/config.hcl

cat <<EOF | sudo tee /etc/vault/config.hcl
disable_cache = true
disable_mlock = true
ui = true
listener "tcp" {
   address          = "0.0.0.0:8200"
   tls_disable      = 1
}
storage "file" {
   path  = "/var/lib/vault/data"
 }
api_addr         = "http://0.0.0.0:8200"
max_lease_ttl         = "10h"
default_lease_ttl    = "10h"
cluster_name         = "vault"
raw_storage_endpoint     = true
disable_sealwrap     = true
disable_printable_check = true
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now vault

systemctl status vault

#Replace 127.0.0.1 with Vault Server IP address.
export VAULT_ADDR="http://127.0.0.1:8200"
echo "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bashrc

#export VAULT_ADDR="http://3.15.210.61:8200"
# $env:VAULT_ADDR = "http://3.15.210.61:8200"    
	
sudo rm -rf  /var/lib/vault/data/*
vault operator init > /etc/vault/init.file

#Test HTTP API endpoint using curl to check initialization status.
#curl http://127.0.0.1:8200/v1/sys/init

##cat /etc/vault/init.file
#export VAULT_TOKEN="s.VntKBnA3SND5jGy5X1zFhkt9"
# $env:VAULT_TOKEN="s.VntKBnA3SND5jGy5X1zFhkt9"

#vault auth enable approle

#https://learn.hashicorp.com/vault/secrets-management/sm-versioned-kv#cli-command
#* tune of path "secret/" failed: no mount entry found

exit 0





