package controller;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyParam;
import itu.framework.annotations.MyURL;
import itu.framework.db.DatabaseConnection;
import itu.framework.model.ModelView;
import models.Distance;
import models.Lieu;

@MyController
public class DistanceController {

    // ========================
    //  LIST
    // ========================
    @MyURL(value = "/distance/list", method = "GET")
    public ModelView listDistances() {
        ModelView mv = new ModelView();
        mv.setView("distanceList.jsp");
        try {
            mv.addItem("distances", getAllDistances());
        } catch (SQLException e) {
            mv.addItem("error", "Erreur chargement distances : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  CREATE FORM
    // ========================
    @MyURL(value = "/distance/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("distanceForm.jsp");
        mv.addItem("action", "create");
        try {
            mv.addItem("lieux", LieuController.getAllLieux());
        } catch (SQLException e) {
            mv.addItem("error", "Erreur chargement lieux : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  SAVE
    // ========================
    @MyURL(value = "/distance/save", method = "POST")
    public ModelView saveDistance(
            @MyParam(value = "lieuFrom") int lieuFrom,
            @MyParam(value = "lieuTo") int lieuTo,
            @MyParam(value = "km") double km) {

        ModelView mv = new ModelView();

        if (lieuFrom == lieuTo) {
            mv.setView("distanceForm.jsp");
            mv.addItem("error", "Le lieu de départ et d'arrivée ne peuvent pas être identiques");
            mv.addItem("action", "create");
            try { mv.addItem("lieux", LieuController.getAllLieux()); } catch (SQLException e) { e.printStackTrace(); }
            return mv;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Vérifier la redondance (A→B interdit si B→A existe déjà)
            if (reverseExists(conn, lieuFrom, lieuTo)) {
                mv.setView("distanceForm.jsp");
                mv.addItem("error", "Cette distance existe déjà (dans le sens inverse). La distance est symétrique.");
                mv.addItem("action", "create");
                mv.addItem("lieux", LieuController.getAllLieux());
                return mv;
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO distance (lieu_from, lieu_to, km) VALUES (?, ?, ?)")) {
                ps.setInt(1, lieuFrom);
                ps.setInt(2, lieuTo);
                ps.setDouble(3, km);
                ps.executeUpdate();
            }
            mv.setView("distanceList.jsp");
            mv.addItem("success", "Distance enregistrée avec succès !");
            mv.addItem("distances", getAllDistances());
        } catch (SQLException e) {
            mv.setView("distanceForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "create");
            try { mv.addItem("lieux", LieuController.getAllLieux()); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        return mv;
    }

    // ========================
    //  EDIT FORM
    // ========================
    @MyURL(value = "/distance/edit", method = "GET")
    public ModelView showEditForm(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        mv.setView("distanceForm.jsp");
        mv.addItem("action", "edit");
        try {
            Distance d = getDistanceById(id);
            if (d == null) {
                mv.setView("distanceList.jsp");
                mv.addItem("error", "Distance introuvable");
                mv.addItem("distances", getAllDistances());
            } else {
                mv.addItem("distance", d);
                mv.addItem("lieux", LieuController.getAllLieux());
            }
        } catch (SQLException e) {
            mv.addItem("error", "Erreur : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  UPDATE
    // ========================
    @MyURL(value = "/distance/update", method = "POST")
    public ModelView updateDistance(
            @MyParam(value = "id") int id,
            @MyParam(value = "lieuFrom") int lieuFrom,
            @MyParam(value = "lieuTo") int lieuTo,
            @MyParam(value = "km") double km) {

        ModelView mv = new ModelView();

        if (lieuFrom == lieuTo) {
            mv.setView("distanceForm.jsp");
            mv.addItem("error", "Le lieu de départ et d'arrivée ne peuvent pas être identiques");
            mv.addItem("action", "edit");
            try { mv.addItem("lieux", LieuController.getAllLieux()); } catch (SQLException e) { e.printStackTrace(); }
            return mv;
        }

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Vérifier redondance inverse (en excluant cet enregistrement)
            String checkSql = "SELECT id FROM distance WHERE id <> ? AND " +
                    "((lieu_from = ? AND lieu_to = ?) OR (lieu_from = ? AND lieu_to = ?))";
            try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
                ps.setInt(1, id); ps.setInt(2, lieuTo); ps.setInt(3, lieuFrom);
                ps.setInt(4, lieuFrom); ps.setInt(5, lieuTo);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        mv.setView("distanceForm.jsp");
                        mv.addItem("error", "Cette distance existe déjà (même paire de lieux).");
                        mv.addItem("action", "edit");
                        mv.addItem("lieux", LieuController.getAllLieux());
                        mv.addItem("distance", getDistanceById(id));
                        return mv;
                    }
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE distance SET lieu_from = ?, lieu_to = ?, km = ? WHERE id = ?")) {
                ps.setInt(1, lieuFrom);
                ps.setInt(2, lieuTo);
                ps.setDouble(3, km);
                ps.setInt(4, id);
                ps.executeUpdate();
            }
            mv.setView("distanceList.jsp");
            mv.addItem("success", "Distance modifiée avec succès !");
            mv.addItem("distances", getAllDistances());
        } catch (SQLException e) {
            mv.setView("distanceForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "edit");
            try { mv.addItem("lieux", LieuController.getAllLieux()); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        return mv;
    }

    // ========================
    //  DELETE
    // ========================
    @MyURL(value = "/distance/delete", method = "POST")
    public ModelView deleteDistance(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM distance WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
            mv.setView("distanceList.jsp");
            mv.addItem("success", "Distance supprimée.");
            mv.addItem("distances", getAllDistances());
        } catch (SQLException e) {
            mv.setView("distanceList.jsp");
            mv.addItem("error", "Erreur suppression : " + e.getMessage());
            try { mv.addItem("distances", getAllDistances()); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        return mv;
    }

    // ========================
    //  HELPERS
    // ========================
    public static List<Distance> getAllDistances() throws SQLException {
        List<Distance> list = new ArrayList<>();
        String sql = "SELECT d.id, d.lieu_from, d.lieu_to, d.km, h1.code AS from_code, h2.code AS to_code " +
                     "FROM distance d " +
                     "JOIN hotel h1 ON h1.id = d.lieu_from " +
                     "JOIN hotel h2 ON h2.id = d.lieu_to " +
                     "ORDER BY h1.code, h2.code";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Distance d = new Distance(rs.getInt("id"), rs.getInt("lieu_from"),
                        rs.getInt("lieu_to"), rs.getDouble("km"));
                d.setLieuFromCode(rs.getString("from_code"));
                d.setLieuToCode(rs.getString("to_code"));
                list.add(d);
            }
        }
        return list;
    }

    private Distance getDistanceById(int id) throws SQLException {
        String sql = "SELECT d.id, d.lieu_from, d.lieu_to, d.km, h1.code AS from_code, h2.code AS to_code " +
                     "FROM distance d " +
                     "JOIN hotel h1 ON h1.id = d.lieu_from " +
                     "JOIN hotel h2 ON h2.id = d.lieu_to " +
                     "WHERE d.id = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Distance d = new Distance(rs.getInt("id"), rs.getInt("lieu_from"),
                            rs.getInt("lieu_to"), rs.getDouble("km"));
                    d.setLieuFromCode(rs.getString("from_code"));
                    d.setLieuToCode(rs.getString("to_code"));
                    return d;
                }
            }
        }
        return null;
    }

    private boolean reverseExists(Connection conn, int lieuFrom, int lieuTo) throws SQLException {
        String sql = "SELECT id FROM distance WHERE " +
                     "(lieu_from = ? AND lieu_to = ?) OR (lieu_from = ? AND lieu_to = ?)";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, lieuFrom); ps.setInt(2, lieuTo);
            ps.setInt(3, lieuTo);  ps.setInt(4, lieuFrom);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Retourne la distance en km entre deux lieux (dans n'importe quel sens).
     */
    public static double getKmBetween(int lieuAId, int lieuBId) throws SQLException {
        String sql = "SELECT km FROM distance WHERE " +
                     "(lieu_from = ? AND lieu_to = ?) OR (lieu_from = ? AND lieu_to = ?)";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, lieuAId); ps.setInt(2, lieuBId);
            ps.setInt(3, lieuBId); ps.setInt(4, lieuAId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble("km");
            }
        }
        return 0;
    }
}
