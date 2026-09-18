# Schema Reference

This page documents the **final database state after all migrations currently in
`db/migrations/` are applied**.

## Tables

### `suppliers`

Supplier master data.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `name` | `text` | Not null |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `clients`

Client master data.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `name` | `text` | Not null |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `warehouses`

Warehouse/location metadata.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `code` | `text` | Not null, unique |
| `warehouse_name` | `text` | Not null |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `raw_materials`

Purchased inputs.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `sku` | `text` | Not null, unique |
| `description` | `text` | Not null |
| `supplier_id` | `integer` | FK to `suppliers.id`, nullable |
| `current_stock` | `numeric` | Not null, default 0 |
| `min_stock_level` | `numeric` | Not null, default 0 |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `intermediaries`

Stocked sub-assemblies.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `sku` | `text` | Not null, unique |
| `description` | `text` | Not null |
| `current_stock` | `numeric` | Not null, default 0 |
| `min_stock_level` | `numeric` | Not null, default 0 |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `finished_products`

Sellable products.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `sku` | `text` | Not null, unique |
| `description` | `text` | Not null |
| `client_id` | `integer` | FK to `clients.id`, nullable |
| `current_stock` | `numeric` | Not null, default 0 |
| `min_stock_level` | `numeric` | Not null, default 0 |
| `created_at` | `timestamptz` | Defaults to `now()` |
| `updated_at` | `timestamptz` | Defaults to `now()` |

### `bom`

Typed multi-level bill of materials.

| Column | Type | Constraints |
|---|---|---|
| `parent_type` | `text` | `intermediate` or `finished` |
| `parent_id` | `integer` | Typed reference |
| `child_type` | `text` | `raw` or `intermediate` |
| `child_id` | `integer` | Typed reference |
| `quantity` | `numeric` | Must be greater than 0 |

Primary key:

```text
(parent_type, parent_id, child_type, child_id)
```

Database rules:

- raw materials cannot be BOM parents
- finished products cannot be BOM children
- direct intermediary self-reference is rejected
- `trg_check_bom_references` validates typed parent and child references

### `stock_transactions`

Append-style inventory movement ledger.

| Column | Type | Constraints |
|---|---|---|
| `id` | `serial` | Primary key |
| `product_id` | `integer` | Typed product reference |
| `product_type` | `text` | `raw`, `intermediate`, or `finished` |
| `warehouse_id` | `integer` | FK to `warehouses.id`, nullable |
| `quantity` | `numeric` | Signed stock movement |
| `transaction_date` | `timestamptz` | Defaults to `now()` |

Indexes:

- `idx_stock_transactions_transaction_date`
- `idx_stock_transactions_product_lookup`
- `idx_stock_transactions_warehouse_lookup`

The trigger layer validates the typed product reference and blocks a movement
that would drive the global stock balance negative.

## Views

### `stock_on_hand`

Unified global stock state across all three item tiers.

Columns:

- `id`
- `sku`
- `description`
- `current_stock`
- `product_type`

### `reorder_alerts`

Items whose `current_stock` is below `min_stock_level`.

Columns:

- `id`
- `sku`
- `description`
- `current_stock`
- `min_stock_level`
- `product_type`

### `stock_on_hand_by_warehouse`

Ledger-derived stock balances by warehouse and typed product.

Columns:

- `warehouse_id`
- `warehouse_code`
- `warehouse_name`
- `product_id`
- `sku`
- `description`
- `product_type`
- `current_stock`

## Functions

### `validate_bom_reference(item_type, item_id)`

Returns whether the typed item exists in the corresponding inventory table.

### `check_bom_references()`

Trigger function enforcing typed BOM referential integrity.

### `check_stock_before_insert()`

Validates a stock transaction before insertion.

It rejects:

- unknown typed product references
- movements that would make global stock negative

### `update_current_stock_after_insert()`

Applies a transaction quantity to the relevant item table after insertion.

### `bom_explosion(parent_id)`

Recursively expands a finished-product BOM and aggregates requirements across
all nested intermediary and raw-material levels.

Returns:

- `child_id`
- `child_type`
- `quantity`

### `create_production_run(product_id, quantity)`

Convenience overload that uses the `MAIN` warehouse when it exists.

### `create_production_run(product_id, quantity, warehouse_id)`

Creates one production batch.

It:

- validates quantity, product, warehouse, and BOM
- inserts negative movements for direct BOM children
- inserts a positive finished-product movement
- carries the selected warehouse into all generated transactions

### `transfer_stock(product_id, product_type, quantity, from_warehouse_id, to_warehouse_id)`

Moves stock between warehouses by writing one negative source movement and one
positive destination movement.

It validates:

- positive transfer quantity
- supported product type
- distinct source and destination warehouses
- product and warehouse existence
- sufficient source-warehouse balance

## Triggers

| Trigger | Table | Purpose |
|---|---|---|
| `trg_check_stock_before_insert` | `stock_transactions` | Validate typed product reference and stock balance |
| `trg_update_current_stock` | `stock_transactions` | Update global `current_stock` |
| `trg_check_bom_references` | `bom` | Validate typed BOM references |

## Relationship model

For the full visual model, see the [ER Diagram](ERD.md).
