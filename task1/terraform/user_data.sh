#!/bin/bash
set -ex

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update and upgrade system packages
sudo apt-get update -y && apt-get upgrade -y

# Install and enable SSH
sudo apt-get install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Install IP Tables and set up forwarding rules
sudo apt update
sudo apt install iptables iptables-persistent
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 30080
sudo sh -c "iptables-save > /etc/iptables/rules.v4"

# Create user and set up SSH for it
sudo useradd jenkins -m -s /bin/bash
sudo mkdir -p /home/jenkins/.ssh
echo "${ssh_public_key}" | sudo tee /home/jenkins/.ssh/authorized_keys
sudo chown -R jenkins:jenkins /home/jenkins/.ssh
sudo chmod 700 /home/jenkins/.ssh
sudo chmod 600 /home/jenkins/.ssh/authorized_keys
mkdir -p /home/ubuntu/.ssh
echo "${ssh_public_key}" >> /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Update SSHD Config for security
sudo sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sudo service sshd restart

# Allow jenkins user to have passwordless sudo capabilities
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

# Install microk8s and configure
sudo snap install microk8s --classic
sudo microk8s.start
sudo microk8s.enable dashboard dns registry istio
sudo usermod -a -G microk8s ubuntu
sudo microk8s.kubectl config view --raw > $HOME/.kube/config
