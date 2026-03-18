package controller;

import java.sql.*;
import java.time.LocalDateTime;
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
            List<PlanningEntry> planning = assignReservations(
                    reservations, voitures, vitesseKmH, airportId, unassigned);

                // --- Replanification complète persistée en base ---
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
            List<Reservation> unassigned) throws SQLException {
        // NOTE: tempsAttenteMin is fetched in computePlanning and passed indirectly;
        //       we re-fetch it here so this method remains self-contained.
        int tempsAttenteMin = ParametreController.getParamInt("temps_attente", 30);

        List<PlanningEntry> entries = new ArrayList<>();
        boolean[] assigned = new boolean[reservations.size()];
        Map<Integer, String> hotelCodeMap = getHotelCodeMap();
        String airportCode = hotelCodeMap.getOrDefault(airportId, "IVATO");

        // Heure à laquelle chaque véhicule sera de retour à l'aéroport
        Map<Integer, LocalDateTime> disponibleA = new HashMap<>();
        // Nombre de trajets effectués dans la planification en cours
        Map<Integer, Integer> nbTrajets = new HashMap<>();
        for (Voiture v : voitures) {
            disponibleA.put(v.getId(), LocalDateTime.MIN);
            nbTrajets.put(v.getId(), 0);
        }

        // Réservations reportées intelligemment : réactivables quand heureInitiale > fin de tranche initiale
        Map<Integer, LocalDateTime> reportEligibleAfter = new HashMap<>();

        // Boucle principale : on traite les réservations groupe par groupe
        int i = 0;
        while (i < reservations.size()) {
            // Trouver la prochaine réservation non assignée
            while (i < reservations.size() && assigned[i]) i++;
            if (i >= reservations.size()) break;

            // --- Heure initiale du groupe = heure d'arrivée de la 1ère réservation non assignée ---
            LocalDateTime heureInitiale = reservations.get(i).getDateHeureArrivee().toLocalDateTime();
            LocalDateTime fenetreMax    = heureInitiale.plusMinutes(tempsAttenteMin);

            // --- Collecter TOUS les indices non assignés dont l'heure ≤ heureInitiale + tempsAttente ---
            List<Integer> groupeIdx = new ArrayList<>();
            for (int j = i; j < reservations.size(); j++) {
                if (!assigned[j]) {
                    LocalDateTime t = reservations.get(j).getDateHeureArrivee().toLocalDateTime();
                    LocalDateTime deferAfter = reportEligibleAfter.get(reservations.get(j).getId());
                    boolean deferOk = (deferAfter == null) || heureInitiale.isAfter(deferAfter);
                    if (!t.isAfter(fenetreMax) && deferOk) {
                        groupeIdx.add(j);
                    }
                }
            }

            // Aucun candidat actif pour cette heure initiale (cas de report) : avancer.
            if (groupeIdx.isEmpty()) {
                i++;
                continue;
            }

            // Nouvelle règle : traiter les réservations à plus grand nombre de passagers en premier
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

            // --- Distribuer les réservations du groupe en lots (un véhicule par lot) ---
            boolean[] groupeAssigned = new boolean[groupeIdx.size()];

            for (int gi = 0; gi < groupeIdx.size(); gi++) {
                if (groupeAssigned[gi]) continue;

                int firstIdx = groupeIdx.get(gi);
                Reservation premiere = reservations.get(firstIdx);

                // Calculer le total passagers pour les réservations restantes du groupe
                List<Integer> candidatsGi = new ArrayList<>();
                for (int gj = gi + 1; gj < groupeIdx.size(); gj++) {
                    if (!groupeAssigned[gj]) candidatsGi.add(gj);
                }

                int totalPassagers = premiere.getNbPassager()
                        + candidatsGi.stream()
                              .mapToInt(gj -> reservations.get(groupeIdx.get(gj)).getNbPassager())
                              .sum();

                // Essayer de trouver un véhicule optimal dans la tranche
                VehicleChoice choix = chooseVehicleForWindow(
                        voitures,
                        disponibleA,
                        nbTrajets,
                        totalPassagers,
                        depart,
                        fenetreMax
                );

                // Si impossible avec tous, prendre au moins la première réservation
                if (choix == null) {
                    choix = chooseVehicleForWindow(
                            voitures,
                            disponibleA,
                            nbTrajets,
                            premiere.getNbPassager(),
                            depart,
                            fenetreMax
                    );
                }

                // Si toujours null : soit capacité insuffisante, soit véhicules en trajet hors tranche
                if (choix == null) {
                    boolean capaciteInsuffisante = voitures.stream()
                            .noneMatch(v -> v.getNbPlace() >= premiere.getNbPassager());

                    if (capaciteInsuffisante) {
                        String reason = "Capacité insuffisante (" + premiere.getNbPassager()
                                + " passager(s) requis, max disponible : "
                                + voitures.stream().mapToInt(Voiture::getNbPlace).max().orElse(0) + " places)";
                        premiere.setUnassignedReason(reason);
                        unassigned.add(premiere);
                        groupeAssigned[gi] = true;
                        assigned[firstIdx] = true;
                    } else {
                        // Report intelligent: reconsidérer cette réservation dans une tranche ultérieure
                        reportEligibleAfter.put(premiere.getId(), fenetreMax);
                    }
                    continue;
                }

                Voiture selectionne = choix.voiture;
                LocalDateTime departEffectif = choix.departure;

                // --- Constituer le lot final (greedy selon la capacité du véhicule choisi) ---
                List<Reservation> lot = new ArrayList<>();
                lot.add(premiere);
                groupeAssigned[gi] = true;
                assigned[firstIdx] = true;
                int passagersLot = premiere.getNbPassager();

                for (int gj : candidatsGi) {
                    int nb = reservations.get(groupeIdx.get(gj)).getNbPassager();
                    if (passagersLot + nb <= selectionne.getNbPlace()) {
                        lot.add(reservations.get(groupeIdx.get(gj)));
                        groupeAssigned[gj] = true;
                        assigned[groupeIdx.get(gj)] = true;
                        passagersLot += nb;
                    }
                }

                // --- Calculer les horaires, distance et itinéraire ---
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

            // Avancer i au-delà du groupe courant
            i = groupeIdx.get(groupeIdx.size() - 1) + 1;
        }

        // Finalisation: toute réservation non assignée restante devient non assignée définitive
        for (int idx = 0; idx < reservations.size(); idx++) {
            if (!assigned[idx]) {
                Reservation r = reservations.get(idx);
                if (r.getUnassignedReason() == null || r.getUnassignedReason().trim().isEmpty()) {
                    LocalDateTime t = r.getDateHeureArrivee().toLocalDateTime();
                    String timeStr = String.format("%02dh%02d", t.getHour(), t.getMinute());
                    r.setUnassignedReason("Aucun véhicule compatible disponible après report (arrivée " + timeStr + ")");
                }
                unassigned.add(r);
                assigned[idx] = true;
            }
        }

        return entries;
    }

    private static class VehicleChoice {
        final Voiture voiture;
        final LocalDateTime departure;

        VehicleChoice(Voiture voiture, LocalDateTime departure) {
            this.voiture = voiture;
            this.departure = departure;
        }
    }

    /**
     * Sélectionne le véhicule optimal sur une tranche donnée.
     * Priorités: capacité -> nombre de trajets -> carburant.
     * Le véhicule peut être choisi s'il revient avant la fin de tranche.
     */
    private VehicleChoice chooseVehicleForWindow(
            List<Voiture> voitures,
            Map<Integer, LocalDateTime> disponibleA,
            Map<Integer, Integer> nbTrajets,
            int passagersNecessaires,
            LocalDateTime departBase,
            LocalDateTime fenetreMax) {

        List<Voiture> eligibles = voitures.stream()
                .filter(v -> v.getNbPlace() >= passagersNecessaires)
                .filter(v -> {
                    LocalDateTime dispo = disponibleA.getOrDefault(v.getId(), LocalDateTime.MIN);
                    return !dispo.isAfter(fenetreMax);
                })
                .collect(Collectors.toList());

        if (eligibles.isEmpty()) return null;

        eligibles.sort(
                Comparator.comparingInt(Voiture::getNbPlace)
                        .thenComparingInt(v -> nbTrajets.getOrDefault(v.getId(), 0))
                        .thenComparingInt(v -> fuelPriority(v.getCarburant()))
                        .thenComparingInt(Voiture::getId)
        );

        Voiture selected = eligibles.get(0);
        LocalDateTime dispo = disponibleA.getOrDefault(selected.getId(), LocalDateTime.MIN);
        LocalDateTime departEffectif = dispo.isAfter(departBase) ? dispo : departBase;

        return new VehicleChoice(selected, departEffectif);
    }

    private int fuelPriority(char fuel) {
        if (fuel == 'd') return 0;
        if (fuel == 'e') return 1;
        return 2;
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

    // ========================
    //  HELPERS DB
    // ========================
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
}
