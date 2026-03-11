-- ============================================================
-- SPRINT 2+3 : Système d'assignation de réservations aux véhicules
-- La table lieu est remplacée par des colonnes code/is_airport dans hotel
-- ============================================================

\c reservation_sprint5;

-- Ajout de la colonne matricule au véhicule (si elle n'existe pas déjà)
ALTER TABLE voiture ADD COLUMN IF NOT EXISTS matricule VARCHAR(50);

-- --------------------------------------------------------
-- Ajout de code et is_airport dans hotel (remplace la table lieu)
-- --------------------------------------------------------
ALTER TABLE hotel ADD COLUMN IF NOT EXISTS code VARCHAR(100) UNIQUE;
ALTER TABLE hotel ADD COLUMN IF NOT EXISTS is_airport BOOLEAN NOT NULL DEFAULT FALSE;

-- Nettoyage de l'ancienne structure si elle existait (migration)
ALTER TABLE reservation DROP COLUMN IF EXISTS id_lieu_destination;
DROP TABLE IF EXISTS distance CASCADE;
DROP TABLE IF EXISTS lieu CASCADE;

-- --------------------------------------------------------
-- Table DISTANCE : distances entre hôtels (sans redondance)
-- Utilise maintenant hotel(id) au lieu de lieu(id)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS distance (
    id         SERIAL PRIMARY KEY,
    lieu_from  INT NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
    lieu_to    INT NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
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

