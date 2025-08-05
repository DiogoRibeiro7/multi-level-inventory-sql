-- Set minimum stock thresholds so reorder_alerts can demonstrate results

-- Raw materials
UPDATE raw_materials SET min_stock_level = 120 WHERE sku = 'STEEL001';
UPDATE raw_materials SET min_stock_level = 50  WHERE sku = 'PLAST001';
UPDATE raw_materials SET min_stock_level = 100 WHERE sku = 'ALUM001';
UPDATE raw_materials SET min_stock_level = 80  WHERE sku = 'RUBB001';
UPDATE raw_materials SET min_stock_level = 20  WHERE sku = 'LEAT001';
UPDATE raw_materials SET min_stock_level = 100 WHERE sku = 'COPP001';
UPDATE raw_materials SET min_stock_level = 40  WHERE sku = 'GLAS001';
UPDATE raw_materials SET min_stock_level = 30  WHERE sku = 'PAIN001';
UPDATE raw_materials SET min_stock_level = 200 WHERE sku = 'SCREW001';
UPDATE raw_materials SET min_stock_level = 150 WHERE sku = 'BOLT001';

-- Intermediaries
UPDATE intermediaries SET min_stock_level = 20 WHERE sku = 'FRAME001';
UPDATE intermediaries SET min_stock_level = 30 WHERE sku = 'WHEEL001';
UPDATE intermediaries SET min_stock_level = 30 WHERE sku = 'SEAT001';
UPDATE intermediaries SET min_stock_level = 30 WHERE sku = 'HANDLE001';
UPDATE intermediaries SET min_stock_level = 25 WHERE sku = 'PEDAL001';
UPDATE intermediaries SET min_stock_level = 15 WHERE sku = 'CHAIN001';
UPDATE intermediaries SET min_stock_level = 35 WHERE sku = 'BRAKE001';
UPDATE intermediaries SET min_stock_level = 10 WHERE sku = 'LIGHT001';

-- Finished goods
UPDATE finished_products SET min_stock_level = 2  WHERE sku = 'BIKE001';
UPDATE finished_products SET min_stock_level = 10 WHERE sku = 'BIKE002';
UPDATE finished_products SET min_stock_level = 5  WHERE sku = 'BIKE003';
UPDATE finished_products SET min_stock_level = 8  WHERE sku = 'BIKE004';
UPDATE finished_products SET min_stock_level = 1  WHERE sku = 'BIKE005';
