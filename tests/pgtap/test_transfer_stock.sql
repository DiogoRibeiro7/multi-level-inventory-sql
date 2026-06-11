BEGIN;
SELECT plan(6);

SELECT has_function(
  'public',
  'transfer_stock',
  ARRAY['integer', 'text', 'numeric', 'integer', 'integer'],
  'transfer_stock function exists'
);

SELECT lives_ok(
  $$
    SELECT transfer_stock(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      'finished',
      2::numeric,
      (SELECT id FROM warehouses WHERE code = 'MAIN'),
      (SELECT id FROM warehouses WHERE code = 'AUX')
    );
  $$,
  'Transfer succeeds for a valid warehouse move'
);

SELECT is(
  (
    SELECT current_stock
    FROM stock_on_hand_by_warehouse
    WHERE warehouse_code = 'MAIN'
      AND product_type = 'finished'
      AND sku = 'BIKE001'
  ),
  8::numeric,
  'Main warehouse stock decreased after transfer'
);

SELECT is(
  (
    SELECT current_stock
    FROM stock_on_hand_by_warehouse
    WHERE warehouse_code = 'AUX'
      AND product_type = 'finished'
      AND sku = 'BIKE001'
  ),
  2::numeric,
  'Destination warehouse stock increased after transfer'
);

SELECT throws_ok(
  $$
    SELECT transfer_stock(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      'finished',
      20::numeric,
      (SELECT id FROM warehouses WHERE code = 'MAIN'),
      (SELECT id FROM warehouses WHERE code = 'AUX')
    );
  $$,
  'P0001',
  'Insufficient warehouse stock for product 1',
  'Transfer rejects overdrawn warehouse moves'
);

SELECT throws_ok(
  $$
    SELECT transfer_stock(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      'finished',
      1::numeric,
      (SELECT id FROM warehouses WHERE code = 'MAIN'),
      (SELECT id FROM warehouses WHERE code = 'MAIN')
    );
  $$,
  'P0001',
  'Source and destination warehouses must differ',
  'Transfer rejects identical source and destination warehouses'
);

SELECT finish();
ROLLBACK;
