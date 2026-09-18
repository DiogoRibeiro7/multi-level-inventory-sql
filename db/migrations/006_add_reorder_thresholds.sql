-- 006_add_reorder_thresholds.sql
-- Adds minimum stock level columns and a view for reorder alerts

BEGIN;

ALTER TABLE raw_materials
ADD COLUMN min_stock_level NUMERIC NOT NULL DEFAULT 0;

ALTER TABLE intermediaries
ADD COLUMN min_stock_level NUMERIC NOT NULL DEFAULT 0;

ALTER TABLE finished_products
ADD COLUMN min_stock_level NUMERIC NOT NULL DEFAULT 0;

-- View listing products that have fallen below their minimum stock level
CREATE OR REPLACE VIEW reorder_alerts AS
SELECT
    id,
    sku,
    description,
    current_stock,
    min_stock_level,
    'raw' AS product_type
FROM raw_materials
WHERE current_stock < min_stock_level
UNION ALL
SELECT
    id,
    sku,
    description,
    current_stock,
    min_stock_level,
    'intermediate' AS product_type
FROM intermediaries
WHERE current_stock < min_stock_level
UNION ALL
SELECT
    id,
    sku,
    description,
    current_stock,
    min_stock_level,
    'finished' AS product_type
FROM finished_products
WHERE current_stock < min_stock_level;

COMMIT;

-- Down
-- BEGIN;
-- DROP VIEW IF EXISTS reorder_alerts;
-- ALTER TABLE finished_products DROP COLUMN IF EXISTS min_stock_level;
-- ALTER TABLE intermediaries DROP COLUMN IF EXISTS min_stock_level;
-- ALTER TABLE raw_materials DROP COLUMN IF EXISTS min_stock_level;
-- COMMIT;
