#!/bin/bash

# Update the system
apt-get update && apt-get upgrade -y
apt-get install -y openjdk-17-jdk ansible openssh-server

# Start and enable SSH
systemctl start ssh
systemctl enable ssh

# ... [Rest of the logic, if you want to keep commented-out lines, else you can remove them]
