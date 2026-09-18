-- 001_create_schema.sql
-- Creates initial tables for inventory management

BEGIN;

CREATE TABLE raw_materials (
    id SERIAL PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE intermediaries (
    id SERIAL PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE finished_products (
    id SERIAL PRIMARY KEY,
    sku TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE bom (
    parent_id INTEGER NOT NULL,
    child_id INTEGER NOT NULL,
    quantity NUMERIC NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (parent_id, child_id),
    FOREIGN KEY (parent_id) REFERENCES finished_products(id) ON DELETE CASCADE,
    FOREIGN KEY (child_id) REFERENCES intermediaries(id) ON DELETE CASCADE
);

CREATE TABLE stock_transactions (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    product_type TEXT NOT NULL CHECK (product_type IN ('raw','intermediate','finished')),
    quantity NUMERIC NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (product_id) REFERENCES finished_products(id)
);

COMMIT;

-- Down
-- BEGIN;
-- DROP TABLE IF EXISTS stock_transactions;
-- DROP TABLE IF EXISTS bom;
-- DROP TABLE IF EXISTS finished_products;
-- DROP TABLE IF EXISTS intermediaries;
-- DROP TABLE IF EXISTS raw_materials;
-- COMMIT;
