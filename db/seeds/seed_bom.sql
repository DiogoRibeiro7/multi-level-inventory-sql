-- Sample bill of materials linking bicycle to frame
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, 1
FROM finished_products fp
JOIN intermediaries i ON i.sku = 'FRAME001'
WHERE fp.sku = 'BIKE001';
