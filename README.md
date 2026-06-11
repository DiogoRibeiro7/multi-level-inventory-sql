# multi-level-inventory-sql
Tracks inventory across raw materials, intermediary products, and finished goods.

See ROADMAP.md for the technical roadmap and BUSINESS_ANALYSIS.md for business planning considerations.

## Setup
1. Install PostgreSQL and ensure `psql` is available in your `PATH`.
2. Install dependencies and run the CLI to apply all migrations and seeds:
   ```bash
   poetry install
   poetry run inventory-cli postgres://user:pass@localhost/dbname
   ```
   The CLI executes every SQL file in `db/migrations` and `db/seeds` in order.
   The lock file is not committed; running `poetry install` will generate it
   automatically.
3. If you prefer to run scripts manually, execute the files in those
   directories with `psql`. Each migration script also contains a "Down"
   section so schema changes can be rolled back if needed.

pgTAP tests live in `tests/pgtap/` and are executed as part of the CI
workflow to verify database functions, triggers, and post-run stock integrity.

## Architecture Overview

The database models three inventory tiers:

- `raw_materials`: purchased inputs.
- `intermediaries`: stocked sub-assemblies.
- `finished_products`: sellable output items.

Inventory movement is written to `stock_transactions`, while `current_stock`
on each item table is maintained by triggers. Multi-level production structure
is stored in the typed `bom` table, which allows finished products to consume
intermediaries and intermediaries to consume raw materials.

After the migrations run, the `stock_on_hand` view provides an overview of
current inventory levels:

```sql
SELECT * FROM stock_on_hand;
```

To identify items that need replenishment, query the `reorder_alerts` view:

```sql
SELECT * FROM reorder_alerts;
```

Use the `bom_explosion` function to see the total components needed for a
finished product across intermediary and raw-material levels:

```sql
SELECT * FROM bom_explosion(1); -- components for product with ID 1
```

To create a production run for one finished bike:

```sql
SELECT create_production_run(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
  1
);
```

To inspect the transaction history for one SKU:

```sql
SELECT st.*
FROM stock_transactions AS st
JOIN finished_products AS fp
  ON fp.id = st.product_id
WHERE st.product_type = 'finished'
  AND fp.sku = 'BIKE001'
ORDER BY st.transaction_date DESC;
```

## Continuous Integration

This project includes a GitHub Actions workflow that runs on pull requests to
`main` and on pushes to `main`. The job starts PostgreSQL, applies the
migrations and seeds, lints SQL files, and executes the test suite.

## Integration Testing with Docker Compose

Use Docker Compose to start a local PostgreSQL instance and run the full test
suite. The helper script sets up the database, applies migrations and seeds,
and then executes Python and pgTAP tests:

```bash
docker-compose up -d
./scripts/integration_test.sh
```

The script shuts down the container when tests complete.

## Backup and Restore
Use the helper scripts in `scripts/` to back up the database and restore it later:
```bash
./scripts/backup.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
./scripts/restore.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
```

Operational notes:
- `backup.sh` requires `pg_dump` in `PATH`, creates parent directories when
  needed, and refuses to overwrite an existing backup file.
- `restore.sh` requires `psql` in `PATH`, fails if the backup file is missing,
  and runs with `ON_ERROR_STOP=1` so SQL errors abort the restore.
- Restore into an empty or disposable database when validating a backup, since
  the script replays SQL exactly as stored in the dump.

## Documentation
The [docs/ERD.md](docs/ERD.md) file contains the entity relationship overview,
and [docs/ERD.drawio](docs/ERD.drawio) is the editable diagram source.
The [docs/SCHEMA.md](docs/SCHEMA.md) file documents tables, views, constraints,
and database functions.
The [docs/RELEASE.md](docs/RELEASE.md) file documents the semantic versioning
and release workflow used by the project.
See [CHANGELOG.md](CHANGELOG.md) for release notes.
