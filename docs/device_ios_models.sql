-- ============================================================
-- Table: device_ios_models
-- Description: Maps Apple device machine identifiers to their
--              model names, CPU specifications, and RAM sizes.
-- ============================================================

CREATE TABLE device_ios_models (
    machine_id  VARCHAR(20)  PRIMARY KEY,
    model_name  VARCHAR(50)  NOT NULL,
    cpu_model   VARCHAR(30),
    cpu_speed   INT,          -- MHz
    cpu_cores   INT,
    ram_size    INT           -- MB
);

-- ============================================================
-- iPod
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPod1,1',  'iPod 1', NULL,       NULL, NULL, NULL),
('iPod2,1',  'iPod 2', NULL,       NULL, NULL, NULL),
('iPod3,1',  'iPod 3', NULL,       NULL, NULL, NULL),
('iPod4,1',  'iPod 4', NULL,       NULL, NULL, NULL),
('iPod5,1',  'iPod 5', 'Apple A5', 1000, 2,    512),
('iPod7,1',  'iPod 6', 'Apple A8', 1400, 2,    1024),
('iPod9,1',  'iPod 7', 'Apple A10', 2340, 4,   2048);

-- ============================================================
-- iPad (standard)
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPad2,1',   'iPad 2',  'Apple A5',  1000, 2,  512),
('iPad2,2',   'iPad 2',  'Apple A5',  1000, 2,  512),
('iPad2,3',   'iPad 2',  'Apple A5',  1000, 2,  512),
('iPad2,4',   'iPad 2',  'Apple A5',  1000, 2,  512),
('iPad3,1',   'iPad 3',  'Apple A5X', 1000, 2,  1024),
('iPad3,2',   'iPad 3',  'Apple A5X', 1000, 2,  1024),
('iPad3,3',   'iPad 3',  'Apple A5X', 1000, 2,  1024),
('iPad3,4',   'iPad 4',  'Apple A6X', 1400, 2,  1024),
('iPad3,5',   'iPad 4',  'Apple A6X', 1400, 2,  1024),
('iPad3,6',   'iPad 4',  'Apple A6X', 1400, 2,  1024),
('iPad6,11',  'iPad 5',  'Apple A9',  1850, 2,  2048),
('iPad6,12',  'iPad 5',  'Apple A9',  1850, 2,  2048),
('iPad7,5',   'iPad 6',  'Apple A9',  1850, 2,  2048),  -- Note: Apple A9 was reused, not A10
('iPad7,6',   'iPad 6',  'Apple A9',  1850, 2,  2048),
('iPad7,11',  'iPad 7',  'Apple A10', 2340, 4,  3072),
('iPad7,12',  'iPad 7',  'Apple A10', 2340, 4,  3072),
('iPad11,6',  'iPad 8',  'Apple A12', 2490, 6,  3072),
('iPad11,7',  'iPad 8',  'Apple A12', 2490, 6,  3072),
('iPad12,1',  'iPad 9',  'Apple A13', 2660, 6,  3072),
('iPad12,2',  'iPad 9',  'Apple A13', 2660, 6,  3072),
('iPad13,18', 'iPad 10', 'Apple A14', 3100, 6,  4096),
('iPad13,19', 'iPad 10', 'Apple A14', 3100, 6,  4096),
('iPad15,7',  'iPad 11', 'Apple A16', 3460, 6,  6144),
('iPad15,8',  'iPad 11', 'Apple A16', 3460, 6,  6144);

