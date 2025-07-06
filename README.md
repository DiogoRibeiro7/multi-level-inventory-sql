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
workflow to verify database functions and triggers.

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
finished product:

```sql
SELECT * FROM bom_explosion(1); -- components for product with ID 1
```

## Continuous Integration

This project includes a GitHub Actions workflow that runs only after changes
are merged to the `main` branch. The job starts PostgreSQL, applies the
migrations and seeds, lints SQL files, and executes the test suite.

## Backup and Restore
Use the helper scripts in `scripts/` to back up the database and restore it later:
```bash
./scripts/backup.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
./scripts/restore.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
```

## Documentation
The [docs/ERD.md](docs/ERD.md) file contains an entity relationship diagram.
See [CHANGELOG.md](CHANGELOG.md) for release notes.
