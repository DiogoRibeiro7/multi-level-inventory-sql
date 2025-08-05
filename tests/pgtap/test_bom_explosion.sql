BEGIN;
SELECT plan(4);

SELECT ok(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'FRAME001') = 1,
  'Frame quantity is 1'
);

SELECT ok(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'WHEEL001') = 2,
  'Wheel quantity is 2'
);

SELECT ok(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'SEAT001') = 1,
  'Seat quantity is 1'
);

SELECT ok(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE i.sku = 'HANDLE001') = 1,
  'Handlebar quantity is 1'
);

SELECT finish();
ROLLBACK;
