-- Supprimer la base si elle existe
\c postgres;

DROP DATABASE IF EXISTS reservation;

-- Créer la base
CREATE DATABASE reservation;

-- Se connecter à la base
\c reservation;

-- Table hotel
CREATE TABLE hotel (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    ville VARCHAR(255) NOT NULL,
    adresse VARCHAR(255) NOT NULL
);

-- Table reservation
CREATE TABLE reservation (
    id SERIAL PRIMARY KEY,
    id_client VARCHAR(4) NOT NULL,
    id_hotel INTEGER NOT NULL,
    nb_passager INTEGER NOT NULL,
    date_heure_arrivee TIMESTAMP NOT NULL,
    CONSTRAINT fk_hotel
        FOREIGN KEY (id_hotel)
        REFERENCES hotel(id)
        ON DELETE CASCADE
);
