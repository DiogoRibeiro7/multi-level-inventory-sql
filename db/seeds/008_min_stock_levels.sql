-- Set minimum stock levels for reorder alerts

-- Raw materials
UPDATE raw_materials SET min_stock_level = 50 WHERE sku = 'STEEL001';
UPDATE raw_materials SET min_stock_level = 100 WHERE sku = 'PLAST001';
UPDATE raw_materials SET min_stock_level = 75 WHERE sku = 'ALUM001';
UPDATE raw_materials SET min_stock_level = 40 WHERE sku = 'RUBB001';
UPDATE raw_materials SET min_stock_level = 25 WHERE sku = 'LEAT001';

-- Intermediaries
UPDATE intermediaries SET min_stock_level = 20 WHERE sku = 'FRAME001';
UPDATE intermediaries SET min_stock_level = 20 WHERE sku = 'WHEEL001';
UPDATE intermediaries SET min_stock_level = 20 WHERE sku = 'SEAT001';
UPDATE intermediaries SET min_stock_level = 20 WHERE sku = 'HANDLE001';

-- Finished products
UPDATE finished_products SET min_stock_level = 5 WHERE sku = 'BIKE001';
UPDATE finished_products SET min_stock_level = 3 WHERE sku = 'BIKE002';
