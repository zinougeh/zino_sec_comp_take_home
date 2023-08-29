#!/bin/bash
apt update && apt upgrade -y
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh
