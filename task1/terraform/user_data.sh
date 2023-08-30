#!/bin/bash

# Update and upgrade system packages
apt-get update -y && apt-get upgrade -y

# Install and enable SSH
apt-get install openssh-server -y
systemctl enable ssh
systemctl start ssh

# Install microk8s
snap install microk8s --classic
microk8s.start

# Add your user to the 'microk8s' group. Replace 'jenkins' with your actual username.
usermod -a -G microk8s ubuntu
newgrp microk8s

# Enable microk8s addons
microk8s.enable dashboard dns registry istio

# Configure kubectl for the user
microk8s.kubectl config view --raw > $HOME/.kube/config
