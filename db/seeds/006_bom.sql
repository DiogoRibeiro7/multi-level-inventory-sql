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
WHERE fp.sku = 'BIKE001'
ON CONFLICT (parent_id, child_id) DO NOTHING;

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
WHERE fp.sku = 'BIKE002'
ON CONFLICT (parent_id, child_id) DO NOTHING;

-- Mountain bicycle with extra components
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, q.qty
FROM finished_products fp
JOIN (VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1),
    ('PEDAL001', 1),
    ('CHAIN001', 1),
    ('BRAKE001', 2)
) AS q(sku, qty) ON TRUE
JOIN intermediaries i ON i.sku = q.sku
WHERE fp.sku = 'BIKE003'
ON CONFLICT (parent_id, child_id) DO NOTHING;

-- Kids bicycle
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, q.qty
FROM finished_products fp
JOIN (VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1),
    ('PEDAL001', 1),
    ('BRAKE001', 2)
) AS q(sku, qty) ON TRUE
JOIN intermediaries i ON i.sku = q.sku
WHERE fp.sku = 'BIKE004'
ON CONFLICT (parent_id, child_id) DO NOTHING;

-- Electric bicycle with lighting kit
INSERT INTO bom (parent_id, child_id, quantity)
SELECT fp.id, i.id, q.qty
FROM finished_products fp
JOIN (VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1),
    ('PEDAL001', 1),
    ('CHAIN001', 1),
    ('BRAKE001', 2),
    ('LIGHT001', 1)
) AS q(sku, qty) ON TRUE
JOIN intermediaries i ON i.sku = q.sku
WHERE fp.sku = 'BIKE005'
ON CONFLICT (parent_id, child_id) DO NOTHING;
