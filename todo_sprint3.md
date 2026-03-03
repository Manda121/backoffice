TEAM LEAD: ETU003354 RANTHOLY Kamel Tommy
Dev backoffice: ETU03377 RAZAFINJATOVO Mialy Soa Lucia
Dev frontoffice: ETU003280 MITANTSOA Notiavina Mandaniaina

===============================================
SPRINT 3: assignation des réservations aux véhicules
===============================================

1. Paramètres système (15 min)
   - Ajouter une table `Parametre` dans la base de données et des champs pour "vitesse moyenne" et "temps d'attente".
   - Exposer ces paramètres dans `application.properties` ou via un contrôleur et vérifier leur lecture.

2. Gestion des lieux et distances (20 min)
   - Créer les entités `Lieu` et `Distance` avec les champs décrits.
   - Implémenter la contrainte empêchant les distances en double (A→B et B→A).
   - Ajouter un service/controller pour gérer ces données et un script d'insertion.

3. Gestion des véhicules (15 min)
   - Ajouter l'entité `Voiture` (ou Véhicule) avec `nb_place` et `type_carburant`.
   - Prévoir un repository et un endpoint REST pour récupérer la liste des véhicules.

4. Amélioration de la réservation (10 min)
   - Mettre à jour l'entité `Reservation` avec lieu de destination, date et nombre de personnes.
   - Adapter le formulaire existant et le contrôleur de sauvegarde.

5. Algorithme d'assignation (25 min)
   - Implémenter les règles de capacité, choix optimal, priorité diesel, et choix aléatoire.
   - Gérer le calcul de durée (distance / vitesse) et l'heure de départ liée au temps d'attente.

6. Interface de planification (15 min)
   - Créer une page JSP pour sélectionner une date et afficher le planning des véhicules :
     véhicules, réservations, départs, arrivées.
   - Ajouter les endpoints backend nécessaires pour alimenter la vue.

7. Scripts de base de données (15 min)
   - Écrire un script de réinitialisation pour supprimer et recréer la base.
   - Écrire un script d'initialisation pour insérer les paramètres, lieux, distances, véhicules.

===============================================
ESTIMATION TOTALE: 115 min
===============================================