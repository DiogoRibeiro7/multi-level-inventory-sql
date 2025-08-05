-- Sample seed data for intermediary products
INSERT INTO intermediaries (sku, description)
VALUES
  ('FRAME001', 'Bicycle Frame'),
  ('WHEEL001', 'Wheel Assembly'),
  ('SEAT001', 'Seat Assembly'),
  ('HANDLE001', 'Handlebar'),
  ('PEDAL001', 'Pedal Assembly'),
  ('CHAIN001', 'Chain'),
  ('BRAKE001', 'Brake Set'),
  ('LIGHT001', 'Lighting Kit')
ON CONFLICT (sku) DO NOTHING;
