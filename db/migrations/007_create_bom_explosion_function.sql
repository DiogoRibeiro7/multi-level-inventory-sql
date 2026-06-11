-- 007_create_bom_explosion_function.sql
-- Adds a function to explode a BOM and return its components
BEGIN;

CREATE OR REPLACE FUNCTION bom_explosion(p_parent_id INTEGER)
RETURNS TABLE (child_id INTEGER, child_type TEXT, quantity NUMERIC) AS $$
    SELECT child_id, 'intermediate'::TEXT AS child_type, quantity
    FROM bom
    WHERE parent_id = p_parent_id;
$$ LANGUAGE sql;

COMMIT;

-- Down
-- BEGIN;
-- DROP FUNCTION IF EXISTS bom_explosion(integer);
-- COMMIT;
