-- Sample seed data for raw materials
INSERT INTO raw_materials (sku, description, supplier_id) VALUES
  ('STEEL001', 'Steel Sheet', (SELECT id FROM suppliers WHERE name = 'Supplier A')),
  ('PLAST001', 'Plastic Pellets', (SELECT id FROM suppliers WHERE name = 'Supplier B'));
