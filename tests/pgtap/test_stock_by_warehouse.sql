BEGIN;
SELECT plan(4);

SELECT is(
  (
    SELECT COUNT(*)
    FROM warehouses
  ),
  2::bigint,
  'Seeded two warehouses'
);

SELECT is(
  (
    SELECT warehouse_code
    FROM stock_on_hand_by_warehouse
    WHERE product_type = 'finished'
      AND sku = 'BIKE001'
  ),
  'MAIN',
  'Finished stock is assigned to the main warehouse'
);

SELECT is(
  (
    SELECT current_stock
    FROM stock_on_hand_by_warehouse
    WHERE product_type = 'finished'
      AND sku = 'BIKE001'
      AND warehouse_code = 'MAIN'
  ),
  10::numeric,
  'Warehouse stock view reports bike inventory for the main warehouse'
);

SELECT is(
  (
    SELECT SUM(current_stock)
    FROM stock_on_hand_by_warehouse
    WHERE product_type = 'raw'
      AND sku = 'STEEL001'
  ),
  (
    SELECT current_stock
    FROM raw_materials
    WHERE sku = 'STEEL001'
  ),
  'Warehouse-level totals reconcile to the global stock balance'
);

SELECT finish();
ROLLBACK;
