-- Initial stock levels
-- Raw materials
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 100 FROM raw_materials WHERE sku = 'STEEL001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 200 FROM raw_materials WHERE sku = 'PLAST001';
-- Intermediary stock
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'intermediate', 50 FROM intermediaries WHERE sku = 'FRAME001';
