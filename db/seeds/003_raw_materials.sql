-- Sample seed data for raw materials
INSERT INTO raw_materials (sku, description, supplier_id)
VALUES
  ('STEEL001', 'Steel Sheet', (SELECT id FROM suppliers WHERE name = 'Supplier A')),
  ('PLAST001', 'Plastic Pellets', (SELECT id FROM suppliers WHERE name = 'Supplier B')),
  ('ALUM001', 'Aluminum Tubing', (SELECT id FROM suppliers WHERE name = 'Supplier A')),
  ('RUBB001', 'Rubber Strips', (SELECT id FROM suppliers WHERE name = 'Supplier C')),
  ('LEAT001', 'Leather', (SELECT id FROM suppliers WHERE name = 'Supplier D')),
  ('COPP001', 'Copper Wire', (SELECT id FROM suppliers WHERE name = 'Supplier B')),
  ('GLAS001', 'Glass Panel', (SELECT id FROM suppliers WHERE name = 'Supplier D')),
  ('PAIN001', 'Industrial Paint', (SELECT id FROM suppliers WHERE name = 'Supplier E')),
  ('SCREW001', 'Steel Screws', (SELECT id FROM suppliers WHERE name = 'Supplier F')),
  ('BOLT001', 'Hex Bolts', (SELECT id FROM suppliers WHERE name = 'Supplier E'))
ON CONFLICT (sku) DO NOTHING;
