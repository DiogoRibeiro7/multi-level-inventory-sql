BEGIN;
SELECT plan(3);

SELECT throws_ok(
  $$
    INSERT INTO stock_transactions (
      product_id,
      product_type,
      quantity,
      warehouse_id
    )
    VALUES (
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      'finished',
      -11,
      (SELECT id FROM warehouses WHERE code = 'MAIN')
    );
  $$,
  'P0001',
  format(
    'Insufficient stock for product %s',
    (SELECT id FROM finished_products WHERE sku = 'BIKE001')
  ),
  'Global stock invariant still rejects an excessive withdrawal'
);

INSERT INTO stock_transactions (
  product_id,
  product_type,
  quantity,
  warehouse_id
)
VALUES (
  (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
  'finished',
  5,
  (SELECT id FROM warehouses WHERE code = 'AUX')
);

SELECT throws_ok(
  $$
    INSERT INTO stock_transactions (
      product_id,
      product_type,
      quantity,
      warehouse_id
    )
    VALUES (
      (SELECT id FROM finished_products WHERE sku = 'BIKE001'),
      'finished',
      -6,
      (SELECT id FROM warehouses WHERE code = 'AUX')
    );
  $$,
  'P0001',
  format(
    'Insufficient warehouse stock for product %s',
    (SELECT id FROM finished_products WHERE sku = 'BIKE001')
  ),
  'Warehouse withdrawal cannot exceed the warehouse balance'
);

SELECT is(
  (
    SELECT current_stock
    FROM stock_on_hand_by_warehouse
    WHERE product_type = 'finished'
      AND sku = 'BIKE001'
      AND warehouse_code = 'AUX'
  ),
  5::numeric,
  'Rejected withdrawal leaves the warehouse balance unchanged'
);

SELECT finish();
ROLLBACK;
