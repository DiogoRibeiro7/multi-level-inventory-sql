-- Seed warehouse metadata and assign historical stock to the main warehouse

INSERT INTO warehouses (code, warehouse_name)
VALUES
('MAIN', 'Main Warehouse'),
('AUX', 'Overflow Warehouse');

UPDATE stock_transactions
SET
    warehouse_id = (
        SELECT id
        FROM warehouses
        WHERE code = 'MAIN'
    )
WHERE warehouse_id IS NULL;
