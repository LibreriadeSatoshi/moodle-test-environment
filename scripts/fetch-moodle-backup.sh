#!/bin/bash

BACKUP_DATE=$1

PEM=~/.ssh/moodle-mvp.pem
SSH="ssh -i $PEM"
SCP="scp -i $PEM"
HOST="ubuntu@3.208.41.147"
FROM="$HOST:backup/$BACKUP_DATE"
TO="backup/$BACKUP_DATE/"

if [ -z "$BACKUP_DATE" ]; then
  echo "Available backups:"
  $SSH $HOST 'cd backup && ls'
  exit 0
fi

mkdir -p $TO
$SCP $FROM/moodle.tar.gz $TO
$SCP $FROM/moodledata.tar.gz $TO
$SCP $FROM/moodle-database.sql.gz $TO
