TEAM LEAD: ETU003354 RANTHOLY Kamel Tommy
Dev backoffice: ETU03377 RAZAFINJATOVO Mialy Soa Lucia
Dev frontoffice: ETU003280 MITANTSOA Notiavina Mandaniaina

TODO Sprint 6 — Amélioration du système de planification des réservations de voitures

1. Contexte

Le système actuel assigne des voitures aux réservations selon capacité et carburant. Nous devons améliorer l'optimisation, la réassignation et la gestion des tranches horaires.

2. Objectifs

- Améliorer le choix de la voiture optimale
- Optimiser l’ordre de traitement des réservations
- Permettre la réassignation intelligente des réservations non planifiées
- Gérer correctement les tranches horaires de départ
- Recalculer entièrement la planification lors du clic "Planifier"

3. Règles principales & tâches

A. Ordre de traitement des réservations (Tâche 2)
- Règle: trier toutes les réservations par `nb_passager` décroissant avant tout traitement.
- But: prioriser les groupes importants pour meilleure utilisation des véhicules.
- Fichiers: `PlanningController.java`, service de récupération des réservations.
- Critères d'acceptation: liste traitée dans l'ordre décroissant, tests unitaires valides.

B. Priorisation des voitures (Tâche 3)
- Règle: sélection selon
  1) capacité disponible (décroissante)
  2) nombre de trajets déjà effectués (croissante)
  3) type de carburant (diesel priorisé si tiebreak)
- Fichiers: `VehicleSelector` / `RegroupementService` (ou équivalent)
- Critères: comparator ajouté, logs montrant choix en cas d'égalité.

C. Replanification complète (Tâche 4)
- Lors du clic `Planifier`:
  - vérifier si des planifications existent pour la date sélectionnée
  - si oui, supprimer toutes les entrées pour cette date
  - recalculer entièrement la planification et insérer les nouvelles entrées
- Fichiers: endpoint/controller Planifier, DAO `PlanificationDAO`.
- Critères: après Planifier, seule la nouvelle planification existe pour la date.

D. Table `planification` (Tâche 5)
- Si manquante, créer la table avec colonnes minimales: `id`, `date`, `heure_depart`, `reservation_ids` (ou mapping), `vehicle_id`, `created_at`.
- Ajouter script SQL `src/main/resources/db/create_planification.sql` et DAO.

E. Report intelligent des réservations non assignées (Tâche 6)
- Si voitures compatibles sont en trajet, autoriser report vers une réservation ultérieure hors tranche d'attente.
- Respecter la règle: on ne reporte que si la nouvelle date est en dehors de la tranche d'attente initiale.
- Documentation + tests d'exemples.

F. Ajustement de l'heure de départ (Tâche 7)
- Si la voiture optimale revient avant la fin de la tranche, fixer le départ à l'heure de disponibilité.
- Implémenter check de disponibilité dynamique au moment de l'assignation du groupe.

G. Intégration UI (Tâche 8)
- Bouton `Planifier` déclenche endpoint qui exécute la replanification complète pour la date sélectionnée.
- Afficher résultat et erreurs côté UI.

H. Tests & Documentation (Tâche 9)
- Scénarios d'intégration pour: assignation normale, report, replanification, ajustement départ.
- Mettre à jour `README` et `TODO` sprint.

4. Décomposition des tâches (estimation rapide)
1. Rédiger spécification détaillée — 2h
2. Trier réservations (implémentation + tests) — 1.5h
3. Priorisation voitures (implémentation + tests) — 3h
4. Replanification complète + endpoint — 3h
5. Table `planification` + DAO — 1.5h
6. Report intelligent — 3h
7. Ajustement heure départ — 2h
8. UI Planifier — 1.5h
9. Tests & docs — 3h

5. Critères de livraison
- Code compilable et testé
- Scripts SQL disponibles dans `src/main/resources/db/`
- Endpoint `POST /planning/planifier` (ou équivalent) documenté
- Cas de test pour report et ajustement

---

Tâches créées dans le planner; commencez par la Tâche 1 (Spécification) et indiquez si vous voulez que j'implémente directement la Tâche 2 ensuite.