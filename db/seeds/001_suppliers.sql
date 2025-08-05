-- Sample suppliers
INSERT INTO suppliers (name)
SELECT v.name
FROM (VALUES
  ('Supplier A'),
  ('Supplier B'),
  ('Supplier C'),
  ('Supplier D'),
  ('Supplier E'),
  ('Supplier F')
) AS v(name)
WHERE NOT EXISTS (
  SELECT 1 FROM suppliers s WHERE s.name = v.name
);