-- ============================================================
-- iPad Mini
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPad2,5',   'iPad Mini',      'Apple A5',  1000, 2, 512),
('iPad2,6',   'iPad Mini',      'Apple A5',  1000, 2, 512),
('iPad2,7',   'iPad Mini',      'Apple A5',  1000, 2, 512),
('iPad4,4',   'iPad Mini 2',    'Apple A7',  1300, 2, 1024),
('iPad4,5',   'iPad Mini 2',    'Apple A7',  1300, 2, 1024),
('iPad4,6',   'iPad Mini 2',    'Apple A7',  1300, 2, 1024),
('iPad4,7',   'iPad Mini 3',    'Apple A7',  1300, 2, 1024),
('iPad4,8',   'iPad Mini 3',    'Apple A7',  1300, 2, 1024),
('iPad4,9',   'iPad Mini 3',    'Apple A7',  1300, 2, 1024),
('iPad5,1',   'iPad Mini 4',    'Apple A8',  1400, 2, 2048),
('iPad5,2',   'iPad Mini 4',    'Apple A8',  1400, 2, 2048),
('iPad11,1',  'iPad Mini 5',    'Apple A12', 2490, 6, 3072),
('iPad11,2',  'iPad Mini 5',    'Apple A12', 2490, 6, 3072),
('iPad14,1',  'iPad Mini 6',    'Apple A15', 3223, 6, 4096),
('iPad14,2',  'iPad Mini 6',    'Apple A15', 3223, 6, 4096),
('iPad16,2',  'iPad Mini 2024', 'Apple A17', 3780, 6, 8192);

-- ============================================================
-- iPad Pro
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPad6,3',   'iPad Pro 9.7',         'Apple A9X',  2200, 2,  4096),
('iPad6,4',   'iPad Pro 9.7',         'Apple A9X',  2200, 2,  4096),
('iPad7,3',   'iPad Pro 10.5',        'Apple A10X', 2380, 6,  4096),
('iPad7,4',   'iPad Pro 10.5',        'Apple A10X', 2380, 6,  4096),
('iPad6,7',   'iPad Pro 12.9',        'Apple A9X',  2200, 2,  4096),
('iPad6,8',   'iPad Pro 12.9',        'Apple A9X',  2200, 2,  4096),
('iPad7,1',   'iPad Pro 2 12.9',      'Apple A10X', 2380, 6,  4096),
('iPad7,2',   'iPad Pro 2 12.9',      'Apple A10X', 2380, 6,  4096),
('iPad8,1',   'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad8,2',   'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad8,3',   'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad8,4',   'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad13,4',  'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad13,5',  'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad13,6',  'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad13,7',  'iPad Pro 11',          'Apple A12X', 2490, 8,  4096),
('iPad8,9',   'iPad Pro 11 2nd gen',  'Apple A12Z', 2490, 8,  4096),
('iPad8,10',  'iPad Pro 11 2nd gen',  'Apple A12Z', 2490, 8,  4096),
('iPad8,5',   'iPad Pro 3 12.9',      'Apple A12X', 2490, 8,  4096),
('iPad8,6',   'iPad Pro 3 12.9',      'Apple A12X', 2490, 8,  4096),
('iPad8,7',   'iPad Pro 3 12.9',      'Apple A12X', 2490, 8,  4096),
('iPad8,8',   'iPad Pro 3 12.9',      'Apple A12X', 2490, 8,  4096),
('iPad8,11',  'iPad Pro 4 12.9',      'Apple A12Z', 2490, 8,  6144),
('iPad8,12',  'iPad Pro 4 12.9',      'Apple A12Z', 2490, 8,  6144),
('iPad13,8',  'iPad Pro 5 12.9',      'Apple M1',   3223, 8,  8192),
('iPad13,9',  'iPad Pro 5 12.9',      'Apple M1',   3223, 8,  8192),
('iPad13,10', 'iPad Pro 5 12.9',      'Apple M1',   3223, 8,  8192),
('iPad13,11', 'iPad Pro 5 12.9',      'Apple M1',   3223, 8,  8192),
('iPad16,3',  'iPad Pro 11 2024',     'Apple M4',   4410, 10, 8192),
('iPad16,4',  'iPad Pro 11 2024',     'Apple M4',   4410, 10, 8192),
('iPad16,5',  'iPad Pro 13 2024',     'Apple M4',   4410, 10, 8192),
('iPad16,6',  'iPad Pro 13 2024',     'Apple M4',   4410, 10, 8192);

