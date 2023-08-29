#!/bin/bash
# Update the system
apt-get update
apt-get install -y openjdk-17-jdk ansible

# Ensure the .ssh directory exists
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh

# Generate an RSA key pair only if it doesn't already exist
if [ ! -f /home/ubuntu/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa -N ""
fi

# Set proper permissions and ownership
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/id_rsa
chmod 644 /home/ubuntu/.ssh/id_rsa.pub

# Embed the Jenkins public key
echo "sec_com_ass_key_pair" >> /home/ubuntu/.ssh/authorized_keys

# Set proper permissions for the authorized_keys file
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Specify the desired directory
TARGET_DIR="/var/lib/jenkins/workspace/sec_comp_pipline/zino_sec_comp_take_home/task1/terraform"

# Check if the directory exists, if not create it
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
fi

# Copy the id_rsa.pub file to the target directory
# Ensure that the source path is correct for your setup.
# In this example, it's assumed that the public key is present in the default .ssh directory of the user.
cp ~/.ssh/id_rsa.pub "$TARGET_DIR/"

# Rest of your script logic, if any...

apt update && apt upgrade -y
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
