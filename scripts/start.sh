#!/bin/bash

pg_ctlcluster 17 main start

cp config.php /root/libreria-moodle/config.php

chown -R www-data:www-data /root/moodledata

apache2ctl start
