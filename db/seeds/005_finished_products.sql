-- Sample seed data for finished products
INSERT INTO finished_products (sku, description, client_id)
VALUES
  ('BIKE001', 'Standard Bicycle', (SELECT id FROM clients WHERE name = 'Client X')),
  ('BIKE002', 'Deluxe Bicycle', (SELECT id FROM clients WHERE name = 'Client Y')),
  ('BIKE003', 'Mountain Bicycle', (SELECT id FROM clients WHERE name = 'Client Z')),
  ('BIKE004', 'Kids Bicycle', (SELECT id FROM clients WHERE name = 'Client W')),
  ('BIKE005', 'Electric Bicycle', (SELECT id FROM clients WHERE name = 'Client V'))
ON CONFLICT (sku) DO NOTHING;
