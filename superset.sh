#!/bin/bash
# Shell script for Apache Superset installation on Rocky Linux 9

# Update and upgrade the system
echo "Updating system packages..."
dnf update -y
dnf upgrade -y

# Install necessary tools
echo "Installing required packages..."
dnf install -y yum-utils device-mapper-persistent-data lvm2 git curl

# Create the Superset directory
mkdir -p /opt/superset

# Create docker-compose.yml file
echo "Creating docker-compose.yml file..."
cat > /opt/superset/docker-compose.yml << 'EOF'
version: "3.1"
services:
  superset:
    image: apache/superset:latest
    container_name: superset
    environment:
      SUPERSET_ENV: production
      SUPERSET_LOAD_EXAMPLES: "yes"
      SUPERSET_SECRET_KEY: "this_is_a_secret_key"
    ports:
      - "8088:8088"
    volumes:
      - superset_home:/app/superset_home
    restart: always
volumes:
  superset_home:
EOF

# Add Docker's official GPG key and repository
echo "Setting up Docker repository..."
curl -fsSL https://download.docker.com/linux/centos/gpg | gpg --dearmor -o /etc/pki/rpm-gpg/docker-ce.gpg
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
echo "Installing Docker..."
dnf install -y docker-ce docker-ce-cli containerd.io

# Enable and start Docker service
echo "Starting Docker service..."
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Start Superset container
echo "Starting Superset container..."
cd /opt/superset
docker-compose up -d

# Wait for Superset to initialize
echo "Waiting for Superset to initialize (30 seconds)..."
sleep 30

# Create an admin user
echo "Creating admin user..."
docker exec -i superset superset fab create-admin \
  --username admin \
  --firstname Admin \
  --lastname User \
  --email admin@example.com \
  --password admin

# Initialize the database
echo "Initializing database..."
docker exec -i superset superset db upgrade

# Load examples (optional)
echo "Loading examples..."
docker exec -i superset superset load_examples

# Start the Superset web server
echo "Starting Superset web server..."
docker exec -i superset superset init

echo "Apache Superset installation complete!"
echo "You can access Superset at http://YOUR_SERVER_IP:8088"
echo "Username: admin"
echo "Password: admin"

