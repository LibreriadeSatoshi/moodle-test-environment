#!/bin/bash

pg_ctlcluster 17 main start

cp config.php /root/libreria-moodle/config.php
cp /root/patches/hvp-curl.php /root/libreria-moodle/public/mod/hvp/classes/curl.php

chown -R www-data:www-data /root/moodledata

apache2ctl start
