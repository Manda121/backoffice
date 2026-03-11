
-- Se connecter à la base
\c reservation_sprint5;

-- Table voiture
CREATE TABLE voiture (
    id SERIAL PRIMARY KEY,
    marque VARCHAR(255) NOT NULL,
    nb_place INTEGER NOT NULL,
    type VARCHAR(255) NOT NULL,
    matricule VARCHAR(255) NOT NULL,
    carburant CHAR(1) NOT NULL CHECK (carburant IN ('d', 'e', 'h'))
);

-- Table token
CREATE TABLE token (
    id SERIAL PRIMARY KEY,
    token VARCHAR(255) NOT NULL,
    date_heure_expiration TIMESTAMP NOT NULL
);
