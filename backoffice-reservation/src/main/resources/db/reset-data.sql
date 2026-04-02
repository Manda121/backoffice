-- ============================================================
-- SCRIPT DE RÉINITIALISATION DES DONNÉES
-- Vide toutes les tables, remet les séquences à 1, réinsère les données
-- Usage : psql -U postgres -f reset-data.sql
-- Prérequis : base "reservation" créée via reset_db.sql
-- ============================================================

\c reservation;

-- ============================================================
-- 1. Vider toutes les tables et remettre les séquences à zéro
-- ============================================================
TRUNCATE TABLE planification, reservation, distance, hotel, voiture, token, parametre
    RESTART IDENTITY CASCADE;

-- ============================================================
-- 2. Hotels  (id 1..2)
-- ============================================================
INSERT INTO hotel (name, ville, adresse, code, is_airport) VALUES
    ('Aéroport d''Ivato', 'Ivato',         'BP 4009, Ivato, Antananarivo', 'IVATO',  TRUE),
    ('Hotel 1',          'Antananarivo',  'Avenue de l''Indépendance',   'HOTEL1', FALSE);
    

-- ============================================================
-- 3. Voitures  (id 1..4)
-- ============================================================
INSERT INTO voiture (marque, nb_place, type, matricule, carburant, heure_disponible) VALUES
    ('v1',  12, 'Berline', 'MAD-002', 'd', '2026-04-02 10:00:00');

-- ============================================================
-- 4. Réservations  (référence hotel id 2 = HOTEL1)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('cli1', 2,  10, '2026-04-02 08:00:00', 'Client1'),
    ('cli2', 2,  15, '2026-04-02 10:10:00', 'Client2'),
    ('cli3', 2,  8, '2026-04-02 10:15:00', 'Client3');
    

-- ============================================================
-- 5. Tokens
-- ============================================================
INSERT INTO token (token, date_heure_expiration) VALUES
    ('a1b2c3d4e5', now() + interval '1 day'),
    ('f6g7h8i9j0', now() + interval '2 days');

-- ============================================================
-- 6. Distances  (IVATO → HOTEL1)
-- ============================================================
INSERT INTO distance (lieu_from, lieu_to, km) VALUES
    (1, 2, 50.0);

-- ============================================================
-- 7. Paramètres
-- ============================================================
INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '50', 'Vitesse moyenne des véhicules en km/h'),
    ('temps_attente',   '30',  'Temps d''attente en minutes avant départ');

-- ============================================================
-- 8. Vérification
-- ============================================================
SELECT 'hotel'      AS table_name, COUNT(*) AS nb FROM hotel
UNION ALL
SELECT 'reservation',              COUNT(*) FROM reservation
UNION ALL
SELECT 'voiture',                  COUNT(*) FROM voiture
UNION ALL
SELECT 'token',                    COUNT(*) FROM token
UNION ALL
SELECT 'distance',                 COUNT(*) FROM distance
UNION ALL
SELECT 'parametre',                COUNT(*) FROM parametre
UNION ALL
SELECT 'planification',            COUNT(*) FROM planification;
