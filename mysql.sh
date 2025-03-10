#cloud-config

package_update: true
package_upgrade: true

packages:
  - mysql-server
  - phpmyadmin
  - httpd
  - php
  - php-mysqlnd
  - php-xml
  - php-mbstring
  - php-json

runcmd:
  - systemctl start mysqld
  - systemctl enable mysqld
  - mysql -e "UPDATE mysql.user SET Password=PASSWORD('password') WHERE User='root';"
  - mysql -e "DELETE FROM mysql.user WHERE User='';"
  - mysql -e "DROP DATABASE IF EXISTS test;"
  - mysql -e "FLUSH PRIVILEGES;"
  - mysql -e "CREATE DATABASE testdbs;"
  - mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'password';"
  - mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';"
  - mysql -e "FLUSH PRIVILEGES;"
  - sed -i 's/Require all denied/Require all granted/g' /etc/httpd/conf.d/phpMyAdmin.conf
  - sed -i 's/Require local/Require all granted/g' /etc/httpd/conf.d/phpMyAdmin.conf
  - systemctl restart httpd
  - systemctl restart mysqld
