BEGIN;
SELECT plan(6);
SELECT has_function('public', 'create_production_run', ARRAY['integer','numeric'], 'Function exists');
SELECT public.create_production_run((SELECT id FROM finished_products WHERE sku='BIKE001'), 2);
SELECT ok(EXISTS(
  SELECT 1 FROM stock_transactions st
  WHERE st.product_id = (SELECT id FROM intermediaries WHERE sku='FRAME001')
    AND st.product_type='intermediate' AND st.quantity = -2
), 'Frame stock deducted');
SELECT ok(EXISTS(
  SELECT 1 FROM stock_transactions st
  WHERE st.product_id = (SELECT id FROM intermediaries WHERE sku='WHEEL001')
    AND st.product_type='intermediate' AND st.quantity = -4
), 'Wheel stock deducted');
SELECT ok(EXISTS(
  SELECT 1 FROM stock_transactions st
  WHERE st.product_id = (SELECT id FROM intermediaries WHERE sku='SEAT001')
    AND st.product_type='intermediate' AND st.quantity = -2
), 'Seat stock deducted');
SELECT ok(EXISTS(
  SELECT 1 FROM stock_transactions st
  WHERE st.product_id = (SELECT id FROM intermediaries WHERE sku='HANDLE001')
    AND st.product_type='intermediate' AND st.quantity = -2
), 'Handlebar stock deducted');
SELECT ok(EXISTS(
  SELECT 1 FROM stock_transactions st
  WHERE st.product_id = (SELECT id FROM finished_products WHERE sku='BIKE001')
    AND st.product_type='finished' AND st.quantity = 2
), 'Finished goods added');
SELECT finish();
ROLLBACK;
