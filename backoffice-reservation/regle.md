# Règles de gestion du projet backoffice-reservation

## Règles d’assignation existantes
- Capacité minimale suffisante pour chaque lot de passagers, avec sélection du véhicule à capacité la plus proche (plus petite suffisante).
- Priorité carburant à capacité égale : Diesel > Essence > Hybride ; à égalité totale, choix du plus petit identifiant.
- Les véhicules doivent être disponibles à l’heure initiale de tranche pour leur premier trajet ; ensuite ils peuvent repartir s’ils reviennent avant la fin de la fenêtre.
- Les réservations sont regroupées par fenêtre glissante de `temps_attente` minutes : ancre = première réservation non affectée, candidates ≤ (ancre + fenêtre).
- Ordonnancement dans un groupe : passagers décroissants (réservation la plus volumineuse d’abord) puis heure d’arrivée croissante.
- Split autorisé : si aucun véhicule ne peut tout prendre, on découpe sur le véhicule le plus capacitaire disponible.
- Départ effectif : par défaut à l’arrivée de la dernière réservation du groupe, ajusté au retour du véhicule si celui-ci revient pendant la fenêtre ; retour fixe l’heure de prochaine disponibilité.
- Persisté dans `planification` : chaque réservation affectée stocke voiture, date, heures de départ/arrivée/retour et distance.

## Nouvelles fonctionnalités (gestion des réservations en attente)
- File d’attente des réservations non assignées faute de véhicule disponible. Ces réservations sont prioritaires sur les nouvelles lors du prochain cycle d’assignation.
- Si des réservations sont en attente et qu’un véhicule revient :
  - Les réservations en attente deviennent l’ancre de la nouvelle tranche.
  - Si elles remplissent totalement un véhicule, celui-ci repart immédiatement à son retour (sans attendre la fin de fenêtre).
  - Si elles ne le remplissent pas, le véhicule attend la durée `temps_attente` pour capter d’éventuelles nouvelles réservations avant de partir.
- Tant qu’aucun véhicule ne revient, les réservations en attente patientent et restent prioritaires sur toute nouvelle réservation, quel que soit le nombre.
- Les règles d’assignation de capacité et de carburant restent inchangées ; seules les priorités et le timing de départ évoluent pour intégrer la file d’attente.
