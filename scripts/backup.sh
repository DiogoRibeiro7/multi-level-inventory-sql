#!/bin/sh
# Simple wrapper around pg_dump to back up the database

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 CONNECTION_STRING OUTPUT_FILE" >&2
  exit 1
fi

pg_dump "$1" > "$2"
