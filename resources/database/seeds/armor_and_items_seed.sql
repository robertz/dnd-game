-- SRD armor list (base_ac/max_dex_bonus/strength_requirement/stealth_disadvantage
-- per the standard 5e armor table) and a handful of general items.
USE gameserver;
SET NAMES utf8mb4;

INSERT INTO armors (name, armor_type, base_ac, max_dex_bonus, strength_requirement, stealth_disadvantage, weight, cost) VALUES
('Padded',          'light',  11, NULL, NULL,  1, '8 lb',    '5 gp'),
('Leather',         'light',  11, NULL, NULL,  0, '10 lb',   '10 gp'),
('Studded Leather', 'light',  12, NULL, NULL,  0, '13 lb',   '45 gp'),
('Hide',            'medium', 12, 2,    NULL,  0, '12 lb',   '10 gp'),
('Chain Shirt',     'medium', 13, 2,    NULL,  0, '20 lb',   '50 gp'),
('Scale Mail',      'medium', 14, 2,    NULL,  1, '45 lb',   '50 gp'),
('Breastplate',     'medium', 14, 2,    NULL,  0, '20 lb',   '400 gp'),
('Half Plate',      'medium', 15, 2,    NULL,  1, '40 lb',   '750 gp'),
('Ring Mail',       'heavy',  14, 0,    NULL,  1, '40 lb',   '30 gp'),
('Chain Mail',      'heavy',  16, 0,    13,    1, '55 lb',   '75 gp'),
('Splint',          'heavy',  17, 0,    15,    1, '60 lb',   '200 gp'),
('Plate',           'heavy',  18, 0,    15,    1, '65 lb',   '1500 gp'),
('Shield',          'shield', 2,  NULL, NULL,  0, '6 lb',    '10 gp');

INSERT INTO items (name, item_type, description, weight, cost) VALUES
('Potion of Healing', 'consumable', 'Regain 2d4+2 hit points when consumed.', '0.5 lb', '50 gp'),
('Rations',           'consumable', 'One day of food.', '2 lb', '5 sp'),
('Torch',             'misc',       'Burns for 1 hour, providing bright light in a 20-foot radius.', '1 lb', '1 cp'),
('Rope (50 ft)',      'misc',       'Hempen rope, 50 feet.', '10 lb', '1 gp'),
('Gemstone',          'treasure',   'A small polished gemstone of no fixed value here — just something to sell.', '-', '-');
