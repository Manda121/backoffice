package controller;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyParam;
import itu.framework.annotations.MyURL;
import itu.framework.db.DatabaseConnection;
import itu.framework.model.JsonResponse;
import itu.framework.model.ModelView;
import models.Hotel;
import models.Reservation;

@MyController
public class ReservationController {

    /**
     * Affiche le formulaire de réservation
     */
    @MyURL(value = "/reservation/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("reservationForm.jsp");
        
        try {
            List<Hotel> hotels = getAllHotels();
            mv.addItem("hotels", hotels);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors du chargement des hôtels: " + e.getMessage());
        }
        
        return mv;
    }

    /**
     * Enregistre une nouvelle réservation
     */
    @MyURL(value = "/reservation/save", method = "POST")
    public ModelView saveReservation(
            @MyParam(value = "idClient") String idClient,
            @MyParam(value = "idHotel") int idHotel,
            @MyParam(value = "nbPassager") int nbPassager,
            @MyParam(value = "dateHeureArrivee") String dateHeureArrivee) {
        
        ModelView mv = new ModelView();
        
        // Validation de l'ID client (4 caractères exactement)
        if (idClient == null || idClient.length() != 4) {
            mv.setView("reservationForm.jsp");
            mv.addItem("error", "L'ID client doit contenir exactement 4 caractères");
            try {
                mv.addItem("hotels", getAllHotels());
            } catch (SQLException e) {
                e.printStackTrace();
            }
            return mv;
        }
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            
            // Convertir la date string en Timestamp
            Timestamp timestamp = Timestamp.valueOf(dateHeureArrivee.replace("T", " ") + ":00");
            
            String sql = "INSERT INTO reservation (id_client, id_hotel, nb_passager, date_heure_arrivee) " +
                         "VALUES (?, ?, ?, ?)";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, idClient);
            pstmt.setInt(2, idHotel);
            pstmt.setInt(3, nbPassager);
            pstmt.setTimestamp(4, timestamp);
            
            pstmt.executeUpdate();
            
            mv.setView("reservationSuccess.jsp");
            
        } catch (SQLException e) {
            e.printStackTrace();
            mv.setView("reservationForm.jsp");
            mv.addItem("error", "Erreur lors de l'enregistrement: " + e.getMessage());
            try {
                mv.addItem("hotels", getAllHotels());
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            try {
                if (pstmt != null) pstmt.close();
                if (conn != null) conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
        
        return mv;
    }

    /**
     * API JSON: Liste toutes les réservations
     */
    @MyURL(value = "/api/reservations", method = "GET")
    public JsonResponse listReservationsApi() {
        JsonResponse response = new JsonResponse();
        
        try {
            List<Reservation> reservations = getAllReservationsWithDetails();
            response.setData(reservations);
            response.setStatus(200);
            response.setMessage("Liste des réservations récupérée avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
            response.setStatus(500);
            response.setMessage("Erreur lors de la récupération des réservations: " + e.getMessage());
        }
        
        return response;
    }

    /**
     * Page HTML: Liste toutes les réservations
     */
    @MyURL(value = "/reservation/list", method = "GET")
    public ModelView listReservations() {
        ModelView mv = new ModelView();
        mv.setView("reservationList.jsp");
        
        try {
            List<Reservation> reservations = getAllReservationsWithDetails();
            mv.addItem("reservations", reservations);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors du chargement des réservations: " + e.getMessage());
        }
        
        return mv;
    }

    // === Méthodes utilitaires ===

    /**
     * Récupère tous les hôtels de la base de données
     */
    private List<Hotel> getAllHotels() throws SQLException {
        List<Hotel> hotels = new ArrayList<>();
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT id, name, ville, adresse FROM hotel ORDER BY name");
            
            while (rs.next()) {
                Hotel hotel = new Hotel();
                hotel.setId(rs.getInt("id"));
                hotel.setName(rs.getString("name"));
                hotel.setVille(rs.getString("ville"));
                hotel.setAdresse(rs.getString("adresse"));
                hotels.add(hotel);
            }
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
        
        return hotels;
    }

    /**
     * Récupère toutes les réservations avec les détails des hôtels
     */
    private List<Reservation> getAllReservationsWithDetails() throws SQLException {
        List<Reservation> reservations = new ArrayList<>();
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            
            String sql = "SELECT r.id, r.id_client, r.id_hotel, r.nb_passager, r.date_heure_arrivee, " +
                         "h.name as hotel_name, h.ville as hotel_ville " +
                         "FROM reservation r " +
                         "JOIN hotel h ON r.id_hotel = h.id " +
                         "ORDER BY r.date_heure_arrivee DESC";
            
            rs = stmt.executeQuery(sql);
            
            while (rs.next()) {
                Reservation reservation = new Reservation();
                reservation.setId(rs.getInt("id"));
                reservation.setIdClient(rs.getString("id_client"));
                reservation.setIdHotel(rs.getInt("id_hotel"));
                reservation.setNbPassager(rs.getInt("nb_passager"));
                reservation.setDateHeureArrivee(rs.getTimestamp("date_heure_arrivee"));
                reservation.setHotelName(rs.getString("hotel_name"));
                reservation.setHotelVille(rs.getString("hotel_ville"));
                reservations.add(reservation);
            }
        } finally {
            if (rs != null) rs.close();
            if (stmt != null) stmt.close();
            if (conn != null) conn.close();
        }
        
        return reservations;
    }
}
