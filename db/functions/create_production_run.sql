-- create_production_run
-- Produces finished goods and deducts required intermediaries.

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
