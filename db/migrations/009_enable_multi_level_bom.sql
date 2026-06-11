-- 009_enable_multi_level_bom.sql
-- Adds typed BOM relationships for true multi-level component tracking

BEGIN;

ALTER TABLE bom
ADD COLUMN parent_type TEXT,
ADD COLUMN child_type TEXT;

UPDATE bom
SET
    parent_type = 'finished',
    child_type = 'intermediate'
WHERE
    parent_type IS NULL
    AND child_type IS NULL;

ALTER TABLE bom
ALTER COLUMN parent_type SET NOT NULL,
ALTER COLUMN child_type SET NOT NULL;

ALTER TABLE bom
DROP CONSTRAINT IF EXISTS bom_parent_id_fkey,
DROP CONSTRAINT IF EXISTS bom_child_id_fkey,
DROP CONSTRAINT IF EXISTS bom_pkey;

ALTER TABLE bom
ADD CONSTRAINT bom_pkey PRIMARY KEY (
    parent_type, parent_id, child_type, child_id
),
ADD CONSTRAINT bom_parent_type_check CHECK (
    parent_type IN ('intermediate', 'finished')
),
ADD CONSTRAINT bom_child_type_check CHECK (
    child_type IN ('raw', 'intermediate')
),
ADD CONSTRAINT bom_no_self_reference_check CHECK (
    NOT (
        parent_type = 'intermediate'
        AND child_type = 'intermediate'
        AND parent_id = child_id
    )
);

CREATE OR REPLACE FUNCTION validate_bom_reference(
    p_item_type TEXT, p_item_id INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    IF p_item_type = 'raw' THEN
        RETURN EXISTS (SELECT 1 FROM raw_materials WHERE id = p_item_id);
    ELSIF p_item_type = 'intermediate' THEN
        RETURN EXISTS (SELECT 1 FROM intermediaries WHERE id = p_item_id);
    ELSIF p_item_type = 'finished' THEN
        RETURN EXISTS (SELECT 1 FROM finished_products WHERE id = p_item_id);
    END IF;

    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_bom_references()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_type = 'raw' THEN
        RAISE EXCEPTION 'Raw materials cannot be BOM parents';
    END IF;

    IF NEW.child_type = 'finished' THEN
        RAISE EXCEPTION 'Finished products cannot be BOM children';
    END IF;

    IF NOT validate_bom_reference(NEW.parent_type, NEW.parent_id) THEN
        RAISE EXCEPTION 'Unknown BOM parent: type=% id=%', NEW.parent_type, NEW.parent_id;
    END IF;

    IF NOT validate_bom_reference(NEW.child_type, NEW.child_id) THEN
        RAISE EXCEPTION 'Unknown BOM child: type=% id=%', NEW.child_type, NEW.child_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_bom_references ON bom;

CREATE TRIGGER trg_check_bom_references
BEFORE INSERT OR UPDATE ON bom
FOR EACH ROW EXECUTE FUNCTION check_bom_references();

DROP FUNCTION IF EXISTS bom_explosion(INTEGER);

CREATE FUNCTION bom_explosion(p_parent_id INTEGER)
RETURNS TABLE (child_id INTEGER, child_type TEXT, quantity NUMERIC) AS $$
    WITH RECURSIVE bom_tree AS (
        SELECT
            b.parent_type,
            b.parent_id,
            b.child_type,
            b.child_id,
            b.quantity,
            ARRAY[format('%s:%s', b.parent_type, b.parent_id), format('%s:%s', b.child_type, b.child_id)]::TEXT[] AS path
        FROM bom b
        WHERE b.parent_type = 'finished'
          AND b.parent_id = p_parent_id

        UNION ALL

        SELECT
            b.parent_type,
            b.parent_id,
            b.child_type,
            b.child_id,
            bt.quantity * b.quantity,
            bt.path || format('%s:%s', b.child_type, b.child_id)
        FROM bom_tree bt
        JOIN bom b
          ON b.parent_type = bt.child_type
         AND b.parent_id = bt.child_id
        WHERE NOT format('%s:%s', b.child_type, b.child_id) = ANY(bt.path)
    )
    SELECT
        child_id,
        child_type,
        SUM(quantity) AS quantity
    FROM bom_tree
    GROUP BY child_type, child_id
    ORDER BY child_type, child_id;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION create_production_run(
    p_product_id INTEGER, p_quantity NUMERIC
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
        INSERT INTO stock_transactions(product_id, product_type, quantity)
        VALUES (component.child_id, component.child_type, -component.quantity * p_quantity);
    END LOOP;

    INSERT INTO stock_transactions(product_id, product_type, quantity)
    VALUES (p_product_id, 'finished', p_quantity);
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- Down
-- BEGIN;
-- DROP TRIGGER IF EXISTS trg_check_bom_references ON bom;
-- DROP FUNCTION IF EXISTS check_bom_references();
-- DROP FUNCTION IF EXISTS validate_bom_reference(text, integer);
-- COMMIT;
