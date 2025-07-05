-- 005_remove_stock_fk.sql
-- Remove FK from stock_transactions to allow referencing any product type
BEGIN;
ALTER TABLE stock_transactions
DROP CONSTRAINT IF EXISTS stock_transactions_product_id_fkey;
COMMIT;