-- ============================================================
-- iPad Air
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPad4,1',   'iPad Air ',        'Apple A7',  1300, 2,  1024),
('iPad4,2',   'iPad Air ',        'Apple A7',  1300, 2,  1024),
('iPad4,3',   'iPad Air ',        'Apple A7',  1300, 2,  1024),
('iPad5,3',   'iPad Air 2',       'Apple A8X', 1500, 3,  2048),
('iPad5,4',   'iPad Air 2',       'Apple A8X', 1500, 3,  2048),
('iPad11,3',  'iPad Air 3',       'Apple A12', 2490, 6,  3072),
('iPad11,4',  'iPad Air 3',       'Apple A12', 2490, 6,  3072),
('iPad13,1',  'iPad Air 4',       'Apple A14', 3100, 6,  NULL),
('iPad13,2',  'iPad Air 4',       'Apple A14', 3100, 6,  NULL),
('iPad13,16', 'iPad Air 5',       'Apple M1',  3223, 8,  8192),
('iPad13,17', 'iPad Air 5',       'Apple M1',  3223, 8,  8192),
('iPad14,8',  'iPad Air 11',      'Apple M2',  3490, 10, 8192),
('iPad14,9',  'iPad Air 11',      'Apple M2',  3490, 10, 8192),
('iPad15,3',  'iPad Air M3 11',   'Apple M3',  4050, 8,  8192),
('iPad15,4',  'iPad Air M3 11',   'Apple M3',  4050, 8,  8192),
('iPad15,5',  'iPad Air M3 13',   'Apple M3',  4050, 8,  8192),
('iPad15,6',  'iPad Air M3 13',   'Apple M3',  4050, 8,  8192);

-- ============================================================
-- iPhone
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('iPhone3,1',  'iPhone 4',           'Apple A4',  1000, 1, 512),
('iPhone3,2',  'iPhone 4',           'Apple A4',  1000, 1, 512),
('iPhone3,3',  'iPhone 4',           'Apple A4',  1000, 1, 512),
('iPhone4,1',  'iPhone 4S',          'Apple A5',  1000, 2, 512),
('iPhone5,1',  'iPhone 5',           'Apple A6',  1300, 2, 1024),
('iPhone5,2',  'iPhone 5',           'Apple A6',  1300, 2, 1024),
('iPhone5,3',  'iPhone 5C',          'Apple A6',  1300, 2, 1024),
('iPhone5,4',  'iPhone 5C',          'Apple A6',  1300, 2, 1024),
('iPhone6,1',  'iPhone 5S',          'Apple A7',  1300, 2, 1024),
('iPhone6,2',  'iPhone 5S',          'Apple A7',  1300, 2, 1024),
('iPhone7,1',  'iPhone 6 Plus',      'Apple A8',  1400, 2, 1024),
('iPhone7,2',  'iPhone 6',           'Apple A8',  1400, 2, 1024),
('iPhone8,1',  'iPhone 6S',          'Apple A9',  1850, 2, 2048),
('iPhone8,2',  'iPhone 6S Plus',     'Apple A9',  1850, 2, 2048),
('iPhone8,4',  'iPhone SE',          'Apple A9',  1850, 2, 2048),
('iPhone9,1',  'iPhone 7',           'Apple A10', 2340, 4, 2048),
('iPhone9,3',  'iPhone 7',           'Apple A10', 2340, 4, 2048),
('iPhone9,2',  'iPhone 7 Plus',      'Apple A10', 2340, 4, 3072),
('iPhone9,4',  'iPhone 7 Plus',      'Apple A10', 2340, 4, 3072),
('iPhone10,1', 'iPhone 8',           'Apple A11', 2390, 6, 2048),
('iPhone10,4', 'iPhone 8',           'Apple A11', 2390, 6, 2048),
('iPhone10,2', 'iPhone 8 Plus',      'Apple A11', 2390, 6, 3072),
('iPhone10,5', 'iPhone 8 Plus',      'Apple A11', 2390, 6, 3072),
('iPhone10,3', 'iPhone X',           'Apple A11', 2390, 6, 3072),
('iPhone10,6', 'iPhone X',           'Apple A11', 2390, 6, 3072),
('iPhone11,2', 'iPhone XS',          'Apple A12', 2490, 6, 4096),
('iPhone11,4', 'iPhone XS Max',      'Apple A12', 2490, 6, 4096),
('iPhone11,6', 'iPhone XS Max',      'Apple A12', 2490, 6, 4096),
('iPhone11,8', 'iPhone XR',          'Apple A12', 2490, 6, 3072),
('iPhone12,1', 'iPhone 11',          'Apple A13', 2660, 6, 4096),
('iPhone12,3', 'iPhone 11 Pro',      'Apple A13', 2660, 6, 4096),
('iPhone12,5', 'iPhone 11 Pro Max',  'Apple A13', 2660, 6, 4096),
('iPhone12,8', 'iPhone SE 2nd gen',  'Apple A13', 2660, 6, 3072),
('iPhone13,1', 'iPhone 12 Mini',     'Apple A14', 3100, 6, 4096),
('iPhone13,2', 'iPhone 12',          'Apple A14', 3100, 6, 4096),
('iPhone13,3', 'iPhone 12 Pro',      'Apple A14', 3100, 6, 6144),
('iPhone13,4', 'iPhone 12 Pro Max',  'Apple A14', 3100, 6, 6144),
('iPhone14,4', 'iPhone 13 Mini',     'Apple A15', 3223, 6, 4096),
('iPhone14,5', 'iPhone 13',          'Apple A15', 3223, 6, 4096),
('iPhone14,2', 'iPhone 13 Pro',      'Apple A15', 3223, 6, 6144),
('iPhone14,3', 'iPhone 13 Pro Max',  'Apple A15', 3223, 6, 6144),
('iPhone14,6', 'iPhone SE 3rd gen',  'Apple A15', 3223, 6, 4096),
('iPhone14,7', 'iPhone 14',          'Apple A15', 3223, 6, 4096),
('iPhone14,8', 'iPhone 14 Plus',     'Apple A15', 3223, 6, 4096),
('iPhone15,2', 'iPhone 14 Pro',      'Apple A16', 3460, 6, 4096),  -- Note: 14 Pro had 6GB but mapping says 4096
('iPhone15,3', 'iPhone 14 Pro Max',  'Apple A16', 3460, 6, 4096),
('iPhone15,4', 'iPhone 15',          'Apple A16', 3460, 6, 6144),
('iPhone15,5', 'iPhone 15 Plus',     'Apple A16', 3460, 6, 8192),
('iPhone16,1', 'iPhone 15 Pro',      'Apple A17', 3780, 6, 8192),
('iPhone16,2', 'iPhone 15 Pro Max',  'Apple A17', 3780, 6, 8192),
('iPhone17,1', 'iPhone 16 Pro',      'Apple A18', 4040, 6, 8192),
('iPhone17,2', 'iPhone 16 Pro Max',  'Apple A18', 4040, 6, 8192),
('iPhone17,3', 'iPhone 16',          'Apple A18', 4040, 6, 8192),
('iPhone17,4', 'iPhone 16 Plus',     'Apple A18', 4040, 6, 8192),
('iPhone17,5', 'iPhone 16 e',        'Apple A18', 4040, 6, 8192),
('iPhone18,1', 'iPhone 17 Pro',      'Apple A19', 4260, 6, 12000),
('iPhone18,2', 'iPhone 17 Pro Max',  'Apple A19', 4260, 6, 12000),
('iPhone18,3', 'iPhone 17',          'Apple A19', 4260, 6, 8192),
('iPhone18,4', 'iPhone Air',         'Apple A19 Pro', 4260, 6, 4250);

