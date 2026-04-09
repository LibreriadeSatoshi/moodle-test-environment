#!/bin/bash

# Init postgres data dir
mkdir -p /var/lib/postgresql/data
chown -R postgres:postgres /var/lib/postgresql

# Init apache
a2enmod rewrite ssl socache_shmcb
a2dissite 000-default
a2ensite moodle

# Permissions for /root so apache can read files served from here
chmod 755 /root

# PHP settings required by Moodle (apache + cli SAPIs)
for d in /etc/php/*/apache2/conf.d /etc/php/*/cli/conf.d; do
  echo "max_input_vars = 5000" > "$d/99-moodle.ini"
done
