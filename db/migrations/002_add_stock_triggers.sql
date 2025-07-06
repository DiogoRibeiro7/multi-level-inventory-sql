-- 002_add_stock_triggers.sql
-- Adds stock columns and triggers for stock management

BEGIN;

ALTER TABLE raw_materials
    ADD COLUMN current_stock NUMERIC NOT NULL DEFAULT 0;

ALTER TABLE intermediaries
    ADD COLUMN current_stock NUMERIC NOT NULL DEFAULT 0;

ALTER TABLE finished_products
    ADD COLUMN current_stock NUMERIC NOT NULL DEFAULT 0;

-- Function: check_stock_before_insert
CREATE OR REPLACE FUNCTION check_stock_before_insert()
RETURNS TRIGGER AS $$
DECLARE
    available NUMERIC;
BEGIN
    IF NEW.product_type = 'raw' THEN
        SELECT current_stock INTO available FROM raw_materials WHERE id = NEW.product_id;
    ELSIF NEW.product_type = 'intermediate' THEN
        SELECT current_stock INTO available FROM intermediaries WHERE id = NEW.product_id;
    ELSE
        SELECT current_stock INTO available FROM finished_products WHERE id = NEW.product_id;
    END IF;

    IF available + NEW.quantity < 0 THEN
        RAISE EXCEPTION 'Insufficient stock for product %', NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function: update_current_stock_after_insert
CREATE OR REPLACE FUNCTION update_current_stock_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.product_type = 'raw' THEN
        UPDATE raw_materials SET current_stock = current_stock + NEW.quantity WHERE id = NEW.product_id;
    ELSIF NEW.product_type = 'intermediate' THEN
        UPDATE intermediaries SET current_stock = current_stock + NEW.quantity WHERE id = NEW.product_id;
    ELSE
        UPDATE finished_products SET current_stock = current_stock + NEW.quantity WHERE id = NEW.product_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_stock_before_insert
BEFORE INSERT ON stock_transactions
FOR EACH ROW EXECUTE FUNCTION check_stock_before_insert();

CREATE TRIGGER trg_update_current_stock
AFTER INSERT ON stock_transactions
FOR EACH ROW EXECUTE FUNCTION update_current_stock_after_insert();

COMMIT;

-- Down
-- BEGIN;
-- DROP TRIGGER IF EXISTS trg_update_current_stock ON stock_transactions;
-- DROP TRIGGER IF EXISTS trg_check_stock_before_insert ON stock_transactions;
-- DROP FUNCTION IF EXISTS update_current_stock_after_insert();
-- DROP FUNCTION IF EXISTS check_stock_before_insert();
-- ALTER TABLE finished_products DROP COLUMN IF EXISTS current_stock;
-- ALTER TABLE intermediaries DROP COLUMN IF EXISTS current_stock;
-- ALTER TABLE raw_materials DROP COLUMN IF EXISTS current_stock;
-- COMMIT;

