# Entity Relationship Diagram

The diagram below reflects the current migrated schema.

```mermaid
erDiagram
    SUPPLIERS ||--o{ RAW_MATERIALS : supplies
    CLIENTS ||--o{ FINISHED_PRODUCTS : buys
    WAREHOUSES ||--o{ STOCK_TRANSACTIONS : location

    SUPPLIERS {
        int id PK
        text name
        timestamptz created_at
        timestamptz updated_at
    }

    CLIENTS {
        int id PK
        text name
        timestamptz created_at
        timestamptz updated_at
    }

    WAREHOUSES {
        int id PK
        text code UK
        text warehouse_name
        timestamptz created_at
        timestamptz updated_at
    }

    RAW_MATERIALS {
        int id PK
        text sku UK
        text description
        int supplier_id FK
        numeric current_stock
        numeric min_stock_level
        timestamptz created_at
        timestamptz updated_at
    }

    INTERMEDIARIES {
        int id PK
        text sku UK
        text description
        numeric current_stock
        numeric min_stock_level
        timestamptz created_at
        timestamptz updated_at
    }

    FINISHED_PRODUCTS {
        int id PK
        text sku UK
        text description
        int client_id FK
        numeric current_stock
        numeric min_stock_level
        timestamptz created_at
        timestamptz updated_at
    }

    BOM {
        text parent_type PK
        int parent_id PK
        text child_type PK
        int child_id PK
        numeric quantity
    }

    STOCK_TRANSACTIONS {
        int id PK
        int product_id
        text product_type
        int warehouse_id FK
        numeric quantity
        timestamptz transaction_date
    }
```

## Typed relationships

Two important relationships cannot be expressed as ordinary SQL foreign keys
because the destination table depends on a type column.

### BOM

```mermaid
flowchart LR
    FP[finished_products] -. parent_type=finished .-> B[bom]
    I[intermediaries] -. parent_type=intermediate .-> B

    B -. child_type=intermediate .-> I
    B -. child_type=raw .-> R[raw_materials]
```

The database enforces those references through `trg_check_bom_references`.

### Stock transactions

```mermaid
flowchart LR
    R[raw_materials] -. product_type=raw .-> T[stock_transactions]
    I[intermediaries] -. product_type=intermediate .-> T
    F[finished_products] -. product_type=finished .-> T
    W[warehouses] --> T
```

The typed product reference is checked by `trg_check_stock_before_insert`.

## Physical vs logical relationships

The solid relationships in the ER diagram correspond to physical foreign keys:

- `raw_materials.supplier_id -> suppliers.id`
- `finished_products.client_id -> clients.id`
- `stock_transactions.warehouse_id -> warehouses.id`

The BOM and stock-product links are logical typed relationships and are
validated by database functions and triggers.

For column-level details, see the [Schema Reference](SCHEMA.md).

The older editable draw.io source remains available as
[`ERD.drawio`](ERD.drawio), but the Mermaid diagram above is the preferred
version-controlled source for the documentation site.
