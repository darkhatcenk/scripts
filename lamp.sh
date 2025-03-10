#!/bin/bash
# LAMP Stack Installation Script (Linux, Apache, MariaDB, PHP)

# Update package lists
echo "Updating package lists..."
dnf update -y

# Install required packages
echo "Installing Apache, MariaDB, and PHP packages..."
dnf install -y httpd mariadb-server php php-mysqlnd php-fpm

# Start and enable Apache web server
echo "Starting and enabling Apache web server..."
systemctl start httpd
systemctl enable httpd

# Start and enable MariaDB database server
echo "Starting and enabling MariaDB database server..."
systemctl start mariadb
systemctl enable mariadb

# Secure MariaDB installation
echo "Securing MariaDB installation..."
mysql -e "UPDATE mysql.user SET Password=PASSWORD('password') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "FLUSH PRIVILEGES;"

# Create PHP info page
echo "Creating PHP info page..."
cat > /var/www/html/index.php << 'EOF'
<?php
phpinfo();
?>
EOF

# Set proper permissions
echo "Setting proper permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure firewall (optional)
echo "Configuring firewall..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo "LAMP stack installation complete!"
echo "You can access your web server at http://YOUR_SERVER_IP"
echo "MariaDB root password: password"

