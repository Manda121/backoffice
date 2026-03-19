-- ============================================================
-- SCRIPT DE CRÉATION DE LA BASE DE DONNÉES
-- Supprime la base si elle existe, la recrée et crée toutes les tables
-- Usage : psql -U postgres -f reset_db.sql
-- ============================================================

\c postgres;
DROP DATABASE IF EXISTS reservationsprint7;
CREATE DATABASE reservationsprint7;
\c reservationsprint7;

-- ============================================================
-- TABLE : hotel
-- ============================================================
CREATE TABLE hotel (
    id         SERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    ville      VARCHAR(255) NOT NULL,
    adresse    VARCHAR(255) NOT NULL,
    code       VARCHAR(100) UNIQUE,
    is_airport BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- TABLE : reservation
-- ============================================================
CREATE TABLE reservation (
    id                 SERIAL PRIMARY KEY,
    id_client          VARCHAR(4)   NOT NULL,
    id_hotel           INTEGER      NOT NULL,
    nb_passager        INTEGER      NOT NULL,
    date_heure_arrivee TIMESTAMP    NOT NULL,
    nom                VARCHAR(255),
    CONSTRAINT fk_hotel FOREIGN KEY (id_hotel) REFERENCES hotel(id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE : voiture
-- ============================================================
CREATE TABLE voiture (
    id        SERIAL PRIMARY KEY,
    marque    VARCHAR(255) NOT NULL,
    nb_place  INTEGER      NOT NULL,
    type      VARCHAR(255) NOT NULL,
    matricule VARCHAR(255) NOT NULL,
    carburant CHAR(1)      NOT NULL CHECK (carburant IN ('d', 'e', 'h'))
);

-- ============================================================
-- TABLE : planification
-- ============================================================
CREATE TABLE planification (
    id                     SERIAL PRIMARY KEY,
    reservation_id         INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,
    voiture_id             INTEGER NOT NULL REFERENCES voiture(id) ON DELETE CASCADE,
    date_planning          DATE NOT NULL,
    heure_depart           TIMESTAMP NOT NULL,
    heure_arrivee_hotel    TIMESTAMP NOT NULL,
    heure_retour_aeroport  TIMESTAMP NOT NULL,
    distance_km            DOUBLE PRECISION NOT NULL DEFAULT 0,
    created_at             TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE : token
-- ============================================================
CREATE TABLE token (
    id                    SERIAL PRIMARY KEY,
    token                 VARCHAR(255) NOT NULL,
    date_heure_expiration TIMESTAMP    NOT NULL
);

-- ============================================================
-- TABLE : distance
-- ============================================================
CREATE TABLE distance (
    id        SERIAL PRIMARY KEY,
    lieu_from INTEGER        NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
    lieu_to   INTEGER        NOT NULL REFERENCES hotel(id) ON DELETE CASCADE,
    km        DECIMAL(10,2)  NOT NULL,
    CONSTRAINT chk_no_self_distance CHECK (lieu_from <> lieu_to)
);

CREATE UNIQUE INDEX idx_distance_unique_pair
    ON distance (LEAST(lieu_from, lieu_to), GREATEST(lieu_from, lieu_to));

-- ============================================================
-- TABLE : parametre
-- ============================================================
CREATE TABLE parametre (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(100) NOT NULL UNIQUE,
    valeur      VARCHAR(255) NOT NULL,
    description VARCHAR(500)
);

SELECT 'Base de données créée avec succès !' AS status;