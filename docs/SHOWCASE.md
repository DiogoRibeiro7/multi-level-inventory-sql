# Showcase Guide

This document is a short portfolio-oriented walkthrough of the project: what
problem it solves, what is technically interesting about it, and how to demo
it quickly.

## Project Summary

`multi-level-inventory-sql` is a PostgreSQL-based inventory system for three
tiers of stock:

- raw materials
- intermediaries / sub-assemblies
- finished products

The repository demonstrates:

- schema design for tiered inventory
- forward-only SQL migrations
- multi-level bill-of-materials modeling
- incremental multi-warehouse support
- trigger-enforced stock integrity
- stored procedures for production flow
- pgTAP and Python-based validation
- CI automation and maintenance tooling

## What Makes It Interesting

### 1. Typed inventory references

The project avoids a single flat products table and instead keeps separate
tables for raw materials, intermediaries, and finished products. That makes
inventory operations more realistic, but it also means stock transactions and
BOM rows must resolve references by both type and ID.

### 2. Multi-level BOM support

The `bom` table supports finished products consuming intermediaries, and
intermediaries consuming raw materials. The `bom_explosion()` function then
recursively expands those relationships into total component requirements.

### 3. Trigger-maintained stock balances

Inventory movement is recorded in `stock_transactions`, while triggers enforce
that stock does not go negative and keep `current_stock` synchronized on each
tier table.

### 4. Testable database behavior

The repo uses pgTAP to test database functions and integrity rules, while the
Python CLI is covered by `pytest`. That gives the project a stronger validation
story than a schema-only repository.

## Recommended Demo Flow

Use this sequence for a quick portfolio demo or screen recording.

### 1. Show the schema shape

Open:

- `docs/ERD.md`
- `docs/SCHEMA.md`

Talk through:

- the three inventory tiers
- typed `bom` relationships
- typed `stock_transactions`
- reporting views and validation triggers

### 2. Run setup

Apply migrations and seeds:

```bash
poetry install
poetry run inventory-cli postgres://user:pass@localhost/dbname
```

### 3. Show the current stock picture

Run:

```sql
SELECT * FROM stock_on_hand ORDER BY product_type, sku;
SELECT * FROM reorder_alerts ORDER BY product_type, sku;
```

### 4. Show recursive BOM expansion

Run:

```sql
SELECT * FROM bom_explosion(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001')
);
```

Point out that this returns both intermediary and raw-material requirements.

### 5. Run a production batch

Run:

```sql
SELECT create_production_run(
  (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
  1
);
```

Then show:

```sql
SELECT * FROM stock_on_hand
WHERE sku IN ('BIKE001', 'FRAME001', 'WHEEL001', 'SEAT001', 'HANDLE001')
ORDER BY product_type, sku;
```

This demonstrates component consumption plus finished-goods incrementing.

### 6. Show test and CI quality controls

Highlight:

- `tests/pgtap/` for database correctness
- `tests/test_cli.py` for CLI behavior
- `.github/workflows/ci.yml` for automated verification
- `stock_on_hand_by_warehouse` as the first future-growth warehouse report

## Design Decisions to Mention

- Separate item-tier tables improve clarity but require typed reference logic.
- Forward-only migrations are safer for an evolving SQL project than rewriting
  historical schema files.
- The trigger layer protects stock integrity at the database boundary, not only
  in application code.
- Documentation was split into schema, ERD, release, and showcase guides so
  each audience can find the right level of detail quickly.

## Portfolio Framing

When describing this project in a portfolio, emphasize:

- database design and migration discipline
- SQL business logic beyond CRUD
- recursive querying and BOM modeling
- automated integrity testing
- operational maturity through CI and backup/restore tooling
