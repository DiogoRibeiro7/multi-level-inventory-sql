-- 008_harden_inventory_logic.sql
-- Deploys production function and hardens stock transaction validation

BEGIN;

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

    IF available IS NULL THEN
        RAISE EXCEPTION 'Unknown product reference: type=% id=%', NEW.product_type, NEW.product_id;
    END IF;

    IF available + NEW.quantity < 0 THEN
        RAISE EXCEPTION 'Insufficient stock for product %', NEW.product_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_current_stock_after_insert()
RETURNS TRIGGER AS $$
DECLARE
    updated_rows INTEGER;
BEGIN
    IF NEW.product_type = 'raw' THEN
        UPDATE raw_materials
        SET current_stock = current_stock + NEW.quantity
        WHERE id = NEW.product_id;
    ELSIF NEW.product_type = 'intermediate' THEN
        UPDATE intermediaries
        SET current_stock = current_stock + NEW.quantity
        WHERE id = NEW.product_id;
    ELSE
        UPDATE finished_products
        SET current_stock = current_stock + NEW.quantity
        WHERE id = NEW.product_id;
    END IF;

    GET DIAGNOSTICS updated_rows = ROW_COUNT;
    IF updated_rows <> 1 THEN
        RAISE EXCEPTION 'Failed to update stock for type=% id=%', NEW.product_type, NEW.product_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_production_run(p_product_id INTEGER, p_quantity NUMERIC)
RETURNS VOID AS $$
DECLARE
    component RECORD;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Production quantity must be greater than zero';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM finished_products
        WHERE id = p_product_id
    ) THEN
        RAISE EXCEPTION 'Unknown finished product %', p_product_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM bom
        WHERE parent_id = p_product_id
    ) THEN
        RAISE EXCEPTION 'No BOM defined for finished product %', p_product_id;
    END IF;

    FOR component IN
        SELECT child_id, quantity
        FROM bom
        WHERE parent_id = p_product_id
    LOOP
        INSERT INTO stock_transactions(product_id, product_type, quantity)
        VALUES (component.child_id, 'intermediate', -component.quantity * p_quantity);
    END LOOP;

    INSERT INTO stock_transactions(product_id, product_type, quantity)
    VALUES (p_product_id, 'finished', p_quantity);
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Down
-- BEGIN;
-- DROP FUNCTION IF EXISTS create_production_run(integer, numeric);
-- COMMIT;
