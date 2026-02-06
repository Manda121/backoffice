-- Supprimer la base si elle existe
\c postgres;

DROP DATABASE IF EXISTS reservation;

-- Créer la base
CREATE DATABASE reservation;

-- Se connecter à la base
\c reservation;

-- Create hotel table if missing
CREATE TABLE IF NOT EXISTS hotel (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    ville VARCHAR(255) NOT NULL,
    adresse VARCHAR(255) NOT NULL
);

-- Create reservation table if missing
CREATE TABLE IF NOT EXISTS reservation (
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

-- Add missing columns to reservation if they don't exist
ALTER TABLE reservation
  ADD COLUMN IF NOT EXISTS id_client VARCHAR(4) NOT NULL DEFAULT '0000';

ALTER TABLE reservation
  ADD COLUMN IF NOT EXISTS id_hotel INTEGER NOT NULL DEFAULT 1;

ALTER TABLE reservation
  ADD COLUMN IF NOT EXISTS nb_passager INTEGER NOT NULL DEFAULT 1;

ALTER TABLE reservation
  ADD COLUMN IF NOT EXISTS date_heure_arrivee TIMESTAMP NOT NULL DEFAULT now();

-- Ensure foreign key exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name = 'reservation'
        AND kcu.column_name = 'id_hotel'
    ) THEN
        ALTER TABLE reservation ADD CONSTRAINT fk_hotel FOREIGN KEY (id_hotel) REFERENCES hotel(id) ON DELETE CASCADE;
    END IF;
END$$;

-- Ensure 'nom' column exists and is nullable to avoid NOT NULL errors
ALTER TABLE reservation ADD COLUMN IF NOT EXISTS nom VARCHAR(255);

-- Populate existing NULL values sensibly (copy from id_client when available, else 'Unknown')
UPDATE reservation SET nom = id_client WHERE nom IS NULL AND id_client IS NOT NULL;
UPDATE reservation SET nom = 'Unknown' WHERE nom IS NULL;

-- Make column nullable (drop NOT NULL if present)
ALTER TABLE reservation ALTER COLUMN nom DROP NOT NULL;