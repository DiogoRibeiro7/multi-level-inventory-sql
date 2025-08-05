BEGIN;
SELECT plan(4);

SELECT is(
  (SELECT count(*) FROM stock_on_hand),
  11,
  'stock_on_hand lists all products'
);

SELECT is(
  (SELECT count(*) FROM reorder_alerts),
  2,
  'reorder_alerts shows items below threshold'
);

SELECT ok(
  EXISTS(SELECT 1 FROM reorder_alerts WHERE sku='STEEL001' AND product_type='raw'),
  'Steel sheet needs reordering'
);

SELECT ok(
  EXISTS(SELECT 1 FROM reorder_alerts WHERE sku='BIKE002' AND product_type='finished'),
  'Bike model 002 needs reordering'
);

SELECT finish();
ROLLBACK;
