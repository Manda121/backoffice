-- ============================================================
-- SPRINT 2 : Système d'assignation de réservations aux véhicules
-- À exécuter APRÈS create_reservation.sql et create_car_and_token.sql
-- ============================================================

\c reservation;

-- Ajout de la colonne matricule au véhicule (si elle n'existe pas déjà)
ALTER TABLE voiture ADD COLUMN IF NOT EXISTS matricule VARCHAR(50);

-- --------------------------------------------------------
-- Table LIEU : points de départ/arrivée (hôtels, aéroport…)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS lieu (
    id         SERIAL PRIMARY KEY,
    code       VARCHAR(100) NOT NULL UNIQUE,
    is_airport BOOLEAN NOT NULL DEFAULT FALSE
);

-- --------------------------------------------------------
-- Table DISTANCE : distances entre lieux (sans redondance)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS distance (
    id         SERIAL PRIMARY KEY,
    lieu_from  INT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    lieu_to    INT NOT NULL REFERENCES lieu(id) ON DELETE CASCADE,
    km         DECIMAL(10,2) NOT NULL,
    CONSTRAINT chk_no_self_distance CHECK (lieu_from <> lieu_to)
);

-- Index unique pour empêcher la redondance (A→B interdit si B→A existe)
CREATE UNIQUE INDEX IF NOT EXISTS idx_distance_unique_pair
ON distance (LEAST(lieu_from, lieu_to), GREATEST(lieu_from, lieu_to));

-- --------------------------------------------------------
-- Table PARAMETRE : paramètres configurables du système
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS parametre (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(100) NOT NULL UNIQUE,
    valeur      VARCHAR(255) NOT NULL,
    description VARCHAR(500)
);

-- --------------------------------------------------------
-- Modification de RESERVATION : ajout du lieu de destination
-- --------------------------------------------------------
ALTER TABLE reservation
    ADD COLUMN IF NOT EXISTS id_lieu_destination INT REFERENCES lieu(id) ON DELETE SET NULL;
