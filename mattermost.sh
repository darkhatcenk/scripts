#!/bin/bash
# Mattermost Installation Script

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install necessary dependencies
echo "Installing dependencies..."
dnf install -y epel-release
dnf install -y wget jq curl postgresql postgresql-server nginx

# Initialize PostgreSQL database
echo "Initializing PostgreSQL database..."
postgresql-setup --initdb --unit postgresql
systemctl enable postgresql
systemctl start postgresql

# Create Mattermost database and user
echo "Setting up PostgreSQL for Mattermost..."
sudo -u postgres psql -c "CREATE DATABASE mattermost;"
sudo -u postgres psql -c "CREATE USER mmuser WITH PASSWORD 'mmuser-password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mattermost TO mmuser;"

# Download and install Mattermost
echo "Downloading Mattermost..."
mkdir -p /opt/mattermost
cd /tmp
wget https://releases.mattermost.com/7.8.1/mattermost-7.8.1-linux-amd64.tar.gz
tar -xf mattermost-7.8.1-linux-amd64.tar.gz
mv mattermost/* /opt/mattermost/
rm -rf mattermost mattermost-7.8.1-linux-amd64.tar.gz

# Create Mattermost user and set permissions
echo "Setting up Mattermost user and permissions..."
useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

# Configure Mattermost
echo "Configuring Mattermost..."
cd /opt/mattermost
cp config/config.json config/config.original.json
sed -i 's/"DriverName": "mysql"/"DriverName": "postgres"/g' config/config.json
sed -i 's/"DataSource": "mmuser:mostest@tcp(localhost:3306)\/mattermost?charset=utf8mb4,utf8\u0026readTimeout=30s\u0026writeTimeout=30s"/"DataSource": "postgres:\/\/mmuser:mmuser-password@localhost:5432\/mattermost?sslmode=disable\u0026connect_timeout=10"/g' config/config.json

# Create systemd service for Mattermost
echo "Creating Mattermost service..."
cat > /etc/systemd/system/mattermost.service << 'EOL'
[Unit]
Description=Mattermost
After=network.target postgresql.service

[Service]
Type=notify
User=mattermost
Group=mattermost
ExecStart=/opt/mattermost/bin/mattermost
TimeoutStartSec=3600
Restart=always
RestartSec=10
WorkingDirectory=/opt/mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
EOL

# Configure Nginx as a reverse proxy
echo "Configuring Nginx..."
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
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        client_body_timeout 60;
        send_timeout 300;
        lingering_timeout 5;
        proxy_connect_timeout 90;
        proxy_send_timeout 300;
        proxy_read_timeout 90s;
        proxy_pass http://127.0.0.1:8065;
    }

    location / {
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        proxy_read_timeout 600s;
        proxy_cache_revalidate on;
        proxy_cache_min_uses 2;
        proxy_cache_use_stale timeout;
        proxy_cache_lock on;
        proxy_http_version 1.1;
        proxy_pass http://127.0.0.1:8065;
    }
}
EOL

# Enable and start services
echo "Starting services..."
systemctl daemon-reload
systemctl enable mattermost
systemctl enable nginx
systemctl start mattermost
systemctl start nginx

# Configure firewall
echo "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo "Mattermost installation complete!"
echo "You can access Mattermost at http://YOUR_SERVER_IP"
echo "Please complete the setup through the web interface."

