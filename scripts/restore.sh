#!/bin/sh
# Restore a PostgreSQL backup created with pg_dump

set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 CONNECTION_STRING BACKUP_FILE" >&2
  exit 1
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql executable not found in PATH" >&2
  exit 1
fi

conn_str=$1
backup_file=$2

if [ ! -f "$backup_file" ]; then
  echo "Backup file does not exist: $backup_file" >&2
  exit 1
fi

psql "$conn_str" -v ON_ERROR_STOP=1 -f "$backup_file"

echo "Restore completed from $backup_file"
