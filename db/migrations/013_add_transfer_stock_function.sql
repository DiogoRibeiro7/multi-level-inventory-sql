-- 013_add_transfer_stock_function.sql
-- Adds an explicit warehouse-to-warehouse stock transfer function

BEGIN;

CREATE OR REPLACE FUNCTION transfer_stock(
    p_product_id INTEGER,
    p_product_type TEXT,
    p_quantity NUMERIC,
    p_from_warehouse_id INTEGER,
    p_to_warehouse_id INTEGER
)
RETURNS VOID AS $$
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION 'Transfer quantity must be greater than zero';
    END IF;

    IF p_product_type NOT IN ('raw', 'intermediate', 'finished') THEN
        RAISE EXCEPTION 'Unsupported product type %', p_product_type;
    END IF;

    IF p_from_warehouse_id = p_to_warehouse_id THEN
        RAISE EXCEPTION 'Source and destination warehouses must differ';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM warehouses
        WHERE id = p_from_warehouse_id
    ) THEN
        RAISE EXCEPTION 'Unknown source warehouse %', p_from_warehouse_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM warehouses
        WHERE id = p_to_warehouse_id
    ) THEN
        RAISE EXCEPTION 'Unknown destination warehouse %', p_to_warehouse_id;
    END IF;

    IF p_product_type = 'raw'
       AND NOT EXISTS (
           SELECT 1
           FROM raw_materials
           WHERE id = p_product_id
       ) THEN
        RAISE EXCEPTION 'Unknown product reference: type=% id=%', p_product_type, p_product_id;
    ELSIF p_product_type = 'intermediate'
          AND NOT EXISTS (
              SELECT 1
              FROM intermediaries
              WHERE id = p_product_id
          ) THEN
        RAISE EXCEPTION 'Unknown product reference: type=% id=%', p_product_type, p_product_id;
    ELSIF p_product_type = 'finished'
          AND NOT EXISTS (
              SELECT 1
              FROM finished_products
              WHERE id = p_product_id
          ) THEN
        RAISE EXCEPTION 'Unknown product reference: type=% id=%', p_product_type, p_product_id;
    END IF;

    IF COALESCE((
        SELECT current_stock
        FROM stock_on_hand_by_warehouse
        WHERE warehouse_id = p_from_warehouse_id
          AND product_type = p_product_type
          AND product_id = p_product_id
    ), 0) < p_quantity THEN
        RAISE EXCEPTION 'Insufficient warehouse stock for product %', p_product_id;
    END IF;

    INSERT INTO stock_transactions (
        product_id,
        product_type,
        quantity,
        warehouse_id
    )
    VALUES (
        p_product_id,
        p_product_type,
        -p_quantity,
        p_from_warehouse_id
    );

    INSERT INTO stock_transactions (
        product_id,
        product_type,
        quantity,
        warehouse_id
    )
    VALUES (
        p_product_id,
        p_product_type,
        p_quantity,
        p_to_warehouse_id
    );
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Down
-- BEGIN;
-- DROP FUNCTION IF EXISTS transfer_stock(
--     integer, text, numeric, integer, integer
-- );
-- COMMIT;
