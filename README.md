# multi-level-inventory-sql
Tracks inventory across raw materials, intermediary products, and finished goods.

See ROADMAP.md for the technical roadmap and BUSINESS_ANALYSIS.md for business planning considerations.

## Setup
1. Install PostgreSQL and ensure `psql` is available in your `PATH`.
2. Run the migrations and seeds manually:
   ```bash
   psql -f db/migrations/001_create_schema.sql
   psql -f db/migrations/002_add_stock_triggers.sql
   psql -f db/migrations/003_create_views.sql
   psql -f db/seeds/seed_raw_materials.sql
   psql -f db/seeds/seed_intermediaries.sql
   psql -f db/seeds/seed_products.sql
   psql -f db/seeds/seed_bom.sql
   psql -f db/seeds/seed_stock.sql
   ```
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
