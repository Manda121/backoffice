-- Insertion des données d'hôtels
INSERT INTO hotel (name, ville, adresse) VALUES
('Hilbert', 'Antananarivo', '29 Rue Printsy Ratsimamanga'),
('Novotel', 'Antananarivo', 'Anosy, 101'),
('Ibis', 'Antananarivo', 'Avenue de l''Indépendance'),
('Lokanga', 'Antsirabe', 'Route d''Ambositra'),
('Hilton', 'Antananarivo', 'Rue Ambohibao, Antananarivo');

-- Afficher les données insérées
SELECT 'Hotels insérés:' as info;
SELECT * FROM hotel;

-- INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
-- ('4631', 3, 11, '2026-02-05 00:01:00'),
-- ('4394', 3, 1, '2026-02-05 23:55:00'),
-- ('8054', 1, 2, '2026-02-09 10:17:00'),
-- ('1432', 2, 4, '2026-02-01 15:25:00'),
-- ('7861', 1, 4, '2026-01-28 07:11:00'),
-- ('3308', 1, 5, '2026-01-28 07:45:00'),
-- ('4484', 2, 13, '2026-02-28 08:25:00'),
-- ('9687', 2, 8, '2026-02-28 13:00:00'),
-- ('6302', 1, 7, '2026-02-15 13:00:00'),
-- ('8640', 4, 1, '2026-02-18 22:55:00');

INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) VALUES
('4631', 1, 11, '2026-03-11 11:00:00'),
('4394', 5, 1, '2026-03-11 11:00:00');