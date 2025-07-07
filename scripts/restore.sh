#!/bin/sh
# Restore a PostgreSQL backup created with pg_dump

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 CONNECTION_STRING BACKUP_FILE" >&2
  exit 1
fi

psql "$1" -f "$2"
