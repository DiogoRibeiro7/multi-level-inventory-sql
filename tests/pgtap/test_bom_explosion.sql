BEGIN;
SELECT plan(9);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE b.child_type = 'intermediate' AND i.sku = 'FRAME001'),
  1::numeric,
  'Frame quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE b.child_type = 'intermediate' AND i.sku = 'WHEEL001'),
  2::numeric,
  'Wheel quantity is 2'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE b.child_type = 'intermediate' AND i.sku = 'SEAT001'),
  1::numeric,
  'Seat quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN intermediaries i ON i.id = b.child_id
   WHERE b.child_type = 'intermediate' AND i.sku = 'HANDLE001'),
  1::numeric,
  'Handlebar quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN raw_materials rm ON rm.id = b.child_id
   WHERE b.child_type = 'raw' AND rm.sku = 'ALUM001'),
  9::numeric,
  'Aluminum quantity is 9'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN raw_materials rm ON rm.id = b.child_id
   WHERE b.child_type = 'raw' AND rm.sku = 'STEEL001'),
  1::numeric,
  'Steel quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN raw_materials rm ON rm.id = b.child_id
   WHERE b.child_type = 'raw' AND rm.sku = 'RUBB001'),
  4::numeric,
  'Rubber quantity is 4'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN raw_materials rm ON rm.id = b.child_id
   WHERE b.child_type = 'raw' AND rm.sku = 'LEAT001'),
  1::numeric,
  'Leather quantity is 1'
);

SELECT is(
  (SELECT quantity FROM bom_explosion((SELECT id FROM finished_products WHERE sku = 'BIKE001')) AS b
   JOIN raw_materials rm ON rm.id = b.child_id
   WHERE b.child_type = 'raw' AND rm.sku = 'PLAST001'),
  1::numeric,
  'Plastic quantity is 1'
);

SELECT finish();
ROLLBACK;
