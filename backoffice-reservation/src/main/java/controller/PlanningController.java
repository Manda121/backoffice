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

    // ========================
    //  FORM : saisie de la date
    // ========================
    @MyURL(value = "/planning/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("planning.jsp");
        return mv;
    }

    // ========================
    //  RESULT : calcul du planning
    // ========================
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
            // --- Paramètres configurables ---
            int tempsAttenteMin = ParametreController.getParamInt("temps_attente", 30);
            double vitesseKmH   = ParametreController.getParamDouble("vitesse_moyenne", 30.0);

            // --- Aéroport (lieu de départ) ---
            int airportId = getAirportId();

            // --- Réservations pour la date (triées par heure) ---
            List<Reservation> reservations = getReservationsForDate(date);
            reservations.sort(Comparator.comparing(Reservation::getDateHeureArrivee));

            // --- Véhicules disponibles ---
            List<Voiture> voitures = getAllVoitures();

            if (voitures.isEmpty()) {
                mv.addItem("error", "Aucun véhicule enregistré dans le système.");
                return mv;
            }

            // --- Algorithme d'assignation ---
            List<Reservation> unassigned = new ArrayList<>();
                LocalDate planningDate = LocalDate.parse(date);
            List<PlanningEntry> planning = assignReservations(
                    reservations, voitures, vitesseKmH, airportId, planningDate, unassigned);

                // --- Persistance : replanification complète pour la date ---
                persistPlanningForDate(date, planning);

            mv.addItem("planning", planning);
            mv.addItem("unassigned", unassigned);
            mv.addItem("totalReservations", reservations.size());
            mv.addItem("tempsAttente", tempsAttenteMin);
            mv.addItem("vitesse", vitesseKmH);

        } catch (Exception e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors du calcul du planning : " + e.getMessage());
        }

        return mv;
    }

    // ========================
    //  ALGORITHME D'ASSIGNATION
    // ========================
    /**
     * Assigne les réservations aux véhicules selon les règles du cahier des charges :
     *  - Règle 1 : capacité minimale pour transporter les passagers
     *  - Règle 2 : la capacité la plus proche du nombre de passagers
     *  - Règle 3 : priorité au carburant Diesel à capacité égale
     *  - Règle 4 : choix aléatoire à capacité et carburant égaux
     *
     * Le temps d'attente (en minutes) regroupe les réservations dans une fenêtre glissante :
     *  - L'heure initiale du groupe = heure d'arrivée de la 1ère réservation non assignée.
     *  - Toutes les réservations dont l'heure ≤ heureInitiale + tempsAttente sont candidates.
     *  - L'heure de départ réelle = heure d'arrivée de la dernière réservation du groupe
     *    (pas nécessairement heureInitiale + tempsAttente).
     *  - Les véhicules disponibles sont ceux libres à heureInitiale.
     *  - Après chaque groupe, la prochaine heureInitiale = heure de la 1ère réservation restante.
     */
    private List<PlanningEntry> assignReservations(
            List<Reservation> reservations,
            List<Voiture> voitures,
            double vitesseKmH,
            int airportId,
            LocalDate planningDate,
            List<Reservation> unassigned) throws SQLException {
        // NOTE: tempsAttenteMin is fetched in computePlanning and passed indirectly;
        //       we re-fetch it here so this method remains self-contained.
        int tempsAttenteMin = ParametreController.getParamInt("temps_attente", 30);

        List<PlanningEntry> entries = new ArrayList<>();
        int[] remainingPassengers = new int[reservations.size()];
        for (int i = 0; i < reservations.size(); i++) {
            remainingPassengers[i] = Math.max(0, reservations.get(i).getNbPassager());
        }
        Map<Integer, String> hotelCodeMap = getHotelCodeMap();
        String airportCode = hotelCodeMap.getOrDefault(airportId, "IVATO");
        Map<Integer, LocalDateTime> disponibiliteInitiale = getVoitureDisponibiliteInitiale(planningDate);

        // Heure à laquelle chaque véhicule sera de retour à l'aéroport
        Map<Integer, LocalDateTime> disponibleA = new HashMap<>();
        // Nombre de trajets déjà effectués dans cette exécution de planification
        Map<Integer, Integer> nbTrajets = new HashMap<>();
        for (Voiture v : voitures) {
            LocalDateTime dispoInitiale = disponibiliteInitiale.get(v.getId());
            disponibleA.put(v.getId(), dispoInitiale != null ? dispoInitiale : LocalDateTime.MIN);
            nbTrajets.put(v.getId(), 0);
        }

        // Report intelligent: une réservation non assignée (véhicules en trajet)
        // ne peut être rejouée que dans une tranche ultérieure hors fenêtre initiale.
        Map<Integer, LocalDateTime> reportEligibleAfter = new HashMap<>();

        // Boucle principale : on traite les réservations groupe par groupe
        while (true) {
            // Trouver la prochaine réservation "active" (non assignée et non bloquée par report)
            Integer anchorIdx = null;
            LocalDateTime anchorTime = null;
            for (int idx = 0; idx < reservations.size(); idx++) {
                if (remainingPassengers[idx] <= 0) continue;
                Reservation r = reservations.get(idx);
                LocalDateTime t = r.getDateHeureArrivee().toLocalDateTime();
                LocalDateTime deferAfter = reportEligibleAfter.get(r.getId());

                // Une réservation reportée ne doit pas redevenir ancre via son ancienne heure.
                // Elle sera réintégrée quand une nouvelle ancre (nouvelle réservation) ouvrira
                // une tranche avec heureInitiale > deferAfter.
                boolean isActiveAnchor = (deferAfter == null);
                if (!isActiveAnchor) continue;

                if (anchorTime == null || t.isBefore(anchorTime)) {
                    anchorTime = t;
                    anchorIdx = idx;
                }
            }

            if (anchorIdx == null) break;

            // --- Heure initiale du groupe = heure d'arrivée de l'ancre active ---
            LocalDateTime heureInitiale = reservations.get(anchorIdx).getDateHeureArrivee().toLocalDateTime();
            LocalDateTime fenetreMax    = heureInitiale.plusMinutes(tempsAttenteMin);

            // --- Collecter TOUS les indices non assignés dont l'heure ≤ heureInitiale + tempsAttente ---
            List<Integer> groupeIdx = new ArrayList<>();
            for (int j = 0; j < reservations.size(); j++) {
                if (remainingPassengers[j] > 0) {
                    LocalDateTime t = reservations.get(j).getDateHeureArrivee().toLocalDateTime();
                    LocalDateTime deferAfter = reportEligibleAfter.get(reservations.get(j).getId());
                    boolean deferOk = (deferAfter == null) || heureInitiale.isAfter(deferAfter);
                    if (!t.isAfter(fenetreMax) && deferOk) {
                        groupeIdx.add(j);
                    }
                }
            }

            if (groupeIdx.isEmpty()) {
                continue;
            }

            // Priorité de traitement: passagers décroissants
            groupeIdx.sort(
                    Comparator.comparingInt((Integer idx) -> reservations.get(idx).getNbPassager())
                              .reversed()
                              .thenComparing(idx -> reservations.get(idx).getDateHeureArrivee().toLocalDateTime())
            );

            // --- Heure de départ réelle = heure d'arrivée de la DERNIÈRE réservation du groupe ---
            LocalDateTime depart = groupeIdx.stream()
                    .map(idx -> reservations.get(idx).getDateHeureArrivee().toLocalDateTime())
                    .max(Comparator.naturalOrder())
                    .orElse(heureInitiale);

                // --- Véhicules disponibles ---
                // Règle: pour le 1er trajet de la journée, une voiture doit être
                // disponible dès l'heure initiale de la tranche.
                // Ensuite, elle peut être réutilisée si elle revient avant la fin de tranche.
                final LocalDateTime hMax = fenetreMax;
                final LocalDateTime hInit = heureInitiale;
            List<Voiture> disponibles = voitures.stream()
                    .filter(v -> {
                        LocalDateTime dispo = disponibleA.get(v.getId());
                        int trajets = nbTrajets.getOrDefault(v.getId(), 0);
                        if (trajets == 0) {
                            return !dispo.isAfter(hInit);
                        }
                        return !dispo.isAfter(hMax);
                    })
                    .collect(Collectors.toList());

            // --- Distribuer les réservations du groupe en lots (un véhicule par lot) ---
            while (true) {
                List<Integer> indicesActifs = groupeIdx.stream()
                        .filter(idx -> remainingPassengers[idx] > 0)
                        .sorted(Comparator
                                .comparingInt((Integer idx) -> remainingPassengers[idx])
                                .reversed()
                                .thenComparing(idx -> reservations.get(idx).getDateHeureArrivee().toLocalDateTime()))
                        .collect(Collectors.toList());

                if (indicesActifs.isEmpty()) break;

                int firstIdx = indicesActifs.get(0);
                Reservation premiere = reservations.get(firstIdx);

                int totalPassagersRestants = indicesActifs.stream()
                        .mapToInt(idx -> remainingPassengers[idx])
                        .sum();

                // Essayer de trouver un véhicule qui prend tout le monde restant du groupe
                Voiture selectionne = selectMeilleurVehicule(disponibles, totalPassagersRestants, nbTrajets);

                // Sinon, prendre un véhicule qui prend au moins le plus gros reliquat
                if (selectionne == null) {
                    selectionne = selectMeilleurVehicule(disponibles, remainingPassengers[firstIdx], nbTrajets);
                }

                // Si toujours null, autoriser le split sur le meilleur véhicule disponible
                if (selectionne == null) {
                    selectionne = selectVehiculePourSplit(disponibles, nbTrajets);
                }

                // Si toujours null : aucun véhicule disponible dans la tranche
                if (selectionne == null) {
                    boolean capaciteInsuffisante = voitures.stream().noneMatch(v -> v.getNbPlace() > 0);
                    boolean blockedByStartAvailability = isBlockedByStartAvailability(
                        voitures, disponibleA, nbTrajets, heureInitiale);

                    if (capaciteInsuffisante) {
                        Reservation reliquat = copyReservationWithPassengers(premiere, remainingPassengers[firstIdx]);
                        String reason = "Capacité insuffisante (" + remainingPassengers[firstIdx]
                                + " passager(s) restant(s), max disponible : "
                                + voitures.stream().mapToInt(Voiture::getNbPlace).max().orElse(0) + " places)";
                        reliquat.setUnassignedReason(reason);
                        unassigned.add(reliquat);
                        remainingPassengers[firstIdx] = 0;
                    } else if (blockedByStartAvailability) {
                    Reservation reliquat = copyReservationWithPassengers(premiere, remainingPassengers[firstIdx]);
                    LocalDateTime firstDispo = getEarliestVoitureDispo(voitures, disponibleA);
                    String firstDispoStr = firstDispo != null
                        ? String.format("%02dh%02d", firstDispo.getHour(), firstDispo.getMinute())
                        : "inconnue";
                    reliquat.setUnassignedReason(
                        "Aucun véhicule disponible à l'heure d'arrivée (1ère disponibilité: " + firstDispoStr + ")");
                    unassigned.add(reliquat);
                    remainingPassengers[firstIdx] = 0;
                    } else {
                        // Report intelligent : rejouer seulement dans une tranche ultérieure
                        // dont l'heure initiale dépasse la fin de la fenêtre actuelle.
                        reportEligibleAfter.put(premiere.getId(), fenetreMax);
                    }
                    break;
                }

                // --- Constituer le lot final (greedy, avec possibilité de split d'une réservation) ---
                List<Reservation> lot = new ArrayList<>();
                int capaciteRestante = selectionne.getNbPlace();

                // 1) Toujours commencer par la réservation ayant le plus grand reliquat
                int restantPremier = remainingPassengers[firstIdx];
                if (restantPremier > 0 && capaciteRestante > 0) {
                    int affectes = Math.min(restantPremier, capaciteRestante);
                    Reservation part = copyReservationWithPassengers(reservations.get(firstIdx), affectes);
                    lot.add(part);
                    remainingPassengers[firstIdx] -= affectes;
                    capaciteRestante -= affectes;
                }

                // 2) Ensuite, choisir la réservation dont l'écart avec la capacité restante est le plus proche
                while (capaciteRestante > 0) {
                    Integer bestIdx = pickBestGapReservationIndex(indicesActifs, remainingPassengers, capacitiesafe(capaciteRestante));
                    if (bestIdx == null) break;

                    int restant = remainingPassengers[bestIdx];
                    if (restant <= 0) break;

                    int affectes = Math.min(restant, capaciteRestante);
                    Reservation part = copyReservationWithPassengers(reservations.get(bestIdx), affectes);
                    lot.add(part);

                    remainingPassengers[bestIdx] -= affectes;
                    capaciteRestante -= affectes;
                }

                if (lot.isEmpty()) {
                    break;
                }

                // Retirer le véhicule sélectionné des disponibles pour ce groupe
                final int selectedId = selectionne.getId();
                disponibles = disponibles.stream()
                        .filter(v -> v.getId() != selectedId)
                        .collect(Collectors.toList());

                // --- Calculer les horaires, distance et itinéraire ---
                // Ajustement: si la voiture revient pendant la tranche, le départ se fait à son retour.
                LocalDateTime departEffectif = depart;
                LocalDateTime retourDisponible = disponibleA.get(selectionne.getId());
                if (retourDisponible != null && retourDisponible.isAfter(departEffectif) && !retourDisponible.isAfter(fenetreMax)) {
                    departEffectif = retourDisponible;
                }

                RouteCalc route = calculateRoute(lot, airportId, vitesseKmH, hotelCodeMap);
                LocalDateTime arrivee        = departEffectif.plusMinutes(route.minsToLastHotel);
                LocalDateTime retourAeroport = departEffectif.plusMinutes(route.totalRouteMinutes);

                // Construire les étapes d'itinéraire
                List<String[]> itin = new ArrayList<>();
                itin.add(new String[]{airportCode, ""});
                for (int s = 0; s < route.orderedHotelIds.size(); s++) {
                    String hCode = hotelCodeMap.getOrDefault(route.orderedHotelIds.get(s),
                            "H#" + route.orderedHotelIds.get(s));
                    itin.add(new String[]{hCode, String.format("%.0f km", route.legKms.get(s))});
                }
                itin.add(new String[]{airportCode,
                        String.format("%.0f km", route.legKms.get(route.legKms.size() - 1))});

                disponibleA.put(selectionne.getId(), retourAeroport);
                nbTrajets.put(selectionne.getId(), nbTrajets.getOrDefault(selectionne.getId(), 0) + 1);
                entries.add(new PlanningEntry(selectionne, lot, departEffectif, arrivee, retourAeroport, route.totalKm, itin));
            }
        }

        // Finaliser les réservations restantes non assignées (ex: report sans tranche ultérieure)
        for (int idx = 0; idx < reservations.size(); idx++) {
            if (remainingPassengers[idx] > 0) {
                Reservation r = reservations.get(idx);
                Reservation reliquat = copyReservationWithPassengers(r, remainingPassengers[idx]);
                if (r.getUnassignedReason() == null || r.getUnassignedReason().trim().isEmpty()) {
                    LocalDateTime t = r.getDateHeureArrivee().toLocalDateTime();
                    String timeStr = String.format("%02dh%02d", t.getHour(), t.getMinute());
                    reliquat.setUnassignedReason("Aucun véhicule compatible disponible après report (arrivée " + timeStr + ")");
                } else {
                    reliquat.setUnassignedReason(r.getUnassignedReason());
                }
                unassigned.add(reliquat);
                remainingPassengers[idx] = 0;
            }
        }

        return entries;
    }

    /**
     * Calcule le trajet complet pour un lot de réservations.
     * Hôtels triés par distance croissante depuis l'aéroport, puis alphabétiquement (code)
     * en cas d'égalité de distance.
     */
    private RouteCalc calculateRoute(List<Reservation> lot, int airportId, double vitesseKmH,
                                     Map<Integer, String> hotelCodeMap) throws SQLException {
        List<Integer> hotelIds = lot.stream()
                .map(Reservation::getIdHotel)
                .distinct()
                .collect(Collectors.toList());

        if (hotelIds.isEmpty())
            return new RouteCalc(0, 0, 0, Collections.emptyList(), Collections.emptyList());

        Map<Integer, Double> distFromAirport = new HashMap<>();
        for (int hId : hotelIds)
            distFromAirport.put(hId, DistanceController.getKmBetween(airportId, hId));

        // Tri : distance depuis l'aéroport croissante, puis code alphabétique en cas d'égalité
        hotelIds.sort(Comparator
                .comparingDouble((Integer h) -> distFromAirport.get(h))
                .thenComparing(h -> hotelCodeMap.getOrDefault(h, "")));

        double totalKm = 0;
        double minutesToLastHotel = 0;
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
            totalKm += legKm;
            minutesToLastHotel += vitesseKmH > 0 ? (legKm / vitesseKmH) * 60 : 0;
            prevId = hId;
        }

        double returnKm = distFromAirport.get(hotelIds.get(hotelIds.size() - 1));
        legKms.add(returnKm);
        totalKm += returnKm;
        double totalMinutes = minutesToLastHotel
                + (vitesseKmH > 0 ? (returnKm / vitesseKmH) * 60 : 0);

        return new RouteCalc(totalKm, (long) minutesToLastHotel, (long) totalMinutes, hotelIds, legKms);
    }

    /** Résultat du calcul de trajet. */
    private static class RouteCalc {
        final double totalKm;
        final long minsToLastHotel;
        final long totalRouteMinutes;
        final List<Integer> orderedHotelIds;
        final List<Double>  legKms; // taille = hotels + 1 (dernier = retour aéroport)

        RouteCalc(double totalKm, long minsToLastHotel, long totalRouteMinutes,
                  List<Integer> orderedHotelIds, List<Double> legKms) {
            this.totalKm          = totalKm;
            this.minsToLastHotel  = minsToLastHotel;
            this.totalRouteMinutes = totalRouteMinutes;
            this.orderedHotelIds  = orderedHotelIds;
            this.legKms           = legKms;
        }
    }

    /** Retourne un map id → code pour tous les hôtels. */
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

    /**
     * Sélectionne le meilleur véhicule selon les règles :
     *  1) capacité minimale suffisante
     *  2) moins de trajets déjà effectués
     *  3) priorité carburant (diesel, puis essence, puis hybride)
     */
    private Voiture selectMeilleurVehicule(List<Voiture> candidats, int passagersNecessaires,
                                           Map<Integer, Integer> nbTrajets) {
        // Règle 1 : capacité >= passagers nécessaires
        List<Voiture> eligibles = candidats.stream()
                .filter(v -> v.getNbPlace() >= passagersNecessaires)
                .collect(Collectors.toList());

        if (eligibles.isEmpty()) return null;

        // Règle 2 : capacité la plus proche (la plus petite suffisante)
        int minCapacite = eligibles.stream().mapToInt(Voiture::getNbPlace).min().getAsInt();
        List<Voiture> optimaux = eligibles.stream()
                .filter(v -> v.getNbPlace() == minCapacite)
                .collect(Collectors.toList());

        // Règle 2 puis 3 : moins de trajets, puis priorité carburant
        optimaux.sort(Comparator
            .comparingInt((Voiture v) -> nbTrajets.getOrDefault(v.getId(), 0))
            .thenComparingInt(v -> fuelRank(v.getCarburant()))
            .thenComparingInt(Voiture::getId));

        return optimaux.get(0);
        }

    /**
     * Sélection de secours pour autoriser le découpage d'une réservation :
     * on prend le véhicule avec la plus grande capacité, puis moins de trajets,
     * puis priorité carburant.
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
                .findFirst()
                .orElse(null);
    }

    /** Copie d'une réservation avec un nombre de passagers spécifique (pour split). */
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

    /**
     * Choisit l'index de réservation dont le reliquat est le plus proche
     * de la capacité restante. En cas d'égalité, on priorise le plus grand reliquat,
     * puis l'heure d'arrivée la plus tôt.
     */
    private Integer pickBestGapReservationIndex(List<Integer> candidateIndices,
                                                int[] remainingPassengers,
                                                int capaciteRestante) {
        return candidateIndices.stream()
                .filter(idx -> remainingPassengers[idx] > 0)
                .min(Comparator
                        .comparingInt((Integer idx) -> Math.abs(remainingPassengers[idx] - capaciteRestante))
                        .thenComparing((Integer idx) -> remainingPassengers[idx], Comparator.reverseOrder())
                        .thenComparing(idx -> idx))
                .orElse(null);
    }

    private int capacitiesafe(int capaciteRestante) {
        return Math.max(0, capaciteRestante);
    }

    /**
     * Cas strict: aucun véhicule n'a encore démarré sa journée et
     * toutes les disponibilités initiales sont après l'heure de la tranche.
     * Dans ce cas, on n'autorise pas le report d'une réservation plus tôt.
     */
    private boolean isBlockedByStartAvailability(List<Voiture> voitures,
                                                 Map<Integer, LocalDateTime> disponibleA,
                                                 Map<Integer, Integer> nbTrajets,
                                                 LocalDateTime heureInitiale) {
        boolean hasFutureStart = false;
        boolean hasStartedOrAlreadyAvailable = false;

        for (Voiture v : voitures) {
            if (v.getNbPlace() <= 0) continue;

            int trajets = nbTrajets.getOrDefault(v.getId(), 0);
            LocalDateTime dispo = disponibleA.get(v.getId());
            if (dispo == null) continue;

            if (trajets > 0 || !dispo.isAfter(heureInitiale)) {
                hasStartedOrAlreadyAvailable = true;
                break;
            }
            hasFutureStart = true;
        }

        return hasFutureStart && !hasStartedOrAlreadyAvailable;
    }

    private LocalDateTime getEarliestVoitureDispo(List<Voiture> voitures,
                                                  Map<Integer, LocalDateTime> disponibleA) {
        return voitures.stream()
                .map(v -> disponibleA.get(v.getId()))
                .filter(Objects::nonNull)
                .min(LocalDateTime::compareTo)
                .orElse(null);
    }

        private int fuelRank(char carburant) {
        if (carburant == 'd') return 0;
        if (carburant == 'e') return 1;
        return 2;
    }

    // ========================
    //  HELPERS DB
    // ========================
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

                String insertSql = "INSERT INTO planification " +
                        "(reservation_id, voiture_id, date_planning, heure_depart, heure_arrivee_hotel, heure_retour_aeroport, distance_km) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?)";

                try (PreparedStatement ins = conn.prepareStatement(insertSql)) {
                    for (PlanningEntry entry : planning) {
                        if (entry.getReservations() == null) continue;
                        for (Reservation r : entry.getReservations()) {
                            if (entry.getDepartureTime() == null || entry.getArrivalTime() == null || entry.getReturnToAirportTime() == null) {
                                continue;
                            }
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
        String ddl = "CREATE TABLE IF NOT EXISTS planification (" +
                "id SERIAL PRIMARY KEY," +
                "reservation_id INTEGER NOT NULL REFERENCES reservation(id) ON DELETE CASCADE," +
                "voiture_id INTEGER NOT NULL REFERENCES voiture(id) ON DELETE CASCADE," +
                "date_planning DATE NOT NULL," +
                "heure_depart TIMESTAMP NOT NULL," +
                "heure_arrivee_hotel TIMESTAMP NOT NULL," +
                "heure_retour_aeroport TIMESTAMP NOT NULL," +
                "distance_km DOUBLE PRECISION NOT NULL DEFAULT 0," +
                "created_at TIMESTAMP NOT NULL DEFAULT NOW()" +
                ")";
        try (PreparedStatement ps = conn.prepareStatement(ddl)) {
            ps.execute();
        }
    }

    private List<Reservation> getReservationsForDate(String date) throws SQLException {
        List<Reservation> list = new ArrayList<>();
        String sql = "SELECT r.id, r.id_client, r.id_hotel, r.nb_passager, r.date_heure_arrivee, " +
                        "h.code AS lieu_code " +
                        "FROM reservation r " +
                        "JOIN hotel h ON h.id = r.id_hotel " +
                        "WHERE DATE(r.date_heure_arrivee) = ? " +
                        "ORDER BY r.date_heure_arrivee, r.nb_passager DESC";
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
        String sql = "SELECT id, marque, nb_place, type, carburant, matricule FROM voiture ORDER BY nb_place";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Voiture(rs.getInt("id"), rs.getString("marque"),
                        rs.getInt("nb_place"), rs.getString("type"),
                        rs.getString("carburant").charAt(0), rs.getString("matricule")));
            }
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

    private Map<Integer, LocalDateTime> getVoitureDisponibiliteInitiale(LocalDate planningDate) throws SQLException {
        Map<Integer, LocalDateTime> map = new HashMap<>();
        String sql = "SELECT id, heure_disponible FROM voiture";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Time t = rs.getTime("heure_disponible");
                LocalTime heure = (t != null) ? t.toLocalTime() : LocalTime.MIDNIGHT;
                map.put(rs.getInt("id"), planningDate.atTime(heure));
            }
        }
        return map;
    }
}
