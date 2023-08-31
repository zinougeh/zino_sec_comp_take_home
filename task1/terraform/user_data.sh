#!/bin/bash

#Update and upgrade system packages
sudo apt-get update -y && apt-get upgrade -y

#Install and enable SSH
sudo apt-get install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

#Install microk8s
sudo snap install microk8s --classic
sudo microk8s.start

#Add the Ubuntu user to the 'microk8s' group
sudo usermod -a -G microk8s ubuntu

# Enable microk8s addons
sudo microk8s.enable dashboard dns registry istio
# Configure kubectl for the user
sudo microk8s.kubectl config view --raw > $HOME/.kube/config

# Set correct permissions
sudo chmod 700 /home/ubuntu/.ssh

# Append the SSH public key to the authorized_keys of the Ubuntu user
sudo echo "${ssh_public_key}" >> /home/ubuntu/.ssh/authorized_keys

# Set correct permissions for the authorized_keys file
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
