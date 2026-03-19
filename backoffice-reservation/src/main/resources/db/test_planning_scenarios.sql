-- ============================================================
-- SCRIPT DE TEST COMPLET - SCÉNARIOS PLANIFICATION
-- Objectif : préparer les données pour tester toutes les règles du planning
-- Usage : psql -U postgres -f test_planning_scenarios.sql
-- Ensuite, dans l'app, cliquer "Planifier" pour chaque date de scénario.
-- ============================================================

\c reservationsprint7;

-- Nettoyage global
TRUNCATE TABLE planification, reservation, distance, hotel, voiture, token, parametre
    RESTART IDENTITY CASCADE;

-- ------------------------------------------------------------
-- 1) Données communes
-- ------------------------------------------------------------
INSERT INTO hotel (name, ville, adresse, code, is_airport) VALUES
    ('Aéroport d''Ivato', 'Ivato',        'Ivato',          'IVATO',    TRUE),
    ('Hotel Near',        'Antananarivo', 'Zone A',         'HOTEL_N',  FALSE),
    ('Hotel Mid',         'Antananarivo', 'Zone B',         'HOTEL_M',  FALSE),
    ('Hotel Far',         'Antananarivo', 'Zone C',         'HOTEL_F',  FALSE);

-- Distances (km)
-- 1 = IVATO, 2 = Near (5km), 3 = Mid (15km), 4 = Far (30km)
INSERT INTO distance (lieu_from, lieu_to, km) VALUES
    (1, 2, 5.0),
    (1, 3, 15.0),
    (1, 4, 30.0),
    (2, 3, 10.0),
    (2, 4, 25.0),
    (3, 4, 15.0);

-- Paramètres globaux
INSERT INTO parametre (code, valeur, description) VALUES
    ('vitesse_moyenne', '60', 'Vitesse moyenne en km/h pour les scénarios'),
    ('temps_attente',   '30', 'Fenêtre d''attente en minutes');

-- Flotte dédiée aux scénarios (capacités spécifiques)
INSERT INTO voiture (marque, nb_place, type, matricule, carburant) VALUES
    ('Toyota',  2,  'Test', 'C02E', 'e'),
    ('Toyota',  4,  'Test', 'C04D', 'd'),
    ('Toyota',  6,  'Test', 'C06E', 'e'),
    ('Toyota',  7,  'Test', 'C07D', 'd'),
    ('Toyota',  7,  'Test', 'C07E', 'e'),
    ('Toyota',  8,  'Test', 'C08D', 'd'),
    ('Toyota',  9,  'Test', 'C09D', 'd'),
    ('Toyota',  9,  'Test', 'C09E', 'e'),
    ('Toyota', 10,  'Test', 'C10D', 'd'),
    ('Toyota', 13,  'Test', 'C13D', 'd'),
    ('Toyota', 13,  'Test', 'C13E', 'e');

-- ------------------------------------------------------------
-- 2) Scénarios à exécuter via "Planifier"
-- ------------------------------------------------------------

-- SCÉNARIO 1 : ordre de traitement (passagers décroissants)
-- Date test : 2026-04-01
-- Réservations (même tranche): 8, 6, 4, 2 passagers
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s101', 2, 8, '2026-04-01 08:00:00', 'S1-P8'),
    ('s102', 2, 6, '2026-04-01 08:00:00', 'S1-P6'),
    ('s103', 2, 4, '2026-04-01 08:00:00', 'S1-P4'),
    ('s104', 2, 2, '2026-04-01 08:00:00', 'S1-P2');

