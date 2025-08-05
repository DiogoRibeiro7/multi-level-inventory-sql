-- Initial stock levels

-- Raw materials
WITH materials (sku, qty) AS (
    VALUES
        ('STEEL001', 100),
        ('PLAST001', 200),
        ('ALUM001', 150),
        ('RUBB001', 100),
        ('LEAT001', 50),
        ('COPP001', 120),
        ('GLAS001', 80),
        ('PAIN001', 60),
        ('SCREW001', 500),
        ('BOLT001', 400)
)
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT rm.id, 'raw', m.qty
FROM raw_materials rm
JOIN materials m ON m.sku = rm.sku
WHERE NOT EXISTS (
    SELECT 1 FROM stock_transactions st
    WHERE st.product_id = rm.id
      AND st.product_type = 'raw'
      AND st.quantity = m.qty
);

-- Intermediary stock
WITH intermediates (sku, qty) AS (
    VALUES
        ('FRAME001', 50),
        ('WHEEL001', 50),
        ('SEAT001', 50),
        ('HANDLE001', 50),
        ('PEDAL001', 60),
        ('CHAIN001', 40),
        ('BRAKE001', 70),
        ('LIGHT001', 30)
)
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT i.id, 'intermediate', im.qty
FROM intermediaries i
JOIN intermediates im ON im.sku = i.sku
WHERE NOT EXISTS (
    SELECT 1 FROM stock_transactions st
    WHERE st.product_id = i.id
      AND st.product_type = 'intermediate'
      AND st.quantity = im.qty
);

-- Finished goods
WITH finished (sku, qty) AS (
    VALUES
        ('BIKE001', 10),
        ('BIKE002', 5),
        ('BIKE003', 8),
        ('BIKE004', 15),
        ('BIKE005', 3)
)
INSERT INTO stock_transactions (product_id, product_type, quantity)
SELECT fp.id, 'finished', f.qty
FROM finished_products fp
JOIN finished f ON f.sku = fp.sku
WHERE NOT EXISTS (
    SELECT 1 FROM stock_transactions st
    WHERE st.product_id = fp.id
      AND st.product_type = 'finished'
      AND st.quantity = f.qty
);

