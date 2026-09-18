BEGIN;
SELECT plan(5);

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

-- Stage the direct BOM components in AUX before producing there.
SELECT transfer_stock(
  (SELECT id FROM intermediaries WHERE sku = 'FRAME001'),
  'intermediate',
  1,
  (SELECT id FROM warehouses WHERE code = 'MAIN'),
  (SELECT id FROM warehouses WHERE code = 'AUX')
);
SELECT transfer_stock(
  (SELECT id FROM intermediaries WHERE sku = 'WHEEL001'),
  'intermediate',
  2,
  (SELECT id FROM warehouses WHERE code = 'MAIN'),
  (SELECT id FROM warehouses WHERE code = 'AUX')
);
SELECT transfer_stock(
  (SELECT id FROM intermediaries WHERE sku = 'SEAT001'),
  'intermediate',
  1,
  (SELECT id FROM warehouses WHERE code = 'MAIN'),
  (SELECT id FROM warehouses WHERE code = 'AUX')
);
SELECT transfer_stock(
  (SELECT id FROM intermediaries WHERE sku = 'HANDLE001'),
  'intermediate',
  1,
  (SELECT id FROM warehouses WHERE code = 'MAIN'),
  (SELECT id FROM warehouses WHERE code = 'AUX')
);

SELECT lives_ok(
  $
    SELECT create_production_run(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      1::numeric,
      (SELECT id FROM warehouses WHERE code = 'AUX')
    );
  $,
  'Warehouse-aware production can target AUX when components are available'
);

SELECT finish();
ROLLBACK;
