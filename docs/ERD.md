# Entity Relationship Diagram

```text
suppliers --< raw_materials
clients   --< finished_products

raw_materials --< intermediaries --< finished_products

raw_materials --< bom >-- intermediaries
intermediaries --< bom >-- finished_products

finished_products --< stock_transactions
intermediaries   --< stock_transactions
raw_materials    --< stock_transactions
```
