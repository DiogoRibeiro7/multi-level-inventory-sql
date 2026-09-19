BEGIN;
SELECT plan(11);

SELECT has_function('public', 'create_production_run', ARRAY['integer','numeric'], 'Function exists');
SELECT has_function('public', 'create_production_run', ARRAY['integer','numeric','integer'], 'Warehouse-aware overload exists');

-- Capture starting stock levels
CREATE TEMP TABLE before AS
SELECT
  (SELECT current_stock FROM intermediaries WHERE sku = 'FRAME001') AS frame_stock,
  (SELECT current_stock FROM intermediaries WHERE sku = 'WHEEL001') AS wheel_stock,
  (SELECT current_stock FROM intermediaries WHERE sku = 'SEAT001') AS seat_stock,
  (SELECT current_stock FROM intermediaries WHERE sku = 'HANDLE001') AS handle_stock,
  (SELECT current_stock FROM finished_products WHERE sku = 'BIKE001') AS bike_stock;

-- Run a production batch of 1 standard bicycle
SELECT create_production_run(
    (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
    1::numeric
);

SELECT is(
  (SELECT current_stock FROM intermediaries WHERE sku = 'FRAME001'),
  (SELECT frame_stock - 1 FROM before),
  'Frame stock decreased by 1'
);

SELECT is(
  (SELECT current_stock FROM intermediaries WHERE sku = 'WHEEL001'),
  (SELECT wheel_stock - 2 FROM before),
  'Wheel stock decreased by 2'
);

SELECT is(
  (SELECT current_stock FROM intermediaries WHERE sku = 'SEAT001'),
  (SELECT seat_stock - 1 FROM before),
  'Seat stock decreased by 1'
);

SELECT is(
  (SELECT current_stock FROM intermediaries WHERE sku = 'HANDLE001'),
  (SELECT handle_stock - 1 FROM before),
  'Handle stock decreased by 1'
);

SELECT is(
  (SELECT current_stock FROM finished_products WHERE sku = 'BIKE001'),
  (SELECT bike_stock + 1 FROM before),
  'Finished product stock increased by 1'
);

SELECT is(
  (
    SELECT warehouse_code
    FROM stock_on_hand_by_warehouse
    WHERE product_type = 'finished'
      AND sku = 'BIKE001'
      AND current_stock = (SELECT bike_stock + 1 FROM before)
  ),
  'MAIN',
  'Two-argument production run posts to the main warehouse'
);

SELECT throws_ok(
  $test$
    SELECT create_production_run(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      0::numeric
    );
  $test$,
  'P0001',
  'Production quantity must be greater than zero',
  'Rejects zero-quantity production runs'
);

SELECT throws_ok(
  $test$
    SELECT create_production_run(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      1::numeric,
      999999
    );
  $test$,
  'P0001',
  'Unknown warehouse 999999',
  'Rejects unknown warehouse IDs'
);

-- Move one production batch of components into AUX before producing there.
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
  $test$
    SELECT create_production_run(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      1::numeric,
      (SELECT id FROM warehouses WHERE code = 'AUX')
    );
  $test$,
  'Warehouse-aware production succeeds when AUX has the required components'
);

SELECT finish();
ROLLBACK;
