-- Sample seed data for finished products
INSERT INTO finished_products (sku, description, client_id) VALUES
  ('BIKE001', 'Bicycle', (SELECT id FROM clients WHERE name = 'Client X'));
