-- Bill of materials linking bikes to required intermediary components

-- Standard bicycle
INSERT INTO bom (parent_type, parent_id, child_type, child_id, quantity)
SELECT
    'finished' AS parent_item_type,
    fp.id AS parent_item_id,
    'intermediate' AS child_item_type,
    i.id AS child_item_id,
    q.qty AS component_quantity
FROM finished_products AS fp
INNER JOIN (
    VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1)
) AS q (sku, qty) ON TRUE
INNER JOIN intermediaries AS i ON q.sku = i.sku
WHERE fp.sku = 'BIKE001';

-- Deluxe bicycle uses same components
INSERT INTO bom (parent_type, parent_id, child_type, child_id, quantity)
SELECT
    'finished' AS parent_item_type,
    fp.id AS parent_item_id,
    'intermediate' AS child_item_type,
    i.id AS child_item_id,
    q.qty AS component_quantity
FROM finished_products AS fp
INNER JOIN (
    VALUES
    ('FRAME001', 1),
    ('WHEEL001', 2),
    ('SEAT001', 1),
    ('HANDLE001', 1)
) AS q (sku, qty) ON TRUE
INNER JOIN intermediaries AS i ON q.sku = i.sku
WHERE fp.sku = 'BIKE002';

-- Intermediaries consume raw materials
INSERT INTO bom (parent_type, parent_id, child_type, child_id, quantity)
SELECT
    'intermediate' AS parent_item_type,
    i.id AS parent_item_id,
    'raw' AS child_item_type,
    rm.id AS child_item_id,
    q.qty AS component_quantity
FROM intermediaries AS i
INNER JOIN (
    VALUES
    ('FRAME001', 'ALUM001', 5),
    ('FRAME001', 'STEEL001', 1),
    ('WHEEL001', 'RUBB001', 2),
    ('WHEEL001', 'ALUM001', 1),
    ('SEAT001', 'LEAT001', 1),
    ('SEAT001', 'PLAST001', 1),
    ('HANDLE001', 'ALUM001', 2)
) AS q (parent_sku, child_sku, qty) ON i.sku = q.parent_sku
INNER JOIN raw_materials AS rm ON q.child_sku = rm.sku;
