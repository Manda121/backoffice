# TODO Sprint 7

TEAM LEAD:  ETU003280 MITANTSOA Notiavina Mandaniaina
Dev backoffice: ETU003354 RANTHOLY Kamel Tommy
Dev frontoffice: ETU03377 RAZAFINJATOVO Mialy Soa Lucia

TODO Sprint 7 — Découpage d’une réservation sur plusieurs voitures

## 1. Contexte

Le sprint 6 a stabilisé la planification (priorisation, report intelligent, replanification complète, ajustement des départs).
Le sprint 7 ajoute une seule évolution métier : une même réservation peut être transportée par plusieurs voitures.

## 2. Objectif principal

- Autoriser le transport partiel d’une réservation (split des passagers) sur plusieurs départs/voitures,
  tout en conservant les règles existantes du sprint 6.

## 3. Règles métier Sprint 7

A. Split d’une réservation

- Si une réservation a N passagers et qu’aucune voiture ne peut prendre N en une fois,
  le système peut affecter une partie des passagers à une première voiture, puis le reliquat à d’autres voitures.
- Le split peut se produire dans la même tranche si plusieurs voitures sont disponibles.
- Le reliquat peut être reporté (règle de report intelligent inchangée) si aucune voiture n’est disponible immédiatement.

B. Compatibilité Sprint 6 conservée

- Ordre de traitement des groupes inchangé.
- Priorisation véhicule inchangée (carburant/nb trajets/capacité selon implémentation actuelle).
- Replanification complète lors du clic “Planifier” inchangée.
- Ajustement de l’heure de départ selon disponibilité véhicule inchangé.

C. Affichage et persistance

- Le planning peut afficher plusieurs lignes avec le même ID de réservation,
  chacune avec un nombre de passagers affectés différent.
- Les passagers non transportés restent visibles dans “non assignées” avec le reliquat.

## 4. Tâches techniques

1) Adapter l’algorithme de planification pour gérer un reliquat de passagers par réservation.
2) Créer des "sous-assignations" (copies logiques de réservation avec nb_passager partiel).
3) Conserver le mécanisme de report intelligent pour les reliquats.
4) Vérifier la persistance de planification pour les réservations splittées.
5) Vérifier l’affichage UI (doublons d’ID de réservation autorisés).
6) Ajouter tests d’intégration pour cas de split.
7) Mettre à jour la documentation (README + exemple de scénario).

## 5. Scénarios de test minimaux

- Cas 1: Réservation de 10 passagers, voitures de 6 et 4 disponibles => split 6 + 4.
- Cas 2: Réservation de 10 passagers, seule voiture de 6 disponible dans tranche => 6 planifiés, 4 reportés.
- Cas 3: Reliquat reporté puis absorbé dans tranche ultérieure.
- Cas 4: Plusieurs réservations + split, vérifier absence de régression des règles Sprint 6.

## 6. Critères de livraison

- Code compilable
- Split effectif d’une réservation sur plusieurs voitures
- Report du reliquat fonctionnel
- UI lisible avec plusieurs lignes pour une même réservation
- Documentation Sprint 7 disponible
