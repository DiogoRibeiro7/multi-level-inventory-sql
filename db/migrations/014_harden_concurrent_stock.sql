-- 014_harden_concurrent_stock.sql
-- Serializes stock validation per product and enforces warehouse balances

BEGIN;

CREATE OR REPLACE FUNCTION check_stock_before_insert()
RETURNS TRIGGER AS $$
DECLARE
    available NUMERIC;
    warehouse_available NUMERIC;
BEGIN
    IF NEW.product_type = 'raw' THEN
        SELECT current_stock
        INTO available
        FROM raw_materials
        WHERE id = NEW.product_id
        FOR UPDATE;
    ELSIF NEW.product_type = 'intermediate' THEN
        SELECT current_stock
        INTO available
        FROM intermediaries
        WHERE id = NEW.product_id
        FOR UPDATE;
    ELSIF NEW.product_type = 'finished' THEN
        SELECT current_stock
        INTO available
        FROM finished_products
        WHERE id = NEW.product_id
        FOR UPDATE;
    ELSE
        RAISE EXCEPTION 'Unsupported product type %', NEW.product_type;
    END IF;

    IF available IS NULL THEN
        RAISE EXCEPTION
            'Unknown product reference: type=% id=%',
            NEW.product_type,
            NEW.product_id;
    END IF;

    IF available + NEW.quantity < 0 THEN
        RAISE EXCEPTION 'Insufficient stock for product %', NEW.product_id;
    END IF;

    IF NEW.warehouse_id IS NOT NULL AND NEW.quantity < 0 THEN
        SELECT COALESCE(SUM(quantity), 0)
        INTO warehouse_available
        FROM stock_transactions
        WHERE warehouse_id = NEW.warehouse_id
          AND product_type = NEW.product_type
          AND product_id = NEW.product_id;

        IF warehouse_available + NEW.quantity < 0 THEN
            RAISE EXCEPTION
                'Insufficient warehouse stock for product %',
                NEW.product_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_production_run(
    p_product_id INTEGER,
    p_quantity NUMERIC,
    p_warehouse_id INTEGER
)
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

    IF p_warehouse_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM warehouses
           WHERE id = p_warehouse_id
       ) THEN
        RAISE EXCEPTION 'Unknown warehouse %', p_warehouse_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM bom
        WHERE parent_type = 'finished'
          AND parent_id = p_product_id
    ) THEN
        RAISE EXCEPTION 'No BOM defined for finished product %', p_product_id;
    END IF;

    FOR component IN
        SELECT child_id, child_type, quantity
        FROM bom
        WHERE parent_type = 'finished'
          AND parent_id = p_product_id
        ORDER BY child_type, child_id
    LOOP
        INSERT INTO stock_transactions (
            product_id,
            product_type,
            quantity,
            warehouse_id
        )
        VALUES (
            component.child_id,
            component.child_type,
            -component.quantity * p_quantity,
            p_warehouse_id
        );
    END LOOP;

    INSERT INTO stock_transactions (
        product_id,
        product_type,
        quantity,
        warehouse_id
    )
    VALUES (
        p_product_id,
        'finished',
        p_quantity,
        p_warehouse_id
    );
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Down
-- BEGIN;
-- Reapply the previous definitions from migrations 008 and 012 if required.
-- COMMIT;
