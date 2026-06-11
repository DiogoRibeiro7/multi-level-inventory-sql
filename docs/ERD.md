# Entity Relationship Diagram

```text
suppliers --< raw_materials
clients   --< finished_products

raw_materials --< intermediaries --< finished_products

bom stores typed parent/child links:
- finished_products -> intermediaries
- finished_products -> raw_materials
- intermediaries -> raw_materials
- intermediaries -> intermediaries

finished_products --< stock_transactions
intermediaries   --< stock_transactions
raw_materials    --< stock_transactions
```

For a field-level schema reference, see [SCHEMA.md](SCHEMA.md).
