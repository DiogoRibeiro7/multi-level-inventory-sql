# ROADMAP

This document outlines the combined technical and business-analysis roadmap for building a multi-level inventory system (raw materials, intermediary products, finished goods) in a GitHub repository.

## Purpose

Deliver a robust SQL-based inventory management system demonstrating database design, migrations, testing, CI/CD, and business value realization.

---

## 1. Project Kick-off & Planning

* **Define use-case & requirements**

  * Track three item tiers: raw materials, intermediary products (sub-assemblies), finished goods.
  * Support bills of materials (BOM), stock movements, and stock valuations.
  * Allow replenishment orders and production runs.
* **List core features**

  * Tables: `raw_materials`, `intermediaries`, `finished_products`, `bom`, `stock_transactions`.
  * CRUD for each tier.
  * BOM explosion queries.
  * Stock-on-hand reports per tier and per location.
* **Identify extras**

  * Views for common reports.
  * Triggers to enforce stock-level constraints.
  * Stored procedures for production runs.

---

## 2. GitHub Repo Setup

* **Create & name repo**: e.g. `multi-level-inventory-sql`.
* **Branch strategy**

  * `main` for release-ready.
  * `dev` for integration.
  * Feature branches: `feature/bom-schema`, `feature/stock-transactions`, `feature/tests`.
* **Essential files**

  * `README.md` (overview, prerequisites, quickstart).
  * `LICENSE` (MIT or Apache 2.0).
  * `.gitignore` (DB dumps, credentials).
* **Issue & project board**

  * Break features into Issues.
  * Use Milestones for “v0.1 (Schema)”, “v0.2 (Transactions)”, etc.

---

## 3. Conceptual & Logical Design

* **ER diagram**

  * Sketch entities and relationships:

    * `raw_materials` → used in → `intermediaries` → used in → `finished_products`.
    * `bom` table linking parent → child with quantity.
    * `stock_transactions` capturing movements (in/out/transfer).
* **Define attributes & keys**

  * Surrogate `id` plus natural keys (e.g. SKU).
  * Timestamps for creation, updates, and transaction dates.
* **Constraints & indexes**

  * Foreign keys on BOM entries.
  * UNIQUE on SKU columns.
  * INDEX on transaction date and product\_id for fast reporting.

---

## 4. Physical Implementation & Migrations

* **Choose SQL engine**: PostgreSQL (recommended for its advanced features).
* **Organize folder structure**

  ```
  ├── db/
  │   ├── migrations/
  │   │   ├── 001_create_schema.sql
  │   │   ├── 002_add_bom_table.sql
  │   │   └── …
  │   ├── seeds/
  │   │   ├── seed_raw_materials.sql
  │   │   └── seed_products.sql
  │   └── functions/
  │       └── create_production_run.sql
  ├── tests/
  ├── .github/workflows/
  ├── README.md
  └── LICENSE
  ```
* **Write migrations**

  * Versioned, idempotent scripts.
  * Include `DOWN` scripts if your tool supports them.
  * `004_add_partners.sql` adds clients and suppliers (implemented).
  * `005_remove_stock_fk.sql` drops a foreign key so stock transactions can
    reference all product types (implemented).
  * `006_add_reorder_thresholds.sql` adds min stock columns and the
    `reorder_alerts` view (implemented).
* **Seed data**

  * Realistic raw materials (e.g. steel, plastic).
  * Sample intermediaries (e.g. frame, casing).
  * Finished products (e.g. bicycle).
  * Suppliers and clients linked to raw materials and finished products.
  * Expanded dataset includes multiple bicycles and components.
  * Poetry-based CLI to run migrations and seeds

---

## 5. Business Logic: Procedures & Triggers

* **Stored procedures**

  * `create_production_run(product_id, quantity)`

    * Explode BOM, deduct raw and intermediary stock.
    * Insert `stock_transaction` rows.
* **Triggers**

  * BEFORE INSERT on `stock_transactions`: prevent negative stock.
  * AFTER INSERT: update a material’s `current_stock` in its table.

---

## 6. Queries & Reports

* **BOM explosion**

  ```sql
  WITH RECURSIVE bom_tree AS (
    SELECT parent_id, child_id, qty FROM bom WHERE parent_id = :product
    UNION ALL
    SELECT b.parent_id, c.child_id, b.qty * c.qty
    FROM bom_tree b
    JOIN bom c ON c.parent_id = b.child_id
  )
  SELECT child_id, SUM(qty) FROM bom_tree GROUP BY child_id;
  ```
* **Stock-on-hand**

  * Aggregate `stock_transactions` by product and date.
  * View `stock_on_hand` consolidates current stock across all item types.
* **Reorder alerts**

  * View showing items below minimum threshold (implemented as `reorder_alerts`).

---

## 7. Testing Strategy

* **Unit tests for functions**

  * Use pgTAP to validate `create_production_run`.
* **Integration tests**

  * Docker-compose: spin up Postgres, run migrations & seeds, then tests.
* **Data integrity checks**

  * Verify no negative balances after test runs.

---

## 8. Continuous Integration & Quality

* **GitHub Actions workflow** (implemented)

  * On PR:

    1. Start Postgres service.
    2. Run migrations & seed data.
    3. Lint SQL files.
    4. Execute tests.
* **Badges in README**: build status (added), test coverage (TBD).
* **Linting**: SQLFluff checks run in CI.

---

## 9. Documentation & Diagrams

* **Enhanced README**

  * Getting started, architecture overview, example commands.
* **Schema docs**

  * Table definitions, column descriptions, constraints.
* **Embed ER diagram**

  * Add PNG or link to draw\.io.
* **Usage examples**

  * How to run a production run.
  * How to query stock levels.

---

## 10. Versioning, Releases & Maintenance

* **Semantic tags**: `v0.1.0` schema only, `v0.2.0` + transactions, etc.
* **CHANGELOG.md**: record new features, fixes, breaking changes.
* **Backup & restore scripts**: `pg_dump` and `psql` commands.
* **Future growth**

  * Support multiple warehouses.
  * Add serial-number tracking.

---

## 11. Showcase & Learnings

* **Write a blog post**

  * Walk through design decisions and challenges.
* **Short demo video**: show migrations, run a production batch, generate reports.
* **Link in portfolio**: highlight architecture, SQL complexity, testing, CI.

See BUSINESS_ANALYSIS.md for the accompanying business analysis plan.
