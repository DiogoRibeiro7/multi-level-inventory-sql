BEGIN;
SELECT plan(3);

-- Attempt to over-consume a raw material beyond available stock
SELECT throws_ok(
  $$
    INSERT INTO stock_transactions (product_id, product_type, quantity)
    VALUES ((SELECT id FROM raw_materials WHERE sku = 'STEEL001'), 'raw', -200);
  $$,
  'P0001',
  'Insufficient stock for product 1',
  'Prevents inserting transaction that results in negative stock'
);

-- Verify current_stock updates after a valid transaction
CREATE TEMP TABLE before AS
SELECT current_stock FROM raw_materials WHERE sku = 'STEEL001';

INSERT INTO stock_transactions (product_id, product_type, quantity)
VALUES ((SELECT id FROM raw_materials WHERE sku = 'STEEL001'), 'raw', 5);

SELECT is(
  (SELECT current_stock FROM raw_materials WHERE sku = 'STEEL001'),
  (SELECT current_stock + 5 FROM before),
  'current_stock increases by 5 after insert'
);

SELECT throws_ok(
  $$
    INSERT INTO stock_transactions (product_id, product_type, quantity)
    VALUES (999999, 'raw', 1);
  $$,
  'P0001',
  'Unknown product reference: type=raw id=999999',
  'Rejects stock transactions for unknown product references'
);

SELECT finish();
ROLLBACK;
