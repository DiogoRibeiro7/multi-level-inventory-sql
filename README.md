# multi-level-inventory-sql

Tracks inventory across raw materials, intermediary products, and finished
goods with PostgreSQL, typed multi-level BOM relationships, warehouse-aware
stock movement, database integrity checks, and automated tests.

See [ROADMAP.md](ROADMAP.md) for the technical roadmap and
[BUSINESS_ANALYSIS.md](BUSINESS_ANALYSIS.md) for business-planning context.

## Setup

1. Install PostgreSQL and ensure `psql` is available in your `PATH`.
2. Install dependencies:

   ```bash
   poetry install
   ```

3. Apply all migrations and seeds:

   ```bash
   poetry run inventory-cli postgres://user:pass@localhost/dbname
   ```

The CLI records applied migrations and seeds in `inventory_script_history`, skips scripts that already ran, and verifies SHA-256 checksums before continuing.

For an existing database created before migration tracking was introduced, run:

```bash
poetry run inventory-cli postgres://user:pass@localhost/dbname baseline
```

`baseline` records the current migration and seed files without executing them. Use it only after confirming the target database already contains that schema/data state.

## Documentation

The project documentation is built with MkDocs Material and published at
https://diogoribeiro7.github.io/multi-level-inventory-sql/.

Build it locally:

```bash
poetry run mkdocs build --strict
```

Serve it with live reload:

```bash
poetry run mkdocs serve
```

Documentation includes:

- architecture and system flow
- complete schema reference
- Mermaid ER diagram
- release process
- portfolio showcase guide

Source files live in [`docs/`](docs/).

## Architecture overview

The database models three inventory tiers:

- `raw_materials`: purchased inputs
- `intermediaries`: stocked sub-assemblies
- `finished_products`: sellable output items

Inventory movement is written to `stock_transactions`, while global
`current_stock` values are maintained by database triggers.

The typed `bom` table supports finished products consuming intermediaries and
intermediaries consuming raw materials. Warehouse-specific balances are derived
from the transaction ledger by `stock_on_hand_by_warehouse`.

## Useful queries

Global stock:

```sql
SELECT * FROM stock_on_hand;
```

Warehouse stock:

```sql
SELECT *
FROM stock_on_hand_by_warehouse
ORDER BY warehouse_code, product_type, sku;
```

Reorder alerts:

```sql
SELECT * FROM reorder_alerts;
```

Recursive BOM expansion:

```sql
SELECT * FROM bom_explosion(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001')
);
```

Production run:

```sql
SELECT create_production_run(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
  1
);
```

Warehouse transfer:

```sql
SELECT transfer_stock(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
  'finished',
  2,
  (SELECT id FROM warehouses WHERE code = 'MAIN'),
  (SELECT id FROM warehouses WHERE code = 'AUX')
);
```

## Testing

Python tests:

```bash
poetry run pytest -q
```

SQL linting:

```bash
poetry run sqlfluff lint db/**/*.sql
```

The GitHub Actions workflow also runs the PostgreSQL migrations, seed data,
pgTAP tests, and a strict MkDocs build.

## Integration testing

```bash
docker compose up -d
./scripts/integration_test.sh
```

## Backup and restore

```bash
./scripts/backup.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
./scripts/restore.sh postgres://user:pass@localhost/dbname /path/to/backup.sql
```
