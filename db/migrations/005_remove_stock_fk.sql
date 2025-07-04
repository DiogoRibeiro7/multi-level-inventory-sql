-- 005_remove_stock_fk.sql
-- Drops the foreign key from stock_transactions so it can reference any product type
BEGIN;
ALTER TABLE stock_transactions DROP CONSTRAINT IF EXISTS stock_transactions_product_id_fkey;
COMMIT;
