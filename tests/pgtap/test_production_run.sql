BEGIN;
SELECT plan(7);

SELECT has_function('public', 'create_production_run', ARRAY['integer','numeric'], 'Function exists');

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

SELECT throws_ok(
  $$
    SELECT create_production_run(
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      0::numeric
    );
  $$,
  'P0001',
  'Production quantity must be greater than zero',
  'Rejects zero-quantity production runs'
);

SELECT finish();
ROLLBACK;
