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
            List<PlanningEntry> planning = assignReservations(
                    reservations, voitures, tempsAttenteMin, vitesseKmH, airportId);

            mv.addItem("planning", planning);
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
     * Le temps d'attente permet de regrouper les réservations proches dans un même véhicule.
     */
    private List<PlanningEntry> assignReservations(
            List<Reservation> reservations,
            List<Voiture> voitures,
            int tempsAttenteMin,
            double vitesseKmH,
            int airportId) throws SQLException {

        List<PlanningEntry> entries = new ArrayList<>();
        boolean[] assigned = new boolean[reservations.size()];

        // Heure à laquelle chaque véhicule sera de retour à l'aéroport
        Map<Integer, LocalDateTime> disponibleA = new HashMap<>();
        for (Voiture v : voitures) {
            disponibleA.put(v.getId(), LocalDateTime.MIN);
        }

        for (int i = 0; i < reservations.size(); i++) {
            if (assigned[i]) continue;

            Reservation premiere = reservations.get(i);
            LocalDateTime premierTemps = premiere.getDateHeureArrivee().toLocalDateTime();
            LocalDateTime depart       = premierTemps.plusMinutes(tempsAttenteMin);

            // --- Collecter les réservations candidates dans la fenêtre d'attente ---
            List<Integer> candidatsIdx = new ArrayList<>();
            for (int j = i + 1; j < reservations.size(); j++) {
                if (!assigned[j]) {
                    LocalDateTime t = reservations.get(j).getDateHeureArrivee().toLocalDateTime();
                    if (!t.isAfter(depart)) candidatsIdx.add(j);
                }
            }

            // --- Véhicules disponibles au moment de la 1ère réservation ---
            final LocalDateTime tp = premierTemps;
            List<Voiture> disponibles = voitures.stream()
                    .filter(v -> !disponibleA.get(v.getId()).isAfter(tp))
                    .collect(Collectors.toList());

            // --- Calculer le total passagers en incluant tous les candidats ---
            int totalPassagers = premiere.getNbPassager()
                    + candidatsIdx.stream().mapToInt(idx -> reservations.get(idx).getNbPassager()).sum();

            // Essayer de trouver un véhicule qui prend tout le monde
            Voiture selectionne = selectMeilleurVehicule(disponibles, totalPassagers);

            // Si impossible avec tous les candidats, prendre au moins la première réservation
            if (selectionne == null) {
                selectionne = selectMeilleurVehicule(disponibles, premiere.getNbPassager());
            }
            // Dernier recours : ignorer la disponibilité
            if (selectionne == null) {
                selectionne = selectMeilleurVehicule(voitures, premiere.getNbPassager());
            }
            if (selectionne == null) continue; // Impossible d'assigner

            // --- Constituer le lot final (greedy selon la capacité du véhicule choisi) ---
            List<Reservation> lot = new ArrayList<>();
            lot.add(premiere);
            assigned[i] = true;
            int passagersLot = premiere.getNbPassager();

            for (int idx : candidatsIdx) {
                int nb = reservations.get(idx).getNbPassager();
                if (passagersLot + nb <= selectionne.getNbPlace()) {
                    lot.add(reservations.get(idx));
                    assigned[idx] = true;
                    passagersLot += nb;
                }
            }

            // --- Calculer les horaires ---
            double km = DistanceController.getKmBetween(airportId, premiere.getIdLieuDestination());
            long dureeMinutes = vitesseKmH > 0 ? (long)((km / vitesseKmH) * 60) : 0;

            LocalDateTime arrivee        = depart.plusMinutes(dureeMinutes);
            LocalDateTime retourAeroport = arrivee.plusMinutes(dureeMinutes); // trajet retour

            disponibleA.put(selectionne.getId(), retourAeroport);

            entries.add(new PlanningEntry(selectionne, lot, depart, arrivee));
        }

        return entries;
    }

    /**
     * Sélectionne le meilleur véhicule selon les règles 1-4 du cahier des charges.
     */
    private Voiture selectMeilleurVehicule(List<Voiture> candidats, int passagersNecessaires) {
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

        // Règle 3 : priorité au Diesel
        List<Voiture> diesel = optimaux.stream()
                .filter(v -> v.getCarburant() == 'd')
                .collect(Collectors.toList());

        List<Voiture> pool = !diesel.isEmpty() ? diesel : optimaux;

        // Règle 4 : choix aléatoire parmi les ex-aequo
        return pool.get(new Random().nextInt(pool.size()));
    }

    // ========================
    //  HELPERS DB
    // ========================
    private List<Reservation> getReservationsForDate(String date) throws SQLException {
        List<Reservation> list = new ArrayList<>();
        String sql = "SELECT r.id, r.id_client, r.id_hotel, r.nb_passager, r.date_heure_arrivee, " +
                     "r.id_lieu_destination, l.code AS lieu_code " +
                     "FROM reservation r " +
                     "LEFT JOIN lieu l ON l.id = r.id_lieu_destination " +
                     "WHERE DATE(r.date_heure_arrivee) = ? " +
                     "   AND r.id_lieu_destination IS NOT NULL " +
                     "ORDER BY r.date_heure_arrivee";
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
                    r.setIdLieuDestination(rs.getInt("id_lieu_destination"));
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
                     "SELECT id FROM lieu WHERE is_airport = TRUE LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id");
        }
        // Fallback : premier lieu
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT id FROM lieu ORDER BY id LIMIT 1");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt("id");
        }
        return 0;
    }
}
