# Entity Relationship Diagram

The editable diagram source lives in [ERD.drawio](ERD.drawio). Open it in
[diagrams.net](https://app.diagrams.net/) or any draw.io-compatible editor.

Relationship summary:

```text
suppliers --< raw_materials
clients   --< finished_products
warehouses --< stock_transactions

finished_products --< bom >-- intermediaries
intermediaries   --< bom >-- raw_materials
intermediaries   --< bom >-- intermediaries

raw_materials    --< stock_transactions
intermediaries   --< stock_transactions
finished_products --< stock_transactions
```

Notes:
- `bom` is a typed relationship table, so parent and child rows are resolved by
  `parent_type` and `child_type` rather than fixed foreign keys.
- `stock_transactions` is also typed and can reference any of the three stock
  tiers through `product_type`.
- `warehouse_id` on `stock_transactions` adds location context without
  changing the existing global stock-balance model.

For a field-level schema reference, see [SCHEMA.md](SCHEMA.md).
