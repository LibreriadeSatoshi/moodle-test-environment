#!/bin/bash

# Init postgres
mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql
pg_ctlcluster 17 main start
su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE USER moodle_user WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE DATABASE moodle OWNER moodle_user;\""

# Init apache
a2enmod rewrite ssl socache_shmcb
a2dissite 000-default
a2ensite moodle

# Restore backup
./restore-moodle.sh latest

# Copy config.php adapted for this environment
mv config.php moodle/config.php
# Setup the maintenance page for later
mv climaintenance.html moodledata/climaintenance.html.disabled

# Fix ownership and permissions
chmod 755 /root
chown -R www-data:www-data moodle moodledata

# Finalize
apache2ctl start
