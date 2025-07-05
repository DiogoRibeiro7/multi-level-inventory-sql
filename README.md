# multi-level-inventory-sql
[![CI](https://github.com/DiogoRibeiro7/multi-level-inventory-sql/actions/workflows/ci.yml/badge.svg)](https://github.com/DiogoRibeiro7/multi-level-inventory-sql/actions/workflows/ci.yml)
Tracks inventory across raw materials, intermediary products, and finished goods.

See ROADMAP.md for the technical roadmap and BUSINESS_ANALYSIS.md for business planning considerations.

## Setup
1. Install PostgreSQL and ensure `psql` is available in your `PATH`.
2. Run the migrations and seeds manually:
   ```bash
   psql -f db/migrations/001_create_schema.sql
   psql -f db/migrations/002_add_stock_triggers.sql
   psql -f db/migrations/003_create_views.sql
   psql -f db/migrations/004_add_partners.sql
   psql -f db/migrations/005_remove_stock_fk.sql
   psql -f db/migrations/006_add_reorder_thresholds.sql
   psql -f db/seeds/001_suppliers.sql
   psql -f db/seeds/002_clients.sql
   psql -f db/seeds/003_raw_materials.sql
   psql -f db/seeds/004_intermediaries.sql
   psql -f db/seeds/005_finished_products.sql
   psql -f db/seeds/006_bom.sql
   psql -f db/seeds/007_stock.sql
   psql -f db/seeds/008_min_stock_levels.sql
   ```
   Seeds include additional products and a complete bill of materials.
3. Alternatively, use the Poetry-based CLI:
   ```bash
   poetry install
   poetry run inventory-cli postgres://user:pass@localhost/dbname
   ```

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

This project uses a GitHub Actions workflow to ensure migrations, seeds,
linting, and tests run on every pull request. The workflow spins up PostgreSQL,
runs the CLI against it, and executes the test suite.
