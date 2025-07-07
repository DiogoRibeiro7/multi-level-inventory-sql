#!/bin/sh
# Run integration tests using Docker Compose

set -e

docker-compose up -d
trap 'docker-compose down' EXIT

# Wait for PostgreSQL to accept connections
sleep 5

poetry install
poetry run inventory-cli postgresql://postgres:postgres@localhost:5432/postgres
psql postgresql://postgres:postgres@localhost:5432/postgres -c 'CREATE EXTENSION IF NOT EXISTS pgtap;'
poetry run pytest -q
pg_prove --dbname=postgresql://postgres:postgres@localhost:5432/postgres tests/pgtap/*.sql
