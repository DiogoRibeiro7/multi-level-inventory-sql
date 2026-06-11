#!/bin/sh
# Simple wrapper around pg_dump to back up the database

set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 CONNECTION_STRING OUTPUT_FILE" >&2
  exit 1
fi

if ! command -v pg_dump >/dev/null 2>&1; then
  echo "pg_dump executable not found in PATH" >&2
  exit 1
fi

conn_str=$1
output_file=$2
output_dir=$(dirname "$output_file")

if [ -e "$output_file" ]; then
  echo "Refusing to overwrite existing file: $output_file" >&2
  exit 1
fi

mkdir -p "$output_dir"

tmp_file="${output_file}.tmp"
trap 'rm -f "$tmp_file"' EXIT

pg_dump --file="$tmp_file" "$conn_str"
mv "$tmp_file" "$output_file"

echo "Backup written to $output_file"
