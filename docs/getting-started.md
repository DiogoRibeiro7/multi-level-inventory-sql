# Getting Started

## Prerequisites

The project requires:

- Python 3.11 or newer
- Poetry
- PostgreSQL client tools, including `psql`
- PostgreSQL 16 for local database execution

## Install dependencies

```bash
poetry install
```

## Apply migrations and seed data

Run all pending migrations and seeds:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname
```

Applied scripts are stored in `inventory_script_history` with their SHA-256 checksums. Re-running the command skips scripts that have already been applied. If an applied file changes later, the CLI stops with a checksum mismatch.

Run only migrations:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname migrate
```

Run migrations up to a specific file:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname migrate \
  --to 009_enable_multi_level_bom.sql
```

## Existing databases

If the database was initialized before migration tracking existed, baseline it once:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname baseline
```

This records all current migration and seed files without executing them. Baseline only a database whose schema and seed state already matches the repository.

## Run the test suite

Python tests:

```bash
poetry run pytest -q
```

SQL linting:

```bash
poetry run sqlfluff lint db/**/*.sql
```

The CI workflow also runs the pgTAP database suite against PostgreSQL.

## Build the documentation

Build the site with warnings treated as errors:

```bash
poetry run mkdocs build --strict
```

Serve it locally with live reload:

```bash
poetry run mkdocs serve
```

Then open `http://127.0.0.1:8000/`.

## Docker integration path

A local PostgreSQL instance can also be started with Docker Compose:

```bash
docker compose up -d
./scripts/integration_test.sh
```

The integration script applies the database setup and executes the test path.
