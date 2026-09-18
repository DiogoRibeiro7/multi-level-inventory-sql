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

Run all migrations and seeds:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname
```

Run only migrations:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname migrate
```

Run migrations up to a specific file:

```bash
poetry run inventory-cli postgresql://user:pass@localhost/dbname migrate \
  --to 009_enable_multi_level_bom.sql
```

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