-- SCÉNARIO 2 : priorité nb trajets (à capacité égale)
-- Date test : 2026-04-02
-- 1er trajet (08:00): C07D ou C07E (tie carburant => diesel d'abord)
-- 2e trajet (09:00): doit privilégier celle avec moins de trajets (attendu: C07E)
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s201', 2, 7, '2026-04-02 08:00:00', 'S2-T1'),
    ('s202', 2, 7, '2026-04-02 09:00:00', 'S2-T2');

-- SCÉNARIO 3 : priorité carburant si capacité + trajets identiques
-- Date test : 2026-04-03
-- Attendu : C09D choisi plutôt que C09E
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s301', 2, 9, '2026-04-03 10:00:00', 'S3-FUEL');

-- SCÉNARIO 4 : replanification complète (DELETE puis INSERT)
-- Date test : 2026-04-04
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s401', 2, 8, '2026-04-04 11:00:00', 'S4-A'),
    ('s402', 2, 2, '2026-04-04 11:05:00', 'S4-B');

-- Ancienne ligne volontaire à écraser lors du clic "Planifier" de la date 2026-04-04
INSERT INTO planification
    (reservation_id, voiture_id, date_planning, heure_depart, heure_arrivee_hotel, heure_retour_aeroport, distance_km)
SELECT r.id, v.id, DATE '2026-04-04',
       TIMESTAMP '2026-04-04 00:00:00',
       TIMESTAMP '2026-04-04 00:00:00',
       TIMESTAMP '2026-04-04 00:00:00',
       0
FROM reservation r
JOIN voiture v ON v.matricule = 'C08D'
WHERE r.id_client = 's401'
LIMIT 1;

-- SCÉNARIO 5 : report intelligent (voitures en trajet puis nouvelle tranche)
-- Date test : 2026-04-05
-- C13D et C13E occupées sur tranche 09:30-10:00 (retour vers 10:31)
-- Réservation à 10:00 (12 pax) potentiellement reportable
-- Nouvelle réservation à 10:55 (1 pax), nouvelle tranche
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s501', 4, 13, '2026-04-05 09:30:00', 'S5-LOAD1'),
    ('s502', 4, 13, '2026-04-05 09:31:00', 'S5-LOAD2'),
    ('s503', 4, 12, '2026-04-05 10:00:00', 'S5-DEFER'),
    ('s504', 4,  1, '2026-04-05 10:55:00', 'S5-LATER');

-- SCÉNARIO 6 : départ ajusté au retour véhicule dans la tranche
-- Date test : 2026-04-06
-- C10D est occupée par un trajet à 09:55 vers HOTEL_M (retour ~10:25)
-- Groupe cible: 10:00 + 10:20 (total 10 pax), fenêtre max 10:30
-- Attendu: départ ajusté à 10:25
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s601', 3, 10, '2026-04-06 09:55:00', 'S6-BUSY'),
    ('s602', 2,  6, '2026-04-06 10:00:00', 'S6-G1'),
    ('s603', 2,  4, '2026-04-06 10:20:00', 'S6-G2');

-- SCÉNARIO 7 : capacité insuffisante
-- Date test : 2026-04-07
-- Attendu: non assignée (max flotte = 13)
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s701', 2, 20, '2026-04-07 12:00:00', 'S7-OVER');

-- SCÉNARIO 8 : sanity check multi-dates + persistance planification
-- Date test : 2026-04-08
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee, nom) VALUES
    ('s801', 2, 4, '2026-04-08 08:00:00', 'S8-A'),
    ('s802', 3, 4, '2026-04-08 08:10:00', 'S8-B'),
    ('s803', 4, 4, '2026-04-08 08:20:00', 'S8-C');

-- ------------------------------------------------------------
-- 3) Vérifications de préparation (avant clic Planifier)
-- ------------------------------------------------------------
SELECT 'reservation_total' AS k, COUNT(*)::text AS v FROM reservation
UNION ALL SELECT 'voiture_total', COUNT(*)::text FROM voiture
UNION ALL SELECT 'planification_preseeded_s4', COUNT(*)::text FROM planification WHERE date_planning = DATE '2026-04-04';

-- Liste des dates de scénarios disponibles
SELECT DATE(date_heure_arrivee) AS date_scenario, COUNT(*) AS nb_reservations
FROM reservation
GROUP BY DATE(date_heure_arrivee)
ORDER BY date_scenario;

-- ============================================================
-- 4) Requêtes de vérification APRÈS clic "Planifier" (à lancer au besoin)
-- ============================================================
-- Exemple:
--   1) Planifier 2026-04-01 dans l'UI
--   2) Exécuter ci-dessous:
--      SELECT p.date_planning, r.id_client, r.nb_passager, v.matricule,
--             to_char(p.heure_depart, 'HH24:MI') AS depart,
--             to_char(p.heure_retour_aeroport, 'HH24:MI') AS retour
--      FROM planification p
--      JOIN reservation r ON r.id = p.reservation_id
--      JOIN voiture v ON v.id = p.voiture_id
--      WHERE p.date_planning = DATE '2026-04-01'
--      ORDER BY p.heure_depart, r.nb_passager DESC;
--
-- Vérif S4 (replanification):
--   SELECT * FROM planification WHERE date_planning = DATE '2026-04-04' ORDER BY id;
--   -- La ligne seedée à 00:00 doit disparaître après le clic Planifier.
--
-- Vérif S2 (trajets):
--   SELECT p.date_planning, r.id_client, v.matricule, to_char(p.heure_depart,'HH24:MI') depart
--   FROM planification p
--   JOIN reservation r ON r.id = p.reservation_id
--   JOIN voiture v ON v.id = p.voiture_id
--   WHERE p.date_planning = DATE '2026-04-02'
--   ORDER BY p.heure_depart, r.id;
--
-- Vérif S3 (fuel):
--   SELECT r.id_client, v.matricule, v.carburant
--   FROM planification p
--   JOIN reservation r ON r.id = p.reservation_id
--   JOIN voiture v ON v.id = p.voiture_id
--   WHERE p.date_planning = DATE '2026-04-03';
--
-- Vérif S6 (départ ajusté):
--   SELECT p.date_planning, r.id_client, v.matricule, to_char(p.heure_depart,'HH24:MI') depart
--   FROM planification p
--   JOIN reservation r ON r.id = p.reservation_id
--   JOIN voiture v ON v.id = p.voiture_id
--   WHERE p.date_planning = DATE '2026-04-06'
--   ORDER BY p.heure_depart, r.id;
-- ============================================================
