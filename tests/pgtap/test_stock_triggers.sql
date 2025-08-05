BEGIN;
SELECT plan(2);

SELECT throws_ok(
  $$INSERT INTO stock_transactions (product_id, product_type, quantity)
     VALUES ((SELECT id FROM raw_materials WHERE sku='STEEL001'), 'raw', -1000);$$,
  'Insufficient stock',
  'Stock trigger prevents negative balance'
);

SELECT is(
  (SELECT current_stock FROM raw_materials WHERE sku='STEEL001'),
  100,
  'Stock level unchanged after failed insert'
);

SELECT finish();
ROLLBACK;
