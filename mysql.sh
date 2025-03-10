#!/bin/bash
dnf update -y
dnf install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb
mysql_secure_installation <<EOF

y
password
password
y
y
y
y
EOF

mysql -u root -ppassword <<EOF
CREATE DATABASE testdb;
CREATE USER 'testuser'@'localhost' IDENTIFIED BY 'testpassword';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;
EOF

if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=mysql
    firewall-cmd --reload
fi
echo "MySQL installation complete!"
echo "Connection details saved in /root/mysql_info.txt"
