-- ============================================================
-- SCRIPT DE RÉINITIALISATION COMPLÈTE
-- Supprime la base, la recrée et exécute tous les scripts
-- Usage : psql -U postgres -f reset_db.sql
-- ============================================================

\c postgres;
DROP DATABASE IF EXISTS reservation_sprint5;

-- Recrée la base
CREATE DATABASE reservation_sprint5;

-- Exécute tous les scripts de création
\i create_reservation.sql
\i create_car_and_token.sql
\i create_sprint2.sql

-- Exécute les données initiales
\i init-database.sql
\i init_sprint2.sql
\i init_sprint5.sql

SELECT 'Base de données réinitialisée avec succès !' AS status;