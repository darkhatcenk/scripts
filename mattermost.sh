#!/bin/bash
dnf update -y
dnf install -y epel-release wget jq curl postgresql postgresql-server nginx
postgresql-setup --initdb --unit postgresql
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql -c "CREATE DATABASE mattermost;"
sudo -u postgres psql -c "CREATE USER mmuser WITH PASSWORD 'mmuser-password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mattermost TO mmuser;"
mkdir -p /opt/mattermost
cd /tmp
wget https://releases.mattermost.com/7.8.1/mattermost-7.8.1-linux-amd64.tar.gz
tar -xf mattermost-7.8.1-linux-amd64.tar.gz
mv mattermost/* /opt/mattermost/
rm -rf mattermost mattermost-7.8.1-linux-amd64.tar.gz
useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost
cd /opt/mattermost
cp config/config.json config/config.original.json
sed -i 's/"DriverName": "mysql"/"DriverName": "postgres"/g' config/config.json
sed -i 's/"DataSource": "mmuser:mostest@tcp(localhost:3306)\/mattermost?charset=utf8mb4,utf8\u0026readTimeout=30s\u0026writeTimeout=30s"/"DataSource": "postgres:\/\/mmuser:mmuser-password@localhost:5432\/mattermost?sslmode=disable\u0026connect_timeout=10"/g' config/config.json

cat > /etc/systemd/system/mattermost.service << 'EOL'
[Unit]
Description=Mattermost
After=network.target postgresql.service

[Service]
Type=notify
User=mattermost
Group=mattermost
ExecStart=/opt/mattermost/bin/mattermost
Restart=always
WorkingDirectory=/opt/mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
EOL

cat > /etc/nginx/conf.d/mattermost.conf << 'EOL'
server {
    listen 80;
    server_name _;

    location ~ /api/v[0-9]+/(users/)?websocket$ {
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:8065;
    }

    location / {
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:8065;
    }
}
EOL

systemctl daemon-reload
systemctl enable mattermost nginx
systemctl start mattermost nginx

if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --reload
fi

echo "Mattermost installation complete!"
echo "Access Mattermost at http://YOUR_SERVER_IP"

