#!/bin/bash

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


# create user for installations
sudo useradd /home/jenkins

# Append the SSH public key to the authorized_keys of the Ubuntu user
sudo echo "${ssh_public_key}" >> /home/ubuntu/.ssh/authorized_keys

# Append the SSH public key to the authorized_keys of the Ubuntu user
sudo echo "${ssh_public_key}" >> /home/jenkins/.ssh/authorized_keys

# Set correct permissions
sudo chmod 700 /home/ubuntu/.ssh

# Set correct permissions for the authorized_keys file
sudo chmod 600 /home/ubuntu/.ssh/authorized_keys

# Set correct permissions
sudo chmod 700 /home/jenkins/.ssh

# Set correct permissions for the authorized_keys file
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

