BEGIN;
SELECT plan(1);
SELECT has_function('public', 'create_production_run', ARRAY['integer','numeric'], 'Function exists');
SELECT finish();
ROLLBACK;
