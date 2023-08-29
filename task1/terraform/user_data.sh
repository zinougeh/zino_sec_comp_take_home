#!/bin/bash

# Update package lists for upgrades and new package installations
apt-get update

# Upgrade the instance with the latest patches
apt-get upgrade -y

# Ensure the SSH server is installed (it typically is by default)
apt-get install -y openssh-server

# Ensure that SSH is set to start on boot
systemctl enable ssh

# Start the SSH service just in case it's not running
systemctl start ssh

# Optional: Install and set up any additional software or tools if required. For example:
# apt-get install -y apache2
# systemctl enable apache2
# systemctl start apache2
