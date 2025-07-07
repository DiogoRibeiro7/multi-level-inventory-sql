-- create_production_run
-- Produces finished goods and deducts required intermediaries.

CREATE OR REPLACE FUNCTION create_production_run(p_product_id INTEGER, p_quantity NUMERIC)
RETURNS VOID AS $$
DECLARE
    component RECORD;
BEGIN
    FOR component IN SELECT child_id, quantity FROM bom WHERE parent_id = p_product_id
    LOOP
        INSERT INTO stock_transactions(product_id, product_type, quantity)
        VALUES (component.child_id, 'intermediate', -component.quantity * p_quantity);
    END LOOP;

    INSERT INTO stock_transactions(product_id, product_type, quantity)
    VALUES (p_product_id, 'finished', p_quantity);
END;
$$ LANGUAGE plpgsql;
