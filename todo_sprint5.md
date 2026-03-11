TEAM LEAD: ETU03377 RAZAFINJATOVO Mialy Soa Lucia
Dev backoffice: ETU003280 MITANTSOA Notiavina Mandaniaina
Dev frontoffice: ETU003354 RANTHOLY Kamel Tommy

TODO Sprint 5 — Gestion du temps d'attente
1. Récupération du paramètre temps_attente (10 min)

Modifier le service qui lit les paramètres.

Récupérer la valeur temps_attente depuis la table parametre.

Convertir la valeur en minutes utilisables dans les calculs.

Vérifier que la valeur existe avant d'exécuter l'algorithme.

2. Service de calcul des groupes temporels (20 min)

Créer le service :

TempsAttenteGroupingService

Responsabilités :

Trier les réservations par date_arrivee ASC.

Déterminer les groupes de réservations selon le temps d’attente.

Algorithme :

Prendre la première réservation restante.

Définir :

heure_initiale = date_arrivee

limite_attente = heure_initiale + temps_attente

Ajouter toutes les réservations avec :

date_arrivee <= limite_attente

Déterminer :

heure_depart = date_arrivee de la dernière réservation du groupe.

Créer un groupe de réservations.

Supprimer ces réservations de la liste.

Recommencer avec les réservations restantes.

Sortie :

List<GroupeReservation>

Chaque groupe contient :

liste de réservations

heure_depart

3. Intégration avec l’algorithme d’assignation (15 min)

Modifier l’algorithme existant dans PlanningController.

Nouvelle logique :

1️- Récupérer toutes les réservations non assignées.

2️- Créer les groupes temporels avec TempsAttenteGroupingService.

3️- Pour chaque groupe :

appeler RegroupementService

appliquer les règles existantes :

capacité voiture

priorité diesel

tie-break aléatoire

4️- Assigner les réservations aux voitures avec la même heure de départ.