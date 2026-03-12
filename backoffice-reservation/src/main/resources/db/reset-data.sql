-- Script de réinitialisation des données pour la base reservation_sprint5
\c reservation;

-- 1. Suppression de toutes les données et remise à zéro des séquences
TRUNCATE TABLE reservation, hotel, voiture, token, distance, parametre
    RESTART IDENTITY CASCADE;

-- 2. (optionnel) Remises en place d'exemples de données minimales
--    l'utilisateur pourra compléter ou remplacer ces lignes selon ses besoins

INSERT INTO hotel (name, ville, adresse, code, is_airport) VALUES
    ('ivato', 'Antananarivo', 'IVATO', 'IVATO', TRUE),
    ('hotel1', 'Antananarivo', 'Avenue de l''Indépendance','HOTEL1', FALSE);

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom)
    VALUES ('cli1', 2, 7, '2026-03-12 9:00:00', 'Dupont'),
           ('cli2', 2, 11, '2026-03-12 9:00:00', 'Dupont'),
           ('cli3', 2, 3, '2026-03-12 9:00:00', 'Dupont'),
           ('cli4', 2, 1, '2026-03-12 9:00:00', 'Dupont'),
           ('cli5', 2, 2, '2026-03-12 9:00:00', 'Dupont'),
           ('cli6', 2, 20, '2026-03-12 09:00:00', 'Martin');

INSERT INTO voiture (marque, nb_place, type, matricule, carburant)
    VALUES ('vehicule1', 12, 'Sedan', 'ABC-123', 'd'),
           ('vehicule2', 5, 'Sedan', 'ABC-123', 'e'),
           ('vehicule3', 5, 'Sedan', 'ABC-123', 'd'),
           ('vehicule4', 12, 'Van',   'DEF-456', 'e');

INSERT INTO token (token, date_heure_expiration)
    VALUES ('a1b2c3d4e5', now() + interval '1 day'),
           ('f6g7h8i9j0', now() + interval '2 days');

INSERT INTO distance (lieu_from, lieu_to, km)
    VALUES (1, 2, 50.0);

INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '50',  'Vitesse moyenne des véhicules en km/h'),
    ('temps_attente',   '0',  'Temps d''attente en minutes (stocké mais non utilisé dans le calcul)')
ON CONFLICT (code) DO NOTHING;

-- 3. Vérification rapide
SELECT 'Données réinitialisées' AS info;
SELECT * FROM hotel;
SELECT * FROM reservation;
SELECT * FROM voiture;
SELECT * FROM token;
SELECT * FROM distance;
SELECT * FROM parametre;
