-- Sample clients
INSERT INTO clients (name)
SELECT v.name
FROM (VALUES
  ('Client X'),
  ('Client Y'),
  ('Client Z'),
  ('Client W'),
  ('Client V'),
  ('Client U')
) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM clients c WHERE c.name = v.name
);
