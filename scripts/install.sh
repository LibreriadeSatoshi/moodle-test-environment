#!/bin/bash

# Start postgres and configure users/database
pg_ctlcluster 17 main start
su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE USER moodle_user WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE DATABASE moodle OWNER moodle_user;\""
# PG15+ no longer grants CREATE on public schema to non-owners; hand it to moodle_user
su - postgres -c "psql -d moodle -c \"ALTER SCHEMA public OWNER TO moodle_user;\""

# Restore backup
# ./restore-moodle.sh latest

# Place config.php in the libreria-moodle volume
cp config.php /root/libreria-moodle/config.php

# Setup the maintenance page for later
# mv climaintenance.html moodledata/climaintenance.html.disabled

# Create moodledata
mkdir -p /root/moodledata

# Populate the moodle DB schema (skips the web installer; required because pre-placing
# config.php makes public/config.php bypass install.php).
#
# The scholastica theme calls get_config() at the top of its config.php, which hits
# mdl_config — a table that doesn't exist yet during install_database.php's plugin scan.
# Move the theme aside for the duration and restore it on exit (trap covers failures).
SCHOLASTICA_DIR=/root/libreria-moodle/public/theme/scholastica
SCHOLASTICA_BAK=/tmp/scholastica.bak
if [ -d "$SCHOLASTICA_DIR" ]; then
  mv "$SCHOLASTICA_DIR" "$SCHOLASTICA_BAK"
  trap '[ -d "$SCHOLASTICA_BAK" ] && mv "$SCHOLASTICA_BAK" "$SCHOLASTICA_DIR"' EXIT
fi

php /root/libreria-moodle/admin/cli/install_database.php \
  --agree-license \
  --lang=en \
  --adminuser=admin \
  --adminpass='Admin1234!' \
  --adminemail='admin@example.com' \
  --fullname='Libreria Moodle (Test)' \
  --shortname='libreria'

# Fix ownership for apache (www-data) — after install_database wrote files as root
chown -R www-data:www-data /root/moodledata

# Finalize
apache2ctl start
