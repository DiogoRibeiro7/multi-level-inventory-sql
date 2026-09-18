# Multi-Level Inventory SQL

A PostgreSQL inventory system for raw materials, intermediaries, and finished
products, with multi-level bills of materials, warehouse-aware stock movement,
database-enforced integrity, and automated tests.

## What the project demonstrates

- versioned PostgreSQL migrations and seed data
- typed multi-level BOM relationships
- recursive BOM explosion
- trigger-maintained stock balances
- production-run and warehouse-transfer functions
- global and per-warehouse reporting views
- pgTAP database tests and Python CLI tests
- SQLFluff validation and GitHub Actions CI
- backup and restore tooling

## Core model

The system deliberately keeps the three inventory tiers in separate tables.
Two typed relationship structures connect them:

1. `bom` resolves a parent and child using both an ID and an item type.
2. `stock_transactions` resolves the affected item using
   `product_type + product_id`.

This preserves domain-specific item tables while still supporting shared
inventory operations.

## Documentation map

Start with [Getting Started](getting-started.md) to run the project locally.

Read [Architecture](architecture.md) for the main data flow and design
decisions.

Use the [Schema Reference](SCHEMA.md) for the final migrated database structure
and the [ER Diagram](ERD.md) for a visual model of physical and typed
relationships.
