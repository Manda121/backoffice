-- ============================================================
-- SCRIPT D'INITIALISATION SPRINT 2+3
-- Données initiales : paramètres, codes hôtels, aéroport, distances, véhicules
-- ============================================================

\c reservation;

-- --------------------------------------------------------
-- Paramètres du système
-- --------------------------------------------------------
INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '30',  'Vitesse moyenne des véhicules en km/h'),
    ('temps_attente',   '30',  'Temps d''attente en minutes (stocké mais non utilisé dans le calcul)')
ON CONFLICT (code) DO NOTHING;

-- --------------------------------------------------------
-- Codes des hôtels existants (insérés par init-database.sql)
-- --------------------------------------------------------
UPDATE hotel SET code = 'COLBERT' WHERE LOWER(name) LIKE '%colbert%' AND (code IS NULL OR code = '');
UPDATE hotel SET code = 'NOVOTEL' WHERE LOWER(name) LIKE '%novotel%' AND (code IS NULL OR code = '');
UPDATE hotel SET code = 'IBIS'    WHERE LOWER(name) LIKE '%ibis%'    AND (code IS NULL OR code = '');
UPDATE hotel SET code = 'LOKANGA' WHERE LOWER(name) LIKE '%lokanga%' AND (code IS NULL OR code = '');
UPDATE hotel SET code = 'HILTON'  WHERE LOWER(name) LIKE '%hilton%'  AND (code IS NULL OR code = '');

-- Codes génériques pour les hôtels sans code (sécurité)
UPDATE hotel
SET code = UPPER(REGEXP_REPLACE(TRIM(name), '\s+', '_', 'g'))
WHERE code IS NULL;

-- --------------------------------------------------------
-- Aéroport (enregistré comme un hôtel avec is_airport = TRUE)
-- --------------------------------------------------------
INSERT INTO hotel (name, ville, adresse, code, is_airport)
VALUES ('Aéroport d''Ivato', 'Ivato', 'BP 4009, Ivato, Antananarivo', 'IVATO', TRUE)
ON CONFLICT (code) DO NOTHING;

-- --------------------------------------------------------
-- Distances entre les hôtels (aéroport ↔ hôtels)
-- --------------------------------------------------------
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT h_from.id, h_to.id, d.km
FROM (VALUES
    ('IVATO',   'COLBERT',  23),
    ('IVATO',   'NOVOTEL',  18),
    ('IVATO',   'IBIS',     20),
    ('IVATO',   'LOKANGA',  160),
    ('IVATO',   'HILTON',   22),
    ('COLBERT', 'NOVOTEL',  5),
    ('COLBERT', 'IBIS',     6),
    ('HILTON',  'LOKANGA',  155)  
) AS d(from_code, to_code, km)
JOIN hotel h_from ON h_from.code = d.from_code
JOIN hotel h_to   ON h_to.code   = d.to_code
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------
-- Véhicules
-- --------------------------------------------------------
INSERT INTO voiture (marque, nb_place, type, carburant, matricule) VALUES
    ('Toyota HiAce',        15, 'Minibus',  'd', 'MAD-001'),
    ('Toyota Coaster',      30, 'Bus',      'd', 'MAD-002'),
    ('Mitsubishi L300',     11, 'Minivan',  'e', 'MAD-003'),
    ('Toyota Land Cruiser',  7, 'SUV',      'd', 'MAD-004'),
    ('Hyundai H1',          11, 'Van',      'e', 'MAD-005'),
    ('Mercedes Sprinter',   19, 'Minibus',  'd', 'MAD-006'),
    ('Toyota Corolla',       5, 'Berline',  'e', 'MAD-007'),
    ('Renault Trafic',       9, 'Van',      'h', 'MAD-008')
ON CONFLICT DO NOTHING;

SELECT 'Paramètres:' AS info;
SELECT * FROM parametre;
SELECT 'Hôtels (avec aéroport):' AS info;
SELECT id, name, code, is_airport FROM hotel ORDER BY is_airport DESC, code;
SELECT 'Distances:' AS info;
SELECT d.id, h1.code AS de, h2.code AS vers, d.km FROM distance d
    JOIN hotel h1 ON h1.id = d.lieu_from
    JOIN hotel h2 ON h2.id = d.lieu_to;
SELECT 'Véhicules:' AS info;
SELECT id, marque, nb_place, type, carburant, matricule FROM voiture ORDER BY id;
