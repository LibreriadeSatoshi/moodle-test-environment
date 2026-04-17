#!/bin/bash

set -e

if [ -z "$PGPASSWORD" ]; then
  export PGPASSWORD='pass'
fi

BACKUP_DIR="backup/$(date +%Y-%m-%d-%H%M)"

echo "Backing up to '$BACKUP_DIR'."
mkdir -p $BACKUP_DIR

echo "Backing up moodledata..."
tar czf $BACKUP_DIR/moodledata.tar.gz moodledata
echo "Done."

echo "Backing up moodle database..."
pg_dump -h localhost -U moodle_user -d moodle > $BACKUP_DIR/moodle-database.sql

if [ $? -ne 0 ]; then
  echo "Error: Failed to backup moodle database, check the database credentials."
  exit 1
fi

gzip $BACKUP_DIR/moodle-database.sql
echo "Done."

echo "Backup stored in '$BACKUP_DIR'."
