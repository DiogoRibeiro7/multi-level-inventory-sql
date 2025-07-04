-- 004_add_partners.sql
-- Adds clients and suppliers tables with relationships

BEGIN;

CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE raw_materials
ADD COLUMN supplier_id INTEGER REFERENCES suppliers (id);

ALTER TABLE finished_products
ADD COLUMN client_id INTEGER REFERENCES clients (id);

COMMIT;
