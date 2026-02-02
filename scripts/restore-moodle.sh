#!/bin/bash

set -e

if [ -z "$PGPASSWORD" ]; then
  export PGPASSWORD='pass'
fi

BACKUP_DATE=$1

if [ -z "$BACKUP_DATE" ]; then
  echo "Available backups:"
  ls backup
  exit 0
elif [ "$BACKUP_DATE" = "latest" ]; then
  BACKUP_DATE=$(ls -1 backup | sort | tail -n 1)
fi

BACKUP_DIR="backup/$BACKUP_DATE"

echo "Restoring from '$BACKUP_DIR'."

echo "Restoring moodle software..."
tar xzf $BACKUP_DIR/moodle.tar.gz -C .
echo "Done."

echo "Restoring moodledata..."
tar xzf $BACKUP_DIR/moodledata.tar.gz -C .
echo "Done."

echo "Restoring moodle database..."
gunzip -k $BACKUP_DIR/moodle-database.sql.gz
psql -h localhost -U moodle_user -d moodle -f $BACKUP_DIR/moodle-database.sql
echo "Done."

echo "Restore completed."
