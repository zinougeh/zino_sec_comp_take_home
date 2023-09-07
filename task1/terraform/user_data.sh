#!/bin/bash

set -e

#Update and upgrade system packages
sudo apt-get update -y && apt-get upgrade -y

#Install and enable SSH
sudo apt-get install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

#Install IP Tables
sudo apt update
sudo apt install iptables

#To make rules persist after a reboot
sudo apt install iptables-persistent


#This command will forward all incoming traffic on port 80 to port 30080
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080

#To save the current iptables rules
sudo sh -c "iptables-save > /etc/iptables/rules.v4"


# Create user and its home directory
sudo useradd jenkins -m

# Ensure the .ssh directory exists for both users
sudo mkdir -p /home/ubuntu/.ssh
sudo mkdir -p /home/jenkins/.ssh

# Append the SSH public key to the authorized_keys of the Ubuntu user
echo "${ssh_public_key}" | sudo tee -a /home/ubuntu/.ssh/authorized_keys
echo "${ssh_public_key}" | sudo tee -a /home/jenkins/.ssh/authorized_keys
echo "${ssh_public_key} jenkins" >> /home/jenkins/.ssh/authorized_keys

# Setup SSH for jenkins user

sudo chown -R jenkins:jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chmod 600 /home/jenkins/.ssh/authorized_keys

# Allow jenkins user to have passwordless sudo capabilities
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

# Ensure that PasswordAuthentication is set to no for sshd_config
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sudo sed -i "s/#AuthorizedKeysFile/AuthorizedKeysFile/g" /etc/ssh/sshd_config
sudo service sshd restart

# Set correct permissions
sudo chmod 700 /home/ubuntu/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
sudo chmod 600 /home/jenkins/.ssh/authorized_keys

#Install microk8s
sudo snap install microk8s --classic
sudo microk8s.start

# Enable microk8s addons
sudo microk8s.enable dashboard dns registry istio

#Add the Ubuntu user to the 'microk8s' group
sudo usermod -a -G microk8s ubuntu

# Configure kubectl for the user
sudo microk8s.kubectl config view --raw > $HOME/.kube/config

