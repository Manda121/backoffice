package controller;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyParam;
import itu.framework.annotations.MyURL;
import itu.framework.db.DatabaseConnection;
import itu.framework.model.ModelView;
import models.Lieu;

@MyController
public class LieuController {

    // ========================
    //  LIST
    // ========================
    @MyURL(value = "/lieu/list", method = "GET")
    public ModelView listLieux() {
        ModelView mv = new ModelView();
        mv.setView("lieuList.jsp");
        try {
            mv.addItem("lieux", getAllLieux());
        } catch (SQLException e) {
            mv.addItem("error", "Erreur chargement lieux : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  CREATE FORM
    // ========================
    @MyURL(value = "/lieu/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("lieuForm.jsp");
        mv.addItem("action", "create");
        return mv;
    }

    // ========================
    //  SAVE
    // ========================
    @MyURL(value = "/lieu/save", method = "POST")
    public ModelView saveLieu(
            @MyParam(value = "code") String code,
            @MyParam(value = "isAirport") String isAirportStr) {

        ModelView mv = new ModelView();

        if (code == null || code.trim().isEmpty()) {
            mv.setView("lieuForm.jsp");
            mv.addItem("error", "Le code du lieu est obligatoire");
            mv.addItem("action", "create");
            return mv;
        }

        boolean isAirport = "on".equals(isAirportStr) || "true".equals(isAirportStr);

        try (Connection conn = DatabaseConnection.getConnection()) {
            // Si isAirport est coché, réinitialiser les autres aéroports
            if (isAirport) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE lieu SET is_airport = FALSE WHERE is_airport = TRUE")) {
                    ps.executeUpdate();
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO lieu (code, is_airport) VALUES (?, ?)")) {
                ps.setString(1, code.trim().toUpperCase());
                ps.setBoolean(2, isAirport);
                ps.executeUpdate();
            }
            mv.setView("lieuList.jsp");
            mv.addItem("success", "Lieu ajouté avec succès !");
            mv.addItem("lieux", getAllLieux());
        } catch (SQLException e) {
            mv.setView("lieuForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "create");
        }
        return mv;
    }

    // ========================
    //  EDIT FORM
    // ========================
    @MyURL(value = "/lieu/edit", method = "GET")
    public ModelView showEditForm(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        mv.setView("lieuForm.jsp");
        mv.addItem("action", "edit");
        try {
            Lieu lieu = getLieuById(id);
            if (lieu == null) {
                mv.setView("lieuList.jsp");
                mv.addItem("error", "Lieu introuvable");
                mv.addItem("lieux", getAllLieux());
            } else {
                mv.addItem("lieu", lieu);
            }
        } catch (SQLException e) {
            mv.addItem("error", "Erreur : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  UPDATE
    // ========================
    @MyURL(value = "/lieu/update", method = "POST")
    public ModelView updateLieu(
            @MyParam(value = "id") int id,
            @MyParam(value = "code") String code,
            @MyParam(value = "isAirport") String isAirportStr) {

        ModelView mv = new ModelView();

        if (code == null || code.trim().isEmpty()) {
            mv.setView("lieuForm.jsp");
            mv.addItem("error", "Le code est obligatoire");
            mv.addItem("action", "edit");
            return mv;
        }

        boolean isAirport = "on".equals(isAirportStr) || "true".equals(isAirportStr);

        try (Connection conn = DatabaseConnection.getConnection()) {
            if (isAirport) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE lieu SET is_airport = FALSE WHERE is_airport = TRUE AND id <> ?")) {
                    ps.setInt(1, id);
                    ps.executeUpdate();
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE lieu SET code = ?, is_airport = ? WHERE id = ?")) {
                ps.setString(1, code.trim().toUpperCase());
                ps.setBoolean(2, isAirport);
                ps.setInt(3, id);
                ps.executeUpdate();
            }
            mv.setView("lieuList.jsp");
            mv.addItem("success", "Lieu modifié avec succès !");
            mv.addItem("lieux", getAllLieux());
        } catch (SQLException e) {
            mv.setView("lieuForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "edit");
        }
        return mv;
    }

    // ========================
    //  DELETE
    // ========================
    @MyURL(value = "/lieu/delete", method = "POST")
    public ModelView deleteLieu(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM lieu WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
            mv.setView("lieuList.jsp");
            mv.addItem("success", "Lieu supprimé.");
            mv.addItem("lieux", getAllLieux());
        } catch (SQLException e) {
            mv.setView("lieuList.jsp");
            mv.addItem("error", "Erreur suppression : " + e.getMessage());
            try { mv.addItem("lieux", getAllLieux()); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        return mv;
    }

    // ========================
    //  HELPERS
    // ========================
    public static List<Lieu> getAllLieux() throws SQLException {
        List<Lieu> lieux = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT id, code, is_airport FROM lieu ORDER BY code");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lieux.add(new Lieu(rs.getInt("id"), rs.getString("code"), rs.getBoolean("is_airport")));
            }
        }
        return lieux;
    }

    private Lieu getLieuById(int id) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, code, is_airport FROM lieu WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Lieu(rs.getInt("id"), rs.getString("code"), rs.getBoolean("is_airport"));
                }
            }
        }
        return null;
    }
}
