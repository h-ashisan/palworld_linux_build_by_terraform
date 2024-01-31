#!/bin/bash

sudo yum update -y

## Install git
sudo yum install -y git

## Install docker
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo yum install -y docker
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
sudo systemctl enable docker

## Install docker-compose
VER=2.5.1
sudo curl \
-L https://github.com/docker/compose/releases/download/v${VER}/docker-compose-$(uname -s)-$(uname -m) \
-o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
sudo ln -s /usr/local/lib/docker/cli-plugins/docker-compose /usr/bin/docker-compose