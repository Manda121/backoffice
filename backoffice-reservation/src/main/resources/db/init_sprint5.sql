-- ============================================================
-- SCRIPT D'INITIALISATION SPRINT 5
-- Données de test pour le temps d'attente (fenêtre glissante)
--
-- Paramètres utilisés :
--   temps_attente   = 30 minutes
--   vitesse_moyenne = 30 km/h
--
-- Véhicules disponibles (après init_sprint2.sql) :
--   MAD-001  Toyota HiAce      15 places  Minibus  Diesel
--   MAD-002  Toyota Coaster    30 places  Bus      Diesel
--   MAD-003  Mitsubishi L300   11 places  Minivan  Essence
--   MAD-004  Toyota LandCruiser 7 places  SUV      Diesel
--   MAD-005  Hyundai H1        11 places  Van      Essence
--   MAD-006  Mercedes Sprinter 19 places  Minibus  Diesel
--   MAD-007  Toyota Corolla     5 places  Berline  Essence
--   MAD-008  Renault Trafic     9 places  Van      Hybride
--
-- Distances depuis IVATO :
--   NOVOTEL  18 km   IBIS     20 km   HILTON  22 km
--   COLBERT  23 km   LOKANGA 160 km
-- ============================================================

\c reservation;

-- --------------------------------------------------------
-- Mise à jour des paramètres pour rendre les tests lisibles
-- --------------------------------------------------------
UPDATE parametre SET
    valeur = '30',
    description = 'Temps d''attente en minutes (utilisé dans le calcul de groupement)'
WHERE code = 'temps_attente';

-- --------------------------------------------------------
-- Véhicules additionnels pour couvrir les scénarios diesel
-- --------------------------------------------------------
-- MAD-T01 : même capacité que Renault Trafic (9 places) mais Diesel
--           → permet de tester la règle 3 : priorité Diesel à capacité égale
INSERT INTO voiture (marque, nb_place, type, carburant, matricule) VALUES
    ('Ford Transit',    9, 'Van',     'd', 'MAD-T01'),
    ('Peugeot Boxer',  15, 'Minibus', 'e', 'MAD-T02')
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------
-- Nettoyage des réservations existantes sur la date de test
-- (pour pouvoir rejouer le script sans doublons)
-- --------------------------------------------------------
DELETE FROM reservation
WHERE DATE(date_heure_arrivee) = '2026-03-15';

-- ============================================================
-- SCÉNARIO 1 — Réservation totalement isolée
-- Fenêtre [08:00, 08:30] → une seule réservation
-- Départ = 08:00 (= heure d'arrivée de la seule réservation)
-- Attendu : Toyota Corolla (5 places, essence) — le plus petit ≥ 3
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S101', (SELECT id FROM hotel WHERE code = 'IBIS'),    3, '2026-03-15 08:00:00');

-- ============================================================
-- SCÉNARIO 2 — Groupement de 3 réservations dans la fenêtre
-- Fenêtre [09:00, 09:30] → R02(09:00), R03(09:10), R04(09:25) tous inclus
-- Départ = 09:25 (= heure du dernier arrivant dans la fenêtre)
-- Total passagers : 2+3+2 = 7
-- Attendu : Toyota Land Cruiser (7 places, diesel) — exactement 7 places
-- Itinéraire : IVATO → NOVOTEL(18km) → IBIS(20km) → COLBERT(23km) → IVATO
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S201', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 2, '2026-03-15 09:00:00'),
    ('S202', (SELECT id FROM hotel WHERE code = 'COLBERT'), 3, '2026-03-15 09:10:00'),
    ('S203', (SELECT id FROM hotel WHERE code = 'IBIS'),    2, '2026-03-15 09:25:00');

-- ============================================================
-- SCÉNARIO 3 — Réservation hors fenêtre du scénario 2
-- 09:31 > 09:00 + 30min = 09:30 → nouveau groupe distinct
-- Fenêtre [09:31, 10:01] → seul R05
-- Départ = 09:31
-- Attendu : Toyota Corolla (5 places, essence) si revenue de S1 (retour ≈ 09:20)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S301', (SELECT id FROM hotel WHERE code = 'HILTON'),  4, '2026-03-15 09:31:00');

-- ============================================================
-- SCÉNARIO 4 — Limite exacte de la fenêtre (inclus vs exclus)
-- Fenêtre [10:00, 10:30]
--   R06 à 10:00 → inclus (heure initiale)
--   R07 à 10:30 → inclus (exactement à la limite)
--   R08 à 10:31 → EXCLU → démarre un nouveau groupe
-- Départ groupe 4a = 10:30 (= R07)
-- Total groupe 4a : 2+3 = 5 → Toyota Corolla (5, essence) si disponible
-- Départ groupe 4b = 10:31 (seul R08)
-- Attendu groupe 4b : Toyota Corolla ou Renault Trafic (le plus petit ≥ 2)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S401', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 2, '2026-03-15 10:00:00'),
    ('S402', (SELECT id FROM hotel WHERE code = 'COLBERT'), 3, '2026-03-15 10:30:00'),
    ('S403', (SELECT id FROM hotel WHERE code = 'IBIS'),    2, '2026-03-15 10:31:00');

-- ============================================================
-- SCÉNARIO 5 — Capacité insuffisante (non assigné)
-- 32 passagers → aucun véhicule (max = 30 places)
-- Attendu : réservation dans la liste "non assignées" avec raison
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S501', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 32, '2026-03-15 11:00:00');

-- ============================================================
-- SCÉNARIO 6 — Groupe nécessitant plusieurs véhicules
-- Fenêtre [12:00, 12:30] : R10(15p), R11(14p), R12(8p) = 37 pass total
-- Étape 1 : 37 > 30 → impossible tout prendre → fallback R10 seul (15p)
--           → Toyota HiAce (15 places, diesel)
-- Étape 2 : R11(14p) + R12(8p) = 22p → Toyota Coaster (30p, diesel) [seul ≥ 22]
-- Attendu : 2 entrées de planning, même heure de départ (12:20)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S601', (SELECT id FROM hotel WHERE code = 'LOKANGA'), 15, '2026-03-15 12:00:00'),
    ('S602', (SELECT id FROM hotel WHERE code = 'HILTON'),  14, '2026-03-15 12:10:00'),
    ('S603', (SELECT id FROM hotel WHERE code = 'COLBERT'),  8, '2026-03-15 12:20:00');

-- ============================================================
-- SCÉNARIO 7 — Règle 3 : Préférence Diesel à capacité égale
-- Fenêtre [13:00, 13:30] : R13(7p) + R14(2p) = 9p
-- Véhicules à 9 places : MAD-008 Renault Trafic (hybride) vs MAD-T01 Ford Transit (diesel)
-- Attendu : Ford Transit (diesel) est choisi
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S701', (SELECT id FROM hotel WHERE code = 'HILTON'),  7, '2026-03-15 13:00:00'),
    ('S702', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 2, '2026-03-15 13:20:00');

-- ============================================================
-- SCÉNARIO 8 — Règle 3 : Préférence Diesel à capacité égale (15 places)
-- Fenêtre [14:00, 14:30] : 13p total
-- Véhicules à 15 places : MAD-001 HiAce (diesel) vs MAD-T02 Peugeot Boxer (essence)
-- Attendu : Toyota HiAce (diesel) est choisi
-- Note : HiAce devrait être revenue de S6 (départ 12:20, LOKANGA ≈ 320min aller...)
--        donc probablement occupée → Peugeot Boxer (essence) sera utilisé à la place
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S801', (SELECT id FROM hotel WHERE code = 'IBIS'),    8, '2026-03-15 14:00:00'),
    ('S802', (SELECT id FROM hotel WHERE code = 'COLBERT'), 5, '2026-03-15 14:25:00');

-- ============================================================
-- SCÉNARIO 9 — Même hôtel dans plusieurs réservations d'un lot
-- Fenêtre [15:00, 15:30] : R16(3p→HILTON), R17(2p→HILTON), R18(2p→COLBERT)
-- Même hôtel (HILTON) → une seule étape HILTON dans l'itinéraire
-- Total : 7p → Toyota Land Cruiser (7, diesel) si disponible
-- Itinéraire : IVATO → HILTON(22km) → COLBERT(23km) → IVATO
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S901', (SELECT id FROM hotel WHERE code = 'HILTON'),  3, '2026-03-15 15:00:00'),
    ('S902', (SELECT id FROM hotel WHERE code = 'HILTON'),  2, '2026-03-15 15:10:00'),
    ('S903', (SELECT id FROM hotel WHERE code = 'COLBERT'), 2, '2026-03-15 15:20:00');

-- ============================================================
-- SCÉNARIO 10 — Véhicule revenu disponible (réutilisation)
-- Fenêtre [16:00, 16:30] : R19(10p→NOVOTEL), R20(5p→IBIS) = 15p
-- Si Toyota HiAce (15p, diesel) est revenue → elle est réutilisée
-- Attendu : 1 véhicule, départ 16:10
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S100', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 10, '2026-03-15 16:00:00'),
    ('S110', (SELECT id FROM hotel WHERE code = 'IBIS'),     5, '2026-03-15 16:10:00');

-- ============================================================
-- SCÉNARIO 11 — Plusieurs groupes successifs (fenêtres enchaînées)
-- Groupe A : [17:00, 17:30] → R21(17:00), R22(17:15), R23(17:28) = 3+2+1=6p
-- Groupe B : [17:45, 18:15] → R24(17:45), R25(18:00) = 4+3=7p
-- Groupe C : [18:30, 19:00] → R26(18:30) seul = 5p
-- Chaque groupe démarre exactement après le dernier arrivant du groupe précédent
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    -- Groupe A
    ('S211', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 3, '2026-03-15 17:00:00'),
    ('S212', (SELECT id FROM hotel WHERE code = 'IBIS'),    2, '2026-03-15 17:15:00'),
    ('S213', (SELECT id FROM hotel WHERE code = 'COLBERT'), 1, '2026-03-15 17:28:00'),
    -- Groupe B
    ('S221', (SELECT id FROM hotel WHERE code = 'HILTON'),  4, '2026-03-15 17:45:00'),
    ('S222', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 3, '2026-03-15 18:00:00'),
    -- Groupe C
    ('S231', (SELECT id FROM hotel WHERE code = 'COLBERT'), 5, '2026-03-15 18:30:00');

-- ============================================================
-- SCÉNARIO 12 — Réservation avec 1 seul passager
-- Attendu : Toyota Corolla (5 places, essence) — le plus petit disponible
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S121', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 1, '2026-03-15 19:00:00');

-- ============================================================
-- SCÉNARIO 13 — Véhicule avec capacité exacte
-- 30 passagers → seul Toyota Coaster (30p, diesel)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S131', (SELECT id FROM hotel WHERE code = 'HILTON'),  30, '2026-03-15 20:00:00');

-- ============================================================
-- SCÉNARIO 14 — Réservations tardives + réservation hors capacité mixée
-- Fenêtre [22:00, 22:30] :
--   R_a : 22:00, 2p → COLBERT
--   R_b : 22:15, 3p → HILTON
--   R_c : 22:25, 25p → NOVOTEL  → total 30p → Coaster
-- Ensuite :
--   R_d : 22:45, 35p → NOVOTEL  → non assigné (hors fenêtre, aucun véhicule ≥35)
-- ============================================================
INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
    ('S141', (SELECT id FROM hotel WHERE code = 'COLBERT'), 2,  '2026-03-15 22:00:00'),
    ('S142', (SELECT id FROM hotel WHERE code = 'HILTON'),  3,  '2026-03-15 22:15:00'),
    ('S143', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 25, '2026-03-15 22:25:00'),
    ('S144', (SELECT id FROM hotel WHERE code = 'NOVOTEL'), 35, '2026-03-15 22:45:00');

-- ============================================================
-- RÉSUMÉ DES SCÉNARIOS ATTENDUS
-- ============================================================
SELECT '=== VÉRIFICATION DES DONNÉES INSÉRÉES ===' AS info;

SELECT
    TO_CHAR(r.date_heure_arrivee, 'HH24:MI') AS heure,
    r.id_client                               AS client,
    h.code                                    AS hotel,
    r.nb_passager                             AS passagers,
    CASE
        WHEN r.id_client LIKE 'S1__' THEN 'Scénario 1  - Réservation isolée'
        WHEN r.id_client LIKE 'S2__' THEN 'Scénario 2  - Groupement fenêtre'
        WHEN r.id_client LIKE 'S3__' THEN 'Scénario 3  - Hors fenêtre scénario 2'
        WHEN r.id_client LIKE 'S4__' THEN 'Scénario 4  - Limite exacte / exclusion'
        WHEN r.id_client LIKE 'S5__' THEN 'Scénario 5  - Capacité insuffisante'
        WHEN r.id_client LIKE 'S6__' THEN 'Scénario 6  - Plusieurs véhicules'
        WHEN r.id_client LIKE 'S7__' THEN 'Scénario 7  - Préférence Diesel (9p)'
        WHEN r.id_client LIKE 'S8__' THEN 'Scénario 8  - Préférence Diesel (15p)'
        WHEN r.id_client LIKE 'S9__' THEN 'Scénario 9  - Même hôtel dans lot'
        WHEN r.id_client IN ('S100','S110') THEN 'Scénario 10 - Réutilisation véhicule'
        WHEN r.id_client LIKE 'S2__%' THEN 'Scénario 11 - Groupes successifs'
        WHEN r.id_client = 'S121' THEN 'Scénario 12 - 1 passager'
        WHEN r.id_client = 'S131' THEN 'Scénario 13 - Capacité exacte (30p)'
        WHEN r.id_client LIKE 'S14%' THEN 'Scénario 14 - Tardif + non assigné'
        ELSE '?'
    END AS scenario
FROM reservation r
JOIN hotel h ON h.id = r.id_hotel
WHERE DATE(r.date_heure_arrivee) = '2026-03-15'
ORDER BY r.date_heure_arrivee, r.id_client;

SELECT 'Total réservations insérées :' AS info,
       COUNT(*) AS nb
FROM reservation
WHERE DATE(date_heure_arrivee) = '2026-03-15';

SELECT 'Véhicules disponibles :' AS info;
SELECT id, marque, nb_place, type,
    CASE carburant WHEN 'd' THEN 'Diesel' WHEN 'e' THEN 'Essence' WHEN 'h' THEN 'Hybride' END AS carburant,
    matricule
FROM voiture
ORDER BY nb_place, carburant;
