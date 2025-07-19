#!/bin/bash
set -e

# 1. Update and install required packages
apt update -y
apt install -y nginx nfs-common

# 2. Remove default NGINX config
unlink /etc/nginx/sites-enabled/default || true

# 3. Create new NGINX site config
cat <<'NGINXCONF' > /etc/nginx/sites-available/eleti.site
server {
    listen 80;
    listen [::]:80;
    server_name eleti.site;

    root /var/www/eleti.site;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
NGINXCONF

# Enable new site
ln -s /etc/nginx/sites-available/eleti.site /etc/nginx/sites-enabled/

# 4. Create web root and mount EFS (replace with your actual EFS ID & Region)
mkdir -p /var/www/eleti.site
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0b08ef45d69a4e3e7.efs.us-east-1.amazonaws.com:/ /var/www/eleti.site

# 5. Start and enable NGINX
systemctl restart nginx
systemctl enable nginx

