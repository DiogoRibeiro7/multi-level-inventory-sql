-- 011_add_warehouses.sql
-- Adds warehouse metadata and warehouse-aware stock reporting

BEGIN;

CREATE TABLE warehouses (
    id SERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    warehouse_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE stock_transactions
ADD COLUMN warehouse_id INTEGER REFERENCES warehouses (id);

CREATE INDEX IF NOT EXISTS idx_stock_transactions_warehouse_lookup
ON stock_transactions (warehouse_id, product_type, product_id);

CREATE OR REPLACE VIEW stock_on_hand_by_warehouse AS
SELECT
    st.warehouse_id,
    w.code AS warehouse_code,
    w.warehouse_name,
    rm.id AS product_id,
    rm.sku,
    rm.description,
    'raw'::TEXT AS product_type,
    SUM(st.quantity) AS current_stock
FROM raw_materials AS rm
INNER JOIN stock_transactions AS st
    ON
        rm.id = st.product_id
        AND st.product_type = 'raw'
LEFT JOIN warehouses AS w
    ON st.warehouse_id = w.id
GROUP BY
    st.warehouse_id,
    w.code,
    w.warehouse_name,
    rm.id,
    rm.sku,
    rm.description

UNION ALL

SELECT
    st.warehouse_id,
    w.code AS warehouse_code,
    w.warehouse_name,
    i.id AS product_id,
    i.sku,
    i.description,
    'intermediate'::TEXT AS product_type,
    SUM(st.quantity) AS current_stock
FROM intermediaries AS i
INNER JOIN stock_transactions AS st
    ON
        i.id = st.product_id
        AND st.product_type = 'intermediate'
LEFT JOIN warehouses AS w
    ON st.warehouse_id = w.id
GROUP BY
    st.warehouse_id,
    w.code,
    w.warehouse_name,
    i.id,
    i.sku,
    i.description

UNION ALL

SELECT
    st.warehouse_id,
    w.code AS warehouse_code,
    w.warehouse_name,
    fp.id AS product_id,
    fp.sku,
    fp.description,
    'finished'::TEXT AS product_type,
    SUM(st.quantity) AS current_stock
FROM finished_products AS fp
INNER JOIN stock_transactions AS st
    ON
        fp.id = st.product_id
        AND st.product_type = 'finished'
LEFT JOIN warehouses AS w
    ON st.warehouse_id = w.id
GROUP BY
    st.warehouse_id,
    w.code,
    w.warehouse_name,
    fp.id,
    fp.sku,
    fp.description;

COMMIT;

-- Down
-- BEGIN;
-- DROP VIEW IF EXISTS stock_on_hand_by_warehouse;
-- DROP INDEX IF EXISTS idx_stock_transactions_warehouse_lookup;
-- ALTER TABLE stock_transactions DROP COLUMN IF EXISTS warehouse_id;
-- DROP TABLE IF EXISTS warehouses;
-- COMMIT;
