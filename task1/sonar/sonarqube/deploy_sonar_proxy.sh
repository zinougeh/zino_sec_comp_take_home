#!/bin/bash

# Ensure the script fails on any error
set -e

# 1. Install Nginx if it's not already installed
if ! command -v nginx &> /dev/null; then
    sudo apt update
    sudo apt install -y nginx
fi

# 2. Place nginx-sonar-config.conf into /etc/nginx/sites-available/
cat <<EOL > /etc/nginx/sites-available/nginx-sonar-config.conf
server {
    listen 80;
    server_name _; # This placeholder will be replaced with the public IP

    location / {
        proxy_pass http://localhost:30080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOL

# 3. Fetch the public IP and update Nginx configuration
PUBLIC_IP=$(curl -s http://ifconfig.me)
CONFIG_PATH="/etc/nginx/sites-available/nginx-sonar-config.conf"
sed -i "s/server_name _;/server_name $PUBLIC_IP;/g" $CONFIG_PATH

# 4. Link to sites-enabled (if not done before)
ln -sfn $CONFIG_PATH /etc/nginx/sites-enabled/

# 5. Reload Nginx
sudo systemctl reload nginx

echo "Deployment completed!"
