# Schema Reference

This document summarizes the tables, views, and functions created by the
current migration set.

## Tables

### `raw_materials`

Stores purchased inputs used directly by intermediaries or finished products.

Columns:
- `id`: surrogate primary key.
- `sku`: unique stock keeping unit.
- `description`: human-readable item name.
- `supplier_id`: optional reference to `suppliers.id`.
- `current_stock`: running on-hand balance maintained by triggers.
- `min_stock_level`: reorder threshold used by `reorder_alerts`.
- `created_at`, `updated_at`: timestamps.

Constraints:
- Primary key on `id`.
- Unique constraint on `sku`.

### `intermediaries`

Stores sub-assemblies that can be stocked and consumed by finished products or
other intermediaries.

Columns:
- `id`: surrogate primary key.
- `sku`: unique stock keeping unit.
- `description`: human-readable item name.
- `current_stock`: running on-hand balance maintained by triggers.
- `min_stock_level`: reorder threshold used by `reorder_alerts`.
- `created_at`, `updated_at`: timestamps.

Constraints:
- Primary key on `id`.
- Unique constraint on `sku`.

### `finished_products`

Stores sellable products produced from BOM-defined components.

Columns:
- `id`: surrogate primary key.
- `sku`: unique stock keeping unit.
- `description`: human-readable item name.
- `client_id`: optional reference to `clients.id`.
- `current_stock`: running on-hand balance maintained by triggers.
- `min_stock_level`: reorder threshold used by `reorder_alerts`.
- `created_at`, `updated_at`: timestamps.

Constraints:
- Primary key on `id`.
- Unique constraint on `sku`.

### `bom`

Stores typed parent/child component relationships for multi-level production.

Columns:
- `parent_type`: one of `intermediate` or `finished`.
- `parent_id`: identifier in the table implied by `parent_type`.
- `child_type`: one of `raw` or `intermediate`.
- `child_id`: identifier in the table implied by `child_type`.
- `quantity`: required component quantity per unit of the parent.

Constraints:
- Composite primary key on
  `parent_type, parent_id, child_type, child_id`.
- `quantity > 0`.
- `parent_type` restricted to `intermediate` and `finished`.
- `child_type` restricted to `raw` and `intermediate`.
- `bom_no_self_reference_check` blocks direct intermediary self-reference.
- Trigger `trg_check_bom_references` validates that typed parent and child
  rows exist.

### `stock_transactions`

Stores inventory movements for raw materials, intermediaries, and finished
products.

Columns:
- `id`: surrogate primary key.
- `product_id`: identifier in the table implied by `product_type`.
- `product_type`: one of `raw`, `intermediate`, or `finished`.
- `warehouse_id`: optional reference to `warehouses.id`.
- `quantity`: positive for inbound stock, negative for consumption.
- `transaction_date`: timestamp for the movement.

Constraints and indexes:
- Primary key on `id`.
- `product_type` restricted to `raw`, `intermediate`, and `finished`.
- Index on `transaction_date`.
- Composite lookup index on `product_type, product_id`.
- Warehouse lookup index on `warehouse_id, product_type, product_id`.
- Trigger `trg_check_stock_before_insert` blocks missing references and
  negative balances.
- Trigger `trg_update_current_stock` applies the transaction to the relevant
  stock table.

### `warehouses`

Stores warehouse or storage-location metadata used by stock transactions.

Columns:
- `id`: surrogate primary key.
- `code`: unique warehouse code.
- `warehouse_name`: human-readable warehouse name.
- `created_at`, `updated_at`: timestamps.

Constraints:
- Primary key on `id`.
- Unique constraint on `code`.

### `suppliers`

Stores supplier master data.

Columns:
- `id`: surrogate primary key.
- `name`: supplier name.
- `created_at`, `updated_at`: timestamps.

### `clients`

Stores client master data.

Columns:
- `id`: surrogate primary key.
- `name`: client name.
- `created_at`, `updated_at`: timestamps.

## Views

### `stock_on_hand`

Normalizes current inventory across all three product tiers with a unified
`product_type` column.

Output columns:
- `id`
- `sku`
- `description`
- `current_stock`
- `product_type`

### `reorder_alerts`

Lists items whose `current_stock` is below `min_stock_level`.

Output columns:
- `id`
- `sku`
- `description`
- `current_stock`
- `min_stock_level`
- `product_type`

### `stock_on_hand_by_warehouse`

Aggregates stock balances by warehouse and product.

Output columns:
- `warehouse_id`
- `warehouse_code`
- `warehouse_name`
- `product_id`
- `sku`
- `description`
- `product_type`
- `current_stock`

## Functions

### `create_production_run(product_id, quantity)`

Consumes the direct BOM children of a finished product and adds the requested
finished quantity to stock.

Behavior:
- Rejects `quantity <= 0`.
- Rejects unknown finished product IDs.
- Rejects production runs for products without a BOM.
- Inserts one negative `stock_transactions` row per direct BOM child.
- Inserts one positive finished-goods `stock_transactions` row.

### `bom_explosion(parent_id)`

Recursively expands the BOM of a finished product and returns the rolled-up
component requirements across intermediary and raw-material levels.

Output columns:
- `child_id`
- `child_type`
- `quantity`
