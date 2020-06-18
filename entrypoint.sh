#!/bin/bash

DOCTL_VERSION=1.45.1

# Deployment repository
git clone https://${INPUT_USERNAME}:${INPUT_PASSWORD}@github.com/WeDevCompany/deployment.git -b ${INPUT_BRANCH} ~/deployment
cd ~/deployment

# obtain env from API and convert
bash json-to-env.sh

# env
DIGITAL_OCEAN_API_KEY=$(grep -w DIGITAL_OCEAN_API_KEY .env | cut -d '=' -f2);
SSH_BACKUP_DIR=$(grep -w SSH_BACKUP_DIR .env | cut -d '=' -f2);
SSH_STORE_TOKEN=$(grep -w SSH_STORE_TOKEN .env | cut -d '=' -f2);
SSH_EMAIL=$(grep -w SSH_EMAIL .env | cut -d '=' -f2);
SSH_BACKUP_DIR=$(grep -w SSH_BACKUP_DIR .env | cut -d '=' -f2);
SSH_FILENAME=$(grep -w SSH_FILENAME .env | cut -d '=' -f2);
SERVER_TIMEZONE=$(grep -w SERVER_TIMEZONE .env | cut -d '=' -f2);
SERVER_SNAPSHOT_ID=$(grep -w SERVER_SNAPSHOT_ID .env | cut -d '=' -f2);

# DOCTL
curl -L https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz  | tar xz
mv doctl /usr/local/bin
doctl auth init -t $DIGITAL_OCEAN_API_KEY

# Generate ssh key in docker
mkdir ~/.ssh
ssh-keygen -t rsa -b 4096 -C "${SSH_EMAIL}" -f ~/.ssh/id_rsa -q -N ""
eval "$(ssh-agent)"
echo $SSH_AUTH_SOCK
ssh-add ~/.ssh/id_rsa

# Adding ssh key to digital ocean
SSH_NAME=docker-$(date +%s%N)
doctl compute ssh-key create $SSH_NAME --public-key "$(cat ~/.ssh/id_rsa.pub)"
echo "Store the droplet expire time in the .env: $SSH_NAME";
sed -i "/SSH_NAME=/c SSH_NAME=${SSH_NAME}" .env;

# Change timezone droplet
echo "Change timezone docker to $SERVER_TIMEZONE"
sh -c "ln -snf /usr/share/zoneinfo/$SERVER_TIMEZONE /etc/localtime && echo $SERVER_TIMEZONE > /etc/timezone"

# Start and configurate server
bash droplet_deploy.sh

# Delete droplet ssh-key from digital ocean
ID_FINGERPRINT=$(doctl compute ssh-key list --format ID,FingerPrint,Name | grep -w "$SSH_NAME" | awk '{print$1}')
doctl compute ssh-key delete $ID_FINGERPRINT -f
echo "Delete fingerprint $ID_FINGERPRINT from digital ocean"