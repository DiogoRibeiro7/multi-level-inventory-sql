BEGIN;
SELECT plan(4);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'FRAME001'),
  1::numeric,
  'Frame quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'WHEEL001'),
  2::numeric,
  'Wheel quantity is 2'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'SEAT001'),
  1::numeric,
  'Seat quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'HANDLE001'),
  1::numeric,
  'Handlebar quantity is 1'
);

SELECT finish();
ROLLBACK;
