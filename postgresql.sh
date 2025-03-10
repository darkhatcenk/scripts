#cloud-config
packages:
  - postgresql-server
  - postgresql-contrib

runcmd:
  - postgresql-setup initdb
  - systemctl start postgresql
  - systemctl enable postgresql
  - sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
  - echo "host    all             all             0.0.0.0/0               md5" >> /var/lib/pgsql/data/pg_hba.conf
  - echo "host    all             admin           0.0.0.0/0               md5" >> /var/lib/pgsql/data/pg_hba.conf
  - systemctl restart postgresql
  - sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'password';"
  - sudo -u postgres psql -c "ALTER USER admin CREATEDB;"
  - echo "ALTER USER postgres WITH PASSWORD 'newpassword';" | sudo -u postgres psql

# Firewall ayarları
firewall:
  firewall:
    - name: postgresql
      port: 5432
      protocol: tcp
      action: accept
