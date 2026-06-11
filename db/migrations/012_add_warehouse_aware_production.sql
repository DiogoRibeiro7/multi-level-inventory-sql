-- 012_add_warehouse_aware_production.sql
-- Adds a warehouse-aware production-run overload

BEGIN;

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

CREATE OR REPLACE FUNCTION create_production_run(
    p_product_id INTEGER,
    p_quantity NUMERIC
)
RETURNS VOID AS $$
DECLARE
    default_warehouse_id INTEGER;
BEGIN
    SELECT id
    INTO default_warehouse_id
    FROM warehouses
    WHERE code = 'MAIN';

    PERFORM create_production_run(
        p_product_id,
        p_quantity,
        default_warehouse_id
    );
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Down
-- BEGIN;
-- DROP FUNCTION IF EXISTS create_production_run(integer, numeric, integer);
-- COMMIT;
