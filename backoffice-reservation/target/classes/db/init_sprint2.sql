-- ============================================================
-- SCRIPT D'INITIALISATION SPRINT 2
-- Données initiales : paramètres, lieux, distances, véhicules
-- ============================================================

\c reservation;

-- --------------------------------------------------------
-- Paramètres du système
-- --------------------------------------------------------
INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '30',  'Vitesse moyenne des véhicules en km/h'),
    ('temps_attente',   '30',  'Temps d''attente en minutes avant le départ du véhicule après la 1ère réservation')
ON CONFLICT (code) DO NOTHING;

-- --------------------------------------------------------
-- Lieux (l'aéroport en premier)
-- --------------------------------------------------------
INSERT INTO lieu (code, is_airport) VALUES
    ('IVATO',    TRUE),   -- Aéroport international d'Ivato
    ('COLBERT',  FALSE),  -- Hôtel Colbert, Antananarivo
    ('NOVOTEL',  FALSE),  -- Hôtel Novotel, Antananarivo
    ('IBIS',     FALSE),  -- Hôtel Ibis, Antananarivo
    ('LOKANGA',  FALSE),  -- Hôtel Lokanga, Antsirabe
    ('HILTON',   FALSE)   -- Hôtel Hilton, Antananarivo
ON CONFLICT (code) DO NOTHING;

-- --------------------------------------------------------
-- Distances entre les lieux (pas de doublons aller-retour)
-- --------------------------------------------------------
INSERT INTO distance (lieu_from, lieu_to, km)
SELECT l1.id, l2.id, d.km
FROM (VALUES
    ('IVATO',   'COLBERT',  23),
    ('IVATO',   'NOVOTEL',  18),
    ('IVATO',   'IBIS',     20),
    ('IVATO',   'LOKANGA',  160),
    ('IVATO',   'HILTON',   22),
    ('COLBERT', 'NOVOTEL',  5),
    ('COLBERT', 'IBIS',     6)
) AS d(from_code, to_code, km)
JOIN lieu l1 ON l1.code = d.from_code
JOIN lieu l2 ON l2.code = d.to_code
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------
-- Associer les hôtels existants à des lieux (optionnel)
-- --------------------------------------------------------
-- Mise à jour des réservations pour leur attribuer un lieu_destination
-- (basé sur l'hôtel existant)
UPDATE reservation r
SET id_lieu_destination = l.id
FROM hotel h
JOIN lieu l ON l.code = UPPER(REGEXP_REPLACE(h.name, '[^a-zA-Z]', '', 'g'))
WHERE r.id_hotel = h.id
  AND r.id_lieu_destination IS NULL;

-- Fallback : assigner COLBERT aux réservations encore sans lieu
UPDATE reservation
SET id_lieu_destination = (SELECT id FROM lieu WHERE code = 'COLBERT' LIMIT 1)
WHERE id_lieu_destination IS NULL;

SELECT 'Paramètres:' AS info;
SELECT * FROM parametre;
SELECT 'Lieux:' AS info;
SELECT * FROM lieu;
SELECT 'Distances:' AS info;
SELECT d.id, l1.code AS de, l2.code AS vers, d.km FROM distance d
    JOIN lieu l1 ON l1.id = d.lieu_from
    JOIN lieu l2 ON l2.id = d.lieu_to;

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

SELECT 'Véhicules:' AS info;
SELECT id, marque, nb_place, type, carburant, matricule FROM voiture ORDER BY id;
