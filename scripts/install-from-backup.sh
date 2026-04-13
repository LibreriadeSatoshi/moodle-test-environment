#!/bin/bash

pg_ctlcluster 17 main start
su - postgres -c "psql -c \"ALTER USER postgres WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE USER moodle_user WITH PASSWORD 'pass';\""
su - postgres -c "psql -c \"CREATE DATABASE moodle OWNER moodle_user;\""
su - postgres -c "psql -d moodle -c \"ALTER SCHEMA public OWNER TO moodle_user;\""

cp config.php /root/libreria-moodle/config.php

./restore-moodle.sh latest

chown -R www-data:www-data /root/moodledata

apache2ctl start
