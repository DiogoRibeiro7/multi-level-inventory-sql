BEGIN;
SELECT plan(4);

SELECT is(
  (
    SELECT COUNT(*)
    FROM raw_materials
    WHERE current_stock < 0
  ),
  0::bigint,
  'Raw materials have no negative balances'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM intermediaries
    WHERE current_stock < 0
  ),
  0::bigint,
  'Intermediaries have no negative balances'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM finished_products
    WHERE current_stock < 0
  ),
  0::bigint,
  'Finished products have no negative balances'
);

SELECT is(
  (
    SELECT COUNT(*)
    FROM stock_on_hand
    WHERE current_stock < 0
  ),
  0::bigint,
  'The stock_on_hand view contains no negative balances'
);

SELECT finish();
ROLLBACK;
