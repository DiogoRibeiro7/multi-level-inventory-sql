-- 003_create_views.sql
-- Adds reporting views

BEGIN;

-- View showing current stock across all item types
CREATE OR REPLACE VIEW stock_on_hand AS
SELECT id, sku, description, current_stock, 'raw' AS product_type
FROM raw_materials
UNION ALL
SELECT id, sku, description, current_stock, 'intermediate' AS product_type
FROM intermediaries
UNION ALL
SELECT id, sku, description, current_stock, 'finished' AS product_type
FROM finished_products;

COMMIT;

-- Down
-- BEGIN;
-- DROP VIEW IF EXISTS stock_on_hand;
-- COMMIT;

