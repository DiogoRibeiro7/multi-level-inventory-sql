-- Bill of materials linking bikes to required intermediary components

-- Standard bicycle
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, q.qty
FROM finished_products fp
JOIN (VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1)
) AS q(sku, qty) ON TRUE
JOIN intermediaries i ON i.sku = q.sku
WHERE fp.sku = 'BIKE001';

-- Deluxe bicycle uses same components
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, q.qty
FROM finished_products fp
JOIN (VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1)
) AS q(sku, qty) ON TRUE
JOIN intermediaries i ON i.sku = q.sku
WHERE fp.sku = 'BIKE002';
