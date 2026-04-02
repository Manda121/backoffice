package controller;

import java.sql.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyParam;
import itu.framework.annotations.MyURL;
import itu.framework.db.DatabaseConnection;
import itu.framework.model.ModelView;
import models.PlanningEntry;
import models.Reservation;
import models.Voiture;

@MyController
public class PlanningController {

    // =========================================================================
    //  FORM
    // =========================================================================
    @MyURL(value = "/planning/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("planning.jsp");
        return mv;
    }

    // =========================================================================
    //  RESULT
    // =========================================================================
    @MyURL(value = "/planning/result", method = "GET")
    public ModelView computePlanning(@MyParam(value = "date") String date) {
        ModelView mv = new ModelView();
        mv.setView("planning.jsp");
        mv.addItem("date", date);

        if (date == null || date.trim().isEmpty()) {
            mv.addItem("error", "Veuillez saisir une date.");
            return mv;
        }

        try {
            int    tempsAttenteMin = ParametreController.getParamInt("temps_attente", 30);
            double vitesseKmH     = ParametreController.getParamDouble("vitesse_moyenne", 30.0);
            int    airportId      = getAirportId();

            List<Reservation> reservations = getReservationsForDate(date);
            reservations.sort(Comparator.comparing(Reservation::getDateHeureArrivee));

            List<Voiture> voitures = getAllVoitures();
            if (voitures.isEmpty()) {
                mv.addItem("error", "Aucun véhicule enregistré dans le système.");
                return mv;
            }

            List<Reservation> nonAssignees = new ArrayList<>();
            LocalDate planningDate = LocalDate.parse(date);

            List<PlanningEntry> planning = assignReservations(
                    reservations, voitures, vitesseKmH, airportId,
                    planningDate, nonAssignees);

            persistPlanningForDate(date, planning);

            mv.addItem("planning", planning);
            mv.addItem("unassigned", nonAssignees);
            mv.addItem("totalReservations", reservations.size());
            mv.addItem("tempsAttente", tempsAttenteMin);
            mv.addItem("vitesse", vitesseKmH);

        } catch (Exception e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors du calcul du planning : " + e.getMessage());
        }

        return mv;
    }

    // =========================================================================
    //  ÉTAT INTERNE DE L'ALGORITHME
    // =========================================================================
    private static class PlanningState {

        final List<Voiture>        voitures;
        final int                  tempsAttenteMin;
        final double               vitesseKmH;
        final int                  airportId;
        final Map<Integer, String> hotelCodeMap;
        final String               airportCode;
        final List<Reservation>    reservations;

        final int[]                        restants;
        final Map<Integer, LocalDateTime>  vehiculeDispo;
        final Map<Integer, Integer>        nbTrajets;
        final List<PlanningEntry>          entries;

        /**
         * Backlog : indices (dans {@code reservations}) des réservations qui n'ont pas
         * pu être prises lors d'un tour précédent.
         * - PRIORITÉ ABSOLUE sur toutes les nouvelles réservations.
         * - LinkedHashSet : ordre d'insertion conservé (= ordre chronologique d'entrée).
         */
        final Set<Integer> backlog;

        PlanningState(List<Reservation> reservations, List<Voiture> voitures,
                      double vitesseKmH, int airportId,
                      Map<Integer, String> hotelCodeMap, String airportCode,
                      int tempsAttenteMin,
                      Map<Integer, LocalDateTime> dispoPar, LocalDate planningDate) {

            this.reservations    = reservations;
            this.voitures        = voitures;
            this.vitesseKmH      = vitesseKmH;
            this.airportId       = airportId;
            this.hotelCodeMap    = hotelCodeMap;
            this.airportCode     = airportCode;
            this.tempsAttenteMin = tempsAttenteMin;

            this.restants = new int[reservations.size()];
            for (int i = 0; i < reservations.size(); i++)
                this.restants[i] = Math.max(0, reservations.get(i).getNbPassager());

            this.vehiculeDispo = new HashMap<>();
            this.nbTrajets     = new HashMap<>();
            for (Voiture v : voitures) {
                LocalDateTime d = dispoPar.get(v.getId());
                this.vehiculeDispo.put(v.getId(), d != null ? d : planningDate.atStartOfDay());
                this.nbTrajets.put(v.getId(), 0);
            }

            this.entries = new ArrayList<>();
            this.backlog = new LinkedHashSet<>();
        }

        /** Nombre total de passagers encore en attente dans le backlog. */
        int totalBacklogPassagers() {
            return backlog.stream().mapToInt(i -> restants[i]).sum();
        }

        /** Indices du backlog ayant encore des passagers restants. */
        List<Integer> backlogActifs() {
            return backlog.stream().filter(i -> restants[i] > 0).collect(Collectors.toList());
        }

        /** True si au moins une réservation non assignée existe (backlog ou nouvelle). */
        boolean hasRemainingWork() {
            for (int r : restants) if (r > 0) return true;
            return false;
        }

        /** Prochaine disponibilité parmi tous les véhicules. */
        LocalDateTime prochainDispoVehicule() {
            return vehiculeDispo.values().stream()
                    .filter(Objects::nonNull)
                    .min(LocalDateTime::compareTo)
                    .orElse(null);
        }
    }

    // =========================================================================
    //  ALGORITHME PRINCIPAL
    // =========================================================================
    /**
     * Orchestre l'assignation complète pour une journée.
     *
     * Principe fondamental :
     *   Les véhicules font des allers-retours jusqu'à ce que TOUTES les réservations
     *   soient assignées. Il ne peut y avoir de réservations non assignées tant qu'au
     *   moins un véhicule existe et a une capacité > 0.
     *
     * Déroulement d'une itération :
     *   1. Déterminer l'ancre (backlog en priorité, puis nouvelles résa).
     *   2. Calculer la fenêtre [ancre, ancre + temps_attente].
     *   3. Si aucun véhicule n'est disponible dans la fenêtre, avancer l'ancre
     *      à la prochaine dispo véhicule (les véhicules reviennent de course).
     *   4. Constituer et dispatcher les lots via {@link #traiterBacklogPourVehicule}.
     *   5. Les réservations non prises dans cette fenêtre rejoignent le backlog.
     *   6. Retour en 1 — la boucle continue tant qu'il reste des passagers à transporter.
     *
     * Seul cas de non-assignation définitive :
     *   Une réservation dont le nombre de passagers dépasse la capacité maximale de
     *   TOUS les véhicules du système (impossible physiquement, même avec des splits).
     */
    private List<PlanningEntry> assignReservations(
            List<Reservation> reservations,
            List<Voiture> voitures,
            double vitesseKmH,
            int airportId,
            LocalDate planningDate,
            List<Reservation> definitivementNonAssignees) throws SQLException {

        int tempsAttenteMin = ParametreController.getParamInt("temps_attente", 30);
        Map<Integer, String> hotelCodeMap = getHotelCodeMap();
        String airportCode = hotelCodeMap.getOrDefault(airportId, "IVATO");

        PlanningState state = new PlanningState(
                reservations, voitures, vitesseKmH, airportId,
                hotelCodeMap, airportCode, tempsAttenteMin,
                getVoitureDisponibiliteInitiale(planningDate), planningDate);

        // Capacité maximale d'un véhicule : si un groupe de passagers dépasse ce seuil,
        // il ne pourra jamais être entièrement transporté en un seul voyage mais PEUT
        // l'être en plusieurs (split). Seul un passager isolé > maxCap est impossible.
        int maxCapVehicule = voitures.stream().mapToInt(Voiture::getNbPlace).max().orElse(0);

        // ── Boucle principale ─────────────────────────────────────────────────────
        // Continue tant qu'il reste des passagers à transporter.
        while (state.hasRemainingWork()) {

            // ------------------------------------------------------------------
            // ÉTAPE 1 — Trouver l'ancre
            // Le backlog est prioritaire : on y cherche d'abord.
            // ------------------------------------------------------------------
            int anchorIdx        = -1;
            LocalDateTime anchorTime = null;

            for (int i : state.backlog) {
                if (state.restants[i] <= 0) continue;
                LocalDateTime t = reservations.get(i).getDateHeureArrivee().toLocalDateTime();
                if (anchorTime == null || t.isBefore(anchorTime)) { anchorTime = t; anchorIdx = i; }
            }
            if (anchorIdx < 0) {
                // Pas de backlog actif : chercher dans les nouvelles réservations
                for (int i = 0; i < reservations.size(); i++) {
                    if (state.restants[i] <= 0 || state.backlog.contains(i)) continue;
                    LocalDateTime t = reservations.get(i).getDateHeureArrivee().toLocalDateTime();
                    if (anchorTime == null || t.isBefore(anchorTime)) { anchorTime = t; anchorIdx = i; }
                }
            }
            if (anchorIdx < 0) break; // sécurité (ne devrait pas arriver vu hasRemainingWork())

            // ------------------------------------------------------------------
            // ÉTAPE 2 — Fenêtre et véhicules éligibles
            // ------------------------------------------------------------------
            LocalDateTime fenetreMax = anchorTime.plusMinutes(tempsAttenteMin);

            List<Voiture> vehiculesEligibles = eligiblesDansFenetre(state, fenetreMax);

            if (vehiculesEligibles.isEmpty()) {
                // Aucun véhicule disponible dans cette fenêtre.
                // Les véhicules sont tous en course → attendre le prochain retour.
                // On décale l'ancre à la prochaine dispo véhicule (retour de course).
                LocalDateTime prochaineDispo = state.prochainDispoVehicule();
                if (prochaineDispo == null) break; // aucun véhicule du tout (impossible normalement)

                anchorTime         = prochaineDispo;
                fenetreMax         = anchorTime.plusMinutes(tempsAttenteMin);
                vehiculesEligibles = eligiblesDansFenetre(state, fenetreMax);

                if (vehiculesEligibles.isEmpty()) break; // sécurité
            }

            // ------------------------------------------------------------------
            // ÉTAPE 3 — Nouvelles réservations dans la fenêtre (hors backlog)
            // ------------------------------------------------------------------
            final LocalDateTime fMax = fenetreMax;
            List<Integer> nouvellesIdx = new ArrayList<>();
            for (int i = 0; i < reservations.size(); i++) {
                if (state.restants[i] <= 0 || state.backlog.contains(i)) continue;
                if (!reservations.get(i).getDateHeureArrivee().toLocalDateTime().isAfter(fMax))
                    nouvellesIdx.add(i);
            }

            // ------------------------------------------------------------------
            // ÉTAPE 4 — Dispatcher les lots : un véhicule à la fois
            // ------------------------------------------------------------------
            Set<Integer> vehiculesUtilises = new HashSet<>();
            boolean progressMade = true;

            while (progressMade) {
                progressMade = false;

                List<Integer> bActifs = state.backlogActifs();
                List<Integer> nActifs = nouvellesIdx.stream()
                        .filter(i -> state.restants[i] > 0).collect(Collectors.toList());
                if (bActifs.isEmpty() && nActifs.isEmpty()) break;

                List<Voiture> disponibles = vehiculesEligibles.stream()
                        .filter(v -> !vehiculesUtilises.contains(v.getId()))
                        .collect(Collectors.toList());
                if (disponibles.isEmpty()) break;

                boolean lotCree = traiterBacklogPourVehicule(
                        state, disponibles, bActifs, nActifs, vehiculesUtilises);

                if (lotCree) progressMade = true;
            }

            // ------------------------------------------------------------------
            // ÉTAPE 5 — Réservations non prises dans cette fenêtre → backlog
            // Elles deviendront prioritaires au prochain tour (quand un véhicule
            // reviendra de course).
            // ------------------------------------------------------------------
            for (int i : nouvellesIdx) {
                if (state.restants[i] > 0) state.backlog.add(i);
            }
            state.backlog.removeIf(i -> state.restants[i] <= 0);

            // ------------------------------------------------------------------
            // ÉTAPE 6 — Détection des réservations impossibles à transporter
            // (passagers > capacité max de tous les véhicules, même en plusieurs
            //  passes → impossible physiquement)
            // ------------------------------------------------------------------
            if (maxCapVehicule > 0) {
                // On ne marque non-assigné que ce qui est vraiment impossible :
                // une réservation dont restant > 0 ET dont TOUS les véhicules
                // ont déjà été utilisés dans cette fenêtre sans pouvoir la prendre.
                // En pratique, avec le split autorisé et les boucles de retour,
                // ce cas ne se produit que si maxCapVehicule == 0.
                // On laisse donc la boucle principale continuer naturellement.
            } else {
                // Aucun véhicule n'a de capacité → impossible d'assigner quoi que ce soit
                for (int i = 0; i < reservations.size(); i++) {
                    if (state.restants[i] <= 0) continue;
                    Reservation r   = reservations.get(i);
                    Reservation rel = copyReservationWithPassengers(r, state.restants[i]);
                    rel.setUnassignedReason("Aucun véhicule avec capacité disponible.");
                    definitivementNonAssignees.add(rel);
                    state.restants[i] = 0;
                }
                state.backlog.clear();
                break;
            }
        }

        return state.entries;
    }

    // =========================================================================
    //  MÉTHODE DÉDIÉE : LOGIQUE BACKLOG + DÉPART IMMÉDIAT / AVEC ATTENTE
    // =========================================================================
    /**
     * Sélectionne un véhicule, constitue son lot selon les règles backlog,
     * calcule l'heure de départ et enregistre le trajet.
     *
     * ┌─────────────────────────────────────────────────────────────────────┐
     * │ RÈGLE 1 — PRIORITÉ ABSOLUE DU BACKLOG                              │
     * │   Les réservations en attente (backlog) passent TOUJOURS avant les  │
     * │   nouvelles, quel que soit leur nombre de passagers.                │
     * ├─────────────────────────────────────────────────────────────────────┤
     * │ RÈGLE 2 — DÉPART IMMÉDIAT                                          │
     * │   Condition : backlog_passagers >= capacité du véhicule.           │
     * │   → Lot constitué UNIQUEMENT du backlog (pas de nouvelles résa).   │
     * │   → Départ = dispo_véhicule (aucune attente).                      │
     * ├─────────────────────────────────────────────────────────────────────┤
     * │ RÈGLE 3 — ATTENTE                                                  │
     * │   Condition : backlog_passagers < capacité du véhicule.            │
     * │   → Backlog en premier, puis nouvelles résa de la fenêtre.         │
     * │   → Départ = MAX(dernière arrivée du lot, dispo_véhicule).         │
     * ├─────────────────────────────────────────────────────────────────────┤
     * │ RÈGLE 4 — PAS DE BACKLOG                                           │
     * │   Traitement normal, nouvelles réservations uniquement.            │
     * │   → Départ = MAX(dernière arrivée du lot, dispo_véhicule).         │
     * └─────────────────────────────────────────────────────────────────────┘
     *
     * @return {@code true} si un lot a été créé et enregistré.
     */
    private boolean traiterBacklogPourVehicule(
            PlanningState state,
            List<Voiture> disponibles,
            List<Integer> bActifs,
            List<Integer> nActifs,
            Set<Integer>  vehiculesUtilises) throws SQLException {

        int totalBacklog  = bActifs.stream().mapToInt(i -> state.restants[i]).sum();
        int totalGroupe   = totalBacklog + nActifs.stream().mapToInt(i -> state.restants[i]).sum();
        int maxIndividuel = 0;
        for (int i : bActifs) maxIndividuel = Math.max(maxIndividuel, state.restants[i]);
        for (int i : nActifs) maxIndividuel = Math.max(maxIndividuel, state.restants[i]);

        // ── Sélection du véhicule ─────────────────────────────────────────────
        Voiture selectionne = selectMeilleurVehicule(disponibles, totalGroupe,   state.nbTrajets);
        if (selectionne == null)
            selectionne     = selectMeilleurVehicule(disponibles, maxIndividuel, state.nbTrajets);
        if (selectionne == null)
            selectionne     = selectVehiculePourSplit(disponibles,               state.nbTrajets);
        if (selectionne == null) return false;

        vehiculesUtilises.add(selectionne.getId());
        int capaciteVehicule = selectionne.getNbPlace();

        // ── Règle 2 : départ immédiat si le backlog remplit le véhicule ──────
        boolean departImmédiat = !bActifs.isEmpty() && totalBacklog >= capaciteVehicule;

        // ── Constitution du lot ───────────────────────────────────────────────
        //   Départ immédiat → candidats = backlog uniquement
        //   Attente         → candidats = backlog EN PREMIER, puis nouvelles
        List<Integer> candidatsLot = new ArrayList<>(bActifs);
        if (!departImmédiat) candidatsLot.addAll(nActifs);

        List<Reservation> lot   = new ArrayList<>();
        int capaciteRestante    = capaciteVehicule;

        while (capaciteRestante > 0 && !candidatsLot.isEmpty()) {
            final int capR = capaciteRestante;

            // Choix de la meilleure réservation candidate :
            //   a) backlog avant nouvelles
            //   b) reliquat le plus proche de la capacité restante
            //   c) à égalité : plus grand reliquat
            //   d) à égalité : index le plus petit (ordre chronologique)
            Integer bestIdx = candidatsLot.stream()
                    .filter(i -> state.restants[i] > 0)
                    .min(Comparator
                            .comparingInt((Integer i) -> state.backlog.contains(i) ? 0 : 1)
                            .thenComparingInt((Integer i) -> Math.abs(state.restants[i] - capR))
                            .thenComparingInt((Integer i) -> -state.restants[i])
                            .thenComparingInt(i -> i))
                    .orElse(null);

            if (bestIdx == null) break;
            candidatsLot.remove(bestIdx);

            int affectes = Math.min(state.restants[bestIdx], capaciteRestante);
            lot.add(copyReservationWithPassengers(state.reservations.get(bestIdx), affectes));
            state.restants[bestIdx] -= affectes;
            capaciteRestante        -= affectes;
        }

        if (lot.isEmpty()) return false;

        // ── Heure de départ ───────────────────────────────────────────────────
        LocalDateTime dispoVehicule = state.vehiculeDispo.get(selectionne.getId());
        LocalDateTime departEffectif;

        if (departImmédiat) {
            // Règle 2 : le véhicule repart dès son retour, sans attendre
            departEffectif = dispoVehicule;
        } else {
            // Règles 3 & 4 : MAX(dernière arrivée des réservations du lot, dispo véhicule)
            LocalDateTime derniereArrivee = lot.stream()
                    .map(r -> r.getDateHeureArrivee().toLocalDateTime())
                    .max(Comparator.naturalOrder())
                    .orElse(dispoVehicule);
            departEffectif = derniereArrivee.isAfter(dispoVehicule) ? derniereArrivee : dispoVehicule;
        }

        // ── Calcul de la route ────────────────────────────────────────────────
        RouteCalc route       = calculateRoute(lot, state.airportId, state.vitesseKmH, state.hotelCodeMap);
        LocalDateTime arrivee = departEffectif.plusMinutes(route.minsToLastHotel);
        LocalDateTime retour  = departEffectif.plusMinutes(route.totalRouteMinutes);

        // Itinéraire textuel
        List<String[]> itin = new ArrayList<>();
        itin.add(new String[]{state.airportCode, ""});
        for (int s = 0; s < route.orderedHotelIds.size(); s++) {
            String hCode = state.hotelCodeMap.getOrDefault(
                    route.orderedHotelIds.get(s), "H#" + route.orderedHotelIds.get(s));
            itin.add(new String[]{hCode, String.format("%.0f km", route.legKms.get(s))});
        }
        itin.add(new String[]{state.airportCode,
                String.format("%.0f km", route.legKms.get(route.legKms.size() - 1))});

        // ── Mise à jour de l'état ─────────────────────────────────────────────
        // Le véhicule sera de retour à l'aéroport à 'retour' → nouvelle dispo.
        state.vehiculeDispo.put(selectionne.getId(), retour);
        state.nbTrajets.put(selectionne.getId(),
                state.nbTrajets.getOrDefault(selectionne.getId(), 0) + 1);
        state.entries.add(new PlanningEntry(
                selectionne, lot, departEffectif, arrivee, retour, route.totalKm, itin));

        return true;
    }

    // =========================================================================
    //  HELPERS ALGORITHME
    // =========================================================================

    /** Véhicules dont la disponibilité courante ≤ fenetreMax. */
    private List<Voiture> eligiblesDansFenetre(PlanningState state, LocalDateTime fenetreMax) {
        return state.voitures.stream()
                .filter(v -> !state.vehiculeDispo.get(v.getId()).isAfter(fenetreMax))
                .collect(Collectors.toList());
    }

    /**
     * Sélectionne le véhicule avec la plus petite capacité ≥ passagersNecessaires.
     * Départage : moins de trajets > diesel > essence > hybride > id.
     */
    private Voiture selectMeilleurVehicule(List<Voiture> candidats, int passagersNecessaires,
                                           Map<Integer, Integer> nbTrajets) {
        List<Voiture> eligibles = candidats.stream()
                .filter(v -> v.getNbPlace() >= passagersNecessaires)
                .collect(Collectors.toList());
        if (eligibles.isEmpty()) return null;

        int minCap = eligibles.stream().mapToInt(Voiture::getNbPlace).min().getAsInt();
        return eligibles.stream()
                .filter(v -> v.getNbPlace() == minCap)
                .sorted(Comparator
                        .comparingInt((Voiture v) -> nbTrajets.getOrDefault(v.getId(), 0))
                        .thenComparingInt(v -> fuelRank(v.getCarburant()))
                        .thenComparingInt(Voiture::getId))
                .findFirst().orElse(null);
    }

    /**
     * Sélection de secours (split autorisé) : plus grande capacité disponible.
     */
    private Voiture selectVehiculePourSplit(List<Voiture> candidats,
                                            Map<Integer, Integer> nbTrajets) {
        return candidats.stream()
                .filter(v -> v.getNbPlace() > 0)
                .sorted(Comparator
                        .comparingInt(Voiture::getNbPlace).reversed()
                        .thenComparingInt(v -> nbTrajets.getOrDefault(v.getId(), 0))
                        .thenComparingInt(v -> fuelRank(v.getCarburant()))
                        .thenComparingInt(Voiture::getId))
                .findFirst().orElse(null);
    }

    /** Diesel = 0 (prioritaire), Essence = 1, Hybride = 2. */
    private int fuelRank(char carburant) {
        if (carburant == 'd') return 0;
        if (carburant == 'e') return 1;
        return 2;
    }

    // =========================================================================
    //  CALCUL DE LA ROUTE
    // =========================================================================
    /**
     * Trajet aéroport → hôtel1 → hôtel2 → … → aéroport.
     * Hôtels triés par distance croissante depuis l'aéroport,
     * puis alphabétiquement (code) en cas d'égalité.
     */
    private RouteCalc calculateRoute(List<Reservation> lot, int airportId,
                                     double vitesseKmH,
                                     Map<Integer, String> hotelCodeMap) throws SQLException {
        List<Integer> hotelIds = lot.stream()
                .map(Reservation::getIdHotel).distinct().collect(Collectors.toList());

        if (hotelIds.isEmpty())
            return new RouteCalc(0, 0, 0, Collections.emptyList(), Collections.emptyList());

        Map<Integer, Double> distFromAirport = new HashMap<>();
        for (int hId : hotelIds)
            distFromAirport.put(hId, DistanceController.getKmBetween(airportId, hId));

        hotelIds.sort(Comparator
                .comparingDouble((Integer h) -> distFromAirport.get(h))
                .thenComparing(h -> hotelCodeMap.getOrDefault(h, "")));

        double totalKm = 0, minsToLastHotel = 0;
        int prevId = airportId;
        List<Double> legKms = new ArrayList<>();

        for (int hId : hotelIds) {
            double legKm;
            if (prevId == airportId) {
                legKm = distFromAirport.get(hId);
            } else {
                double direct = DistanceController.getKmBetween(prevId, hId);
                legKm = direct > 0 ? direct
                        : Math.abs(distFromAirport.get(hId) - distFromAirport.get(prevId));
            }
            legKms.add(legKm);
            totalKm         += legKm;
            minsToLastHotel += vitesseKmH > 0 ? (legKm / vitesseKmH) * 60 : 0;
            prevId           = hId;
        }

        double returnKm   = distFromAirport.get(hotelIds.get(hotelIds.size() - 1));
        legKms.add(returnKm);
        totalKm          += returnKm;
        double totalMins  = minsToLastHotel + (vitesseKmH > 0 ? (returnKm / vitesseKmH) * 60 : 0);

        return new RouteCalc(totalKm, (long) minsToLastHotel, (long) totalMins, hotelIds, legKms);
    }

    private static class RouteCalc {
        final double totalKm;
        final long   minsToLastHotel, totalRouteMinutes;
        final List<Integer> orderedHotelIds;
        final List<Double>  legKms;

        RouteCalc(double totalKm, long minsToLastHotel, long totalRouteMinutes,
                  List<Integer> orderedHotelIds, List<Double> legKms) {
            this.totalKm           = totalKm;
            this.minsToLastHotel   = minsToLastHotel;
            this.totalRouteMinutes = totalRouteMinutes;
            this.orderedHotelIds   = orderedHotelIds;
            this.legKms            = legKms;
        }
    }

    // =========================================================================
    //  UTILITAIRES
    // =========================================================================
    private Reservation copyReservationWithPassengers(Reservation source, int nbPassagers) {
        Reservation copy = new Reservation();
        copy.setId(source.getId());
        copy.setIdClient(source.getIdClient());
        copy.setIdHotel(source.getIdHotel());
        copy.setNbPassager(nbPassagers);
        copy.setDateHeureArrivee(source.getDateHeureArrivee());
        copy.setIdLieuDestination(source.getIdLieuDestination());
        copy.setLieuCode(source.getLieuCode());
        copy.setHotelName(source.getHotelName());
        copy.setHotelVille(source.getHotelVille());
        copy.setUnassignedReason(source.getUnassignedReason());
        return copy;
    }

    // =========================================================================
    //  PERSISTANCE
    // =========================================================================
    private void persistPlanningForDate(String date, List<PlanningEntry> planning) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                ensurePlanificationTable(conn);

                try (PreparedStatement del = conn.prepareStatement(
                        "DELETE FROM planification WHERE date_planning = ?")) {
                    del.setDate(1, java.sql.Date.valueOf(date));
                    del.executeUpdate();
                }

                String sql = "INSERT INTO planification "
                        + "(reservation_id, voiture_id, date_planning, heure_depart, "
                        + "heure_arrivee_hotel, heure_retour_aeroport, distance_km) "
                        + "VALUES (?, ?, ?, ?, ?, ?, ?)";

                try (PreparedStatement ins = conn.prepareStatement(sql)) {
                    for (PlanningEntry entry : planning) {
                        if (entry.getReservations() == null) continue;
                        for (Reservation r : entry.getReservations()) {
                            if (entry.getDepartureTime() == null
                                    || entry.getArrivalTime() == null
                                    || entry.getReturnToAirportTime() == null) continue;
                            ins.setInt(1, r.getId());
                            ins.setInt(2, entry.getVoiture().getId());
                            ins.setDate(3, java.sql.Date.valueOf(date));
                            ins.setTimestamp(4, Timestamp.valueOf(entry.getDepartureTime()));
                            ins.setTimestamp(5, Timestamp.valueOf(entry.getArrivalTime()));
                            ins.setTimestamp(6, Timestamp.valueOf(entry.getReturnToAirportTime()));
                            ins.setDouble(7, entry.getTotalKm());
                            ins.addBatch();
                        }
                    }
                    ins.executeBatch();
                }

                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private void ensurePlanificationTable(Connection conn) throws SQLException {
        String ddl = "CREATE TABLE IF NOT EXISTS planification ("
                + "id SERIAL PRIMARY KEY,"
                + "reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE,"
                + "voiture_id INTEGER NOT NULL REFERENCES voiture(id) ON DELETE CASCADE,"
                + "date_planning DATE NOT NULL,"
                + "heure_depart TIMESTAMP NOT NULL,"
                + "heure_arrivee_hotel TIMESTAMP NOT NULL,"
                + "heure_retour_aeroport TIMESTAMP NOT NULL,"
                + "distance_km DOUBLE PRECISION NOT NULL DEFAULT 0,"
                + "created_at TIMESTAMP NOT NULL DEFAULT NOW()"
                + ")";
        try (PreparedStatement ps = conn.prepareStatement(ddl)) { ps.execute(); }
    }

    // =========================================================================
    //  ACCÈS BASE DE DONNÉES
    // =========================================================================
    private List<Reservation> getReservationsForDate(String date) throws SQLException {
        List<Reservation> list = new ArrayList<>();
        String sql = "SELECT r.id, r.id_client, r.id_hotel, r.nb_passager, "
                + "r.date_heure_arrivee, h.code AS lieu_code "
                + "FROM reservation r "
                + "JOIN hotel h ON h.id = r.id_hotel "
                + "WHERE DATE(r.date_heure_arrivee) = ? "
                + "ORDER BY r.date_heure_arrivee";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Reservation r = new Reservation();
                    r.setId(rs.getInt("id"));
                    r.setIdClient(rs.getString("id_client"));
                    r.setIdHotel(rs.getInt("id_hotel"));
                    r.setNbPassager(rs.getInt("nb_passager"));
                    r.setDateHeureArrivee(rs.getTimestamp("date_heure_arrivee"));
                    r.setLieuCode(rs.getString("lieu_code"));
                    list.add(r);
                }
            }
        }
        return list;
    }

    private List<Voiture> getAllVoitures() throws SQLException {
        List<Voiture> list = new ArrayList<>();
        String sql = "SELECT id, marque, nb_place, type, carburant, matricule "
                + "FROM voiture ORDER BY nb_place";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(new Voiture(rs.getInt("id"), rs.getString("marque"),
                        rs.getInt("nb_place"), rs.getString("type"),
                        rs.getString("carburant").charAt(0), rs.getString("matricule")));
        }
        return list;
    }

    private int getAirportId() throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id FROM hotel WHERE is_airport = TRUE LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id");
        }
        return 0;
    }

    private Map<Integer, String> getHotelCodeMap() throws SQLException {
        Map<Integer, String> map = new HashMap<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, code FROM hotel WHERE code IS NOT NULL");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt("id"), rs.getString("code"));
        }
        return map;
    }

    private Map<Integer, LocalDateTime> getVoitureDisponibiliteInitiale(LocalDate date) throws SQLException {
        Map<Integer, LocalDateTime> map = new HashMap<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT id, heure_disponible FROM voiture");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Time t = rs.getTime("heure_disponible");
                LocalTime heure = (t != null) ? t.toLocalTime() : LocalTime.MIDNIGHT;
                map.put(rs.getInt("id"), date.atTime(heure));
            }
        }
        return map;
    }
}