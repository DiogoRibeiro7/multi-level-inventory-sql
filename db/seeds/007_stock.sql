-- Initial stock levels

-- Raw materials
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 100 FROM raw_materials WHERE sku = 'STEEL001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 200 FROM raw_materials WHERE sku = 'PLAST001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 150 FROM raw_materials WHERE sku = 'ALUM001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 100 FROM raw_materials WHERE sku = 'RUBB001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'raw', 50 FROM raw_materials WHERE sku = 'LEAT001';

-- Intermediary stock
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'intermediate', 50 FROM intermediaries WHERE sku = 'FRAME001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'intermediate', 50 FROM intermediaries WHERE sku = 'WHEEL001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'intermediate', 50 FROM intermediaries WHERE sku = 'SEAT001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'intermediate', 50 FROM intermediaries WHERE sku = 'HANDLE001';

-- Finished goods
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'finished', 10 FROM finished_products WHERE sku = 'BIKE001';
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT id, 'finished', 5 FROM finished_products WHERE sku = 'BIKE002';
