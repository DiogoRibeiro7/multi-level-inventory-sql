BEGIN;
SELECT no_plan();

-- Core tables
SELECT has_table('suppliers');
SELECT has_table('clients');
SELECT has_table('warehouses');
SELECT has_table('raw_materials');
SELECT has_table('intermediaries');
SELECT has_table('finished_products');
SELECT has_table('bom');
SELECT has_table('stock_transactions');
SELECT has_table('inventory_script_history');

-- Reporting views
SELECT has_view('stock_on_hand');
SELECT has_view('reorder_alerts');
SELECT has_view('stock_on_hand_by_warehouse');

-- Migration ledger contract
SELECT has_column('inventory_script_history', 'script_type');
SELECT has_column('inventory_script_history', 'script_name');
SELECT has_column('inventory_script_history', 'checksum');
SELECT has_column('inventory_script_history', 'applied_at');

-- Public database functions
SELECT has_function(
  'public',
  'bom_explosion',
  ARRAY['integer'],
  'bom_explosion(integer) exists'
);
SELECT has_function(
  'public',
  'create_production_run',
  ARRAY['integer', 'numeric'],
  'create_production_run(integer, numeric) exists'
);
SELECT has_function(
  'public',
  'create_production_run',
  ARRAY['integer', 'numeric', 'integer'],
  'warehouse-aware create_production_run overload exists'
);
SELECT has_function(
  'public',
  'transfer_stock',
  ARRAY['integer', 'text', 'numeric', 'integer', 'integer'],
  'transfer_stock function exists'
);

-- Integrity triggers
SELECT has_trigger(
  'stock_transactions',
  'trg_check_stock_before_insert'
);
SELECT has_trigger(
  'stock_transactions',
  'trg_update_current_stock'
);
SELECT has_trigger(
  'bom',
  'trg_check_bom_references'
);

-- Reporting and lookup indexes
SELECT has_index(
  'stock_transactions',
  'idx_stock_transactions_transaction_date'
);
SELECT has_index(
  'stock_transactions',
  'idx_stock_transactions_product_lookup'
);
SELECT has_index(
  'stock_transactions',
  'idx_stock_transactions_warehouse_lookup'
);

SELECT finish();
ROLLBACK;