-- ============================================================
-- Apple Watch
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('Watch1,1',  'Apple Watch 1gen',           NULL,        NULL, NULL, NULL),
('Watch1,2',  'Apple Watch 1gen',           NULL,        NULL, NULL, NULL),
('Watch2,6',  'Apple Watch Series 1',       NULL,        NULL, NULL, NULL),
('Watch2,7',  'Apple Watch Series 1',       NULL,        NULL, NULL, NULL),
('Watch2,3',  'Apple Watch Series 2',       NULL,        NULL, NULL, NULL),
('Watch2,4',  'Apple Watch Series 2',       NULL,        NULL, NULL, NULL),
('Watch3,1',  'Apple Watch Series 3',       NULL,        NULL, NULL, NULL),
('Watch3,2',  'Apple Watch Series 3',       NULL,        NULL, NULL, NULL),
('Watch3,3',  'Apple Watch Series 3',       NULL,        NULL, NULL, NULL),
('Watch3,4',  'Apple Watch Series 3',       NULL,        NULL, NULL, NULL),
('Watch4,1',  'Apple Watch Series 4',       NULL,        NULL, NULL, NULL),
('Watch4,2',  'Apple Watch Series 4',       NULL,        NULL, NULL, NULL),
('Watch4,3',  'Apple Watch Series 4',       NULL,        NULL, NULL, NULL),
('Watch4,4',  'Apple Watch Series 4',       NULL,        NULL, NULL, NULL),
('Watch5,1',  'Apple Watch Series 5',       NULL,        NULL, NULL, NULL),
('Watch5,2',  'Apple Watch Series 5',       NULL,        NULL, NULL, NULL),
('Watch5,3',  'Apple Watch Series 5',       NULL,        NULL, NULL, NULL),
('Watch5,4',  'Apple Watch Series 5',       NULL,        NULL, NULL, NULL),
('Watch5,9',  'Apple Watch Special Edition', NULL,       NULL, NULL, NULL),
('Watch5,10', 'Apple Watch Special Edition', NULL,       NULL, NULL, NULL),
('Watch5,11', 'Apple Watch Special Edition', NULL,       NULL, NULL, NULL),
('Watch5,12', 'Apple Watch Special Edition', NULL,       NULL, NULL, NULL),
('Watch6,1',  'Apple Watch Series 6',       NULL,        NULL, NULL, NULL),
('Watch6,2',  'Apple Watch Series 6',       NULL,        NULL, NULL, NULL),
('Watch6,3',  'Apple Watch Series 6',       NULL,        NULL, NULL, NULL),
('Watch6,4',  'Apple Watch Series 6',       NULL,        NULL, NULL, NULL),
('Watch6,6',  'Apple Watch Series 7',       NULL,        NULL, NULL, NULL),
('Watch6,7',  'Apple Watch Series 7',       NULL,        NULL, NULL, NULL),
('Watch6,8',  'Apple Watch Series 7',       NULL,        NULL, NULL, NULL),
('Watch6,9',  'Apple Watch Series 7',       NULL,        NULL, NULL, NULL),
('Watch6,14', 'Apple Watch Series 8',       'Apple S8',  1800, NULL, NULL),
('Watch6,15', 'Apple Watch Series 8',       'Apple S8',  1800, NULL, NULL),
('Watch6,16', 'Apple Watch Series 8',       'Apple S8',  1800, NULL, NULL),
('Watch6,17', 'Apple Watch Series 8',       'Apple S8',  1800, NULL, NULL),
('Watch7,1',  'Apple Watch Series 9',       'Apple S9',  1800, NULL, NULL),
('Watch7,2',  'Apple Watch Series 9',       'Apple S9',  1800, NULL, NULL),
('Watch7,3',  'Apple Watch Series 9',       'Apple S9',  1800, NULL, NULL),
('Watch7,4',  'Apple Watch Series 9',       'Apple S9',  1800, NULL, NULL),
('Watch7,8',  'Apple Watch Series 10',      'Apple S10', 1800, NULL, NULL),
('Watch7,9',  'Apple Watch Series 10',      'Apple S10', 1800, NULL, NULL),
('Watch7,10', 'Apple Watch Series 10',      'Apple S10', 1800, NULL, NULL),
('Watch7,11', 'Apple Watch Series 10',      'Apple S10', 1800, NULL, NULL),
('Watch6,18', 'Apple Watch Ultra',          'Apple S8',  1800, NULL, NULL),
('Watch7,5',  'Apple Watch Ultra 2',        'Apple S9',  1800, NULL, NULL);

-- ============================================================
-- Apple TV
-- ============================================================
INSERT INTO device_ios_models (machine_id, model_name, cpu_model, cpu_speed, cpu_cores, ram_size) VALUES
('AppleTV1,1',  'Apple TV 1gen',    NULL, NULL, NULL, NULL),
('AppleTV2,1',  'Apple TV 2gen',    NULL, NULL, NULL, NULL),
('AppleTV3,1',  'Apple TV 3gen',    NULL, NULL, NULL, NULL),
('AppleTV3,2',  'Apple TV 3gen',    NULL, NULL, NULL, NULL),
('AppleTV5,3',  'Apple TV 4gen',    NULL, NULL, NULL, NULL),
('AppleTV6,2',  'Apple TV 4K',      NULL, NULL, NULL, NULL),
('AppleTV11,1', 'Apple TV 4K 2gen', NULL, NULL, NULL, NULL);
