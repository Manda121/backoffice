TEAM LEAD: ETU003354 RANTHOLY Kamel Tommy
Dev backoffice: ETU03377 RAZAFINJATOVO Mialy Soa Lucia
Dev frontoffice: ETU003280 MITANTSOA Notiavina Mandaniaina

===============================================
SPRINT 3: Système d'assignation de réservations aux véhicules
===============================================

1. Créer les modèles et tables (30 min) — état actuel
   - Créer `Lieu.java` (id, code) et `Distance.java` (id, from, to, km) dans le package models. (À FAIRE)
   - Créer `Parametre.java` (id, cle, valeur) pour gérer vitesse_moyenne et temps_attente. (À FAIRE)
   - `Voiture.java` : déjà présent dans `backoffice-reservation/src/main/java/models/Voiture.java` — contient `nbPlace` et `carburant` utilisés par `VoitureController`.
   - Script SQL `init-sprint3.sql` (À FAIRE) — voir `init-data-sprint3.sql` pour insérer les lieux/distances/paramètres (non présent actuellement).

2. Scripts de gestion BD (10 min)
   - Créer `reset_db_sprint3.sql` pour réinitialiser la base de données.
   - Créer `init-data-sprint3.sql` pour insérer les lieux (Aéroport, Hôtel Colbert, etc.), distances et paramètres par défaut.

3. Services métier (40 min)
   - Créer `AssignationService.java` qui implémente l'algorithme d'assignation selon les règles :
     * Règle 1 : Capacité minimale
     * Règle 2 : Capacité optimale (la plus proche)
     * Règle 3 : Priorité Diesel
     * Règle 4 : Choix aléatoire si égalité
   - Créer `TrajetService.java` pour calculer durée trajet (distance / vitesse_moyenne) et heures d'arrivée.
   - Créer `PlanificationService.java` pour gérer le temps d'attente et grouper les réservations.

4. Endpoints backend planification (30 min) — état actuel
    - `GET /api/planification?date={date}` dans `PlanificationController.java` (À FAIRE)
       * Doit retourner : liste des véhicules, réservations assignées, heure départ/arrivée.
    - `POST /api/reservations/assigner` (À FAIRE)
    - Remarque : les endpoints existants identifiés dans le projet actuellement sont :
       * `GET /api/reservations` (implémenté dans `ReservationController`)
       * `GET /api/voitures` (implémenté dans `VoitureController`) — notez la casse: `voitures` en minuscules.

5. Interface de planification (25 min)
    - `planification.jsp` (À FAIRE)
       * Formulaire de sélection de date
       * Tableau : Véhicule | Réservations | Heure départ | Heure arrivée
    - Ajouter appel AJAX vers `GET /api/planification` (À FAIRE)

6. Gestion des paramètres système (20 min)
    - `ParametreController.java` (À FAIRE)
       * `GET /api/parametres` (À FAIRE)
       * `PUT /api/parametres/{cle}` (À FAIRE)
    - `parametres.jsp` (À FAIRE)

7. Gestion des lieux et distances (25 min)
   - `LieuController.java` avec CRUD (À FAIRE)
   - `DistanceController.java` avec validation anti-redondance (À FAIRE)
   - `lieux.jsp` et `distances.jsp` (À FAIRE)

8. Tests et validation (15 min)
   - Tests unitaires et scénarios d'assignation (À FAIRE)
   - Vérifier calculs durée trajet / heures d'arrivée (À FAIRE)

===============================================
ESTIMATION TOTALE: 195 min (3h15)
===============================================

Priorités :
- Phase 1 (Fondations) : Tâches 1, 2 → 40 min
- Phase 2 (Logique métier) : Tâches 3, 4 → 70 min
- Phase 3 (Interface utilisateur) : Tâches 5, 6, 7 → 70 min
- Phase 4 (Validation) : Tâche 8 → 15 min
