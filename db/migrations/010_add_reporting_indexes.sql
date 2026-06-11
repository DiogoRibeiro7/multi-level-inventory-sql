-- 010_add_reporting_indexes.sql
-- Adds indexes used by transaction history and product lookup queries

BEGIN;

CREATE INDEX IF NOT EXISTS idx_stock_transactions_transaction_date
ON stock_transactions (transaction_date);

CREATE INDEX IF NOT EXISTS idx_stock_transactions_product_lookup
ON stock_transactions (product_type, product_id);

COMMIT;

-- Down
-- BEGIN;
-- DROP INDEX IF EXISTS idx_stock_transactions_product_lookup;
-- DROP INDEX IF EXISTS idx_stock_transactions_transaction_date;
-- COMMIT;
