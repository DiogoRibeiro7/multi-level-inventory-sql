-- 007_create_bom_explosion_function.sql
-- Adds a function to explode a BOM and return its components
BEGIN;

CREATE OR REPLACE FUNCTION bom_explosion(p_parent_id INTEGER)
RETURNS TABLE (child_id INTEGER, quantity NUMERIC) AS $$
    WITH RECURSIVE bom_tree AS (
        SELECT child_id, quantity
        FROM bom
        WHERE parent_id = p_parent_id
      UNION ALL
        SELECT b.child_id, b.quantity * t.quantity
        FROM bom b
        JOIN bom_tree t ON b.parent_id = t.child_id
    )
    SELECT child_id, SUM(quantity) AS quantity
    FROM bom_tree
    GROUP BY child_id;
$$ LANGUAGE sql;

COMMIT;
