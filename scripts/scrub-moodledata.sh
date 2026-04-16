#!/bin/bash

set -e

MOODLEDATA="${MOODLEDATA:-/root/moodledata}"

echo "Clearing filestore on disk at '$MOODLEDATA'..."
for d in filedir trashdir temp sessions cache localcache muc antivirus_quarantine repository; do
  dir="$MOODLEDATA/$d"
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -delete
  fi
done

if id -u www-data >/dev/null 2>&1; then
  chown -R www-data:www-data "$MOODLEDATA"
fi

echo "Scrub completed."
