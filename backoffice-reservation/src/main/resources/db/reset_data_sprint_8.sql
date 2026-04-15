\c reservation;

TRUNCATE TABLE planification, reservation, distance, hotel, voiture, token, parametre
    RESTART IDENTITY CASCADE;

-- ==================
-- Hôtels (1 = aéroport)
-- ==================
INSERT INTO hotel (name, ville, adresse, code, is_airport) VALUES
    ('Aéroport Ivato', 'Antananarivo', 'Ivato', 'IVATO', TRUE),
    ('Hotel Alpha',    'Antananarivo', 'Centre', 'ALPHA', FALSE),
    ('Hotel Bravo',    'Antananarivo', 'Ankorondrano', 'BRAVO', FALSE),
    ('Hotel Charlie',  'Antananarivo', 'Analakely', 'CHARLIE', FALSE);

-- ==================
-- Distances (km)
-- ==================
INSERT INTO distance (lieu_from, lieu_to, km) VALUES
    (1, 2, 30), 
    (1, 3, 25), 
    (1, 4, 15), 
    (2, 3, 10), (2, 4, 15), (3, 4, 12);

-- ==================
-- Paramètres
-- ==================
INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '40', 'km/h'),
    ('temps_attente',   '20', 'minutes');

INSERT INTO voiture (marque, nb_place, type, matricule, carburant, heure_disponible) VALUES
    ('Hyundai', 8,  'Minibus', 'MAD-100', 'd', '2026-03-20 09:00:00'),
    ('Toyota',  12, 'Minibus', 'MAD-200', 'e', '2026-03-20 09:30:00'),
    ('Suzuki',  5,  'Van',     'MAD-300', 'd', '2026-03-20 10:00:00');

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('cli1', 2, 6, '2026-03-20 09:00:00', 'client1'),
    ('cli2', 3, 6, '2026-03-20 09:05:00', 'client2');

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('cli3', 4, 3, '2026-03-20 09:40:00', 'client3'),
    ('cli4', 2, 2, '2026-03-20 09:45:00', 'client4');

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('cli5', 3, 4, '2026-03-20 10:10:00', 'client5'),
    ('cli6', 3, 4, '2026-03-20 10:12:00', 'client6');

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('cli7', 2, 20, '2026-03-20 11:00:00', 'client7');

-- ==================
-- Tokens (technique)
-- ==================
INSERT INTO token (token, date_heure_expiration) VALUES
    ('tok-s8-1', now() + interval '1 day'),
    ('tok-s8-2', now() + interval '2 days');

-- ==================
-- Vérification rapide
-- ==================
SELECT 'hotel' AS table_name, COUNT(*) AS nb FROM hotel
UNION ALL SELECT 'distance', COUNT(*) FROM distance
UNION ALL SELECT 'voiture', COUNT(*) FROM voiture
UNION ALL SELECT 'reservation', COUNT(*) FROM reservation
UNION ALL SELECT 'parametre', COUNT(*) FROM parametre;
