package controller;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import itu.framework.annotations.MyController;
import itu.framework.annotations.MyParam;
import itu.framework.annotations.MyURL;
import itu.framework.db.DatabaseConnection;
import itu.framework.model.ModelView;
import models.Parametre;

@MyController
public class ParametreController {

    // ========================
    //  LIST
    // ========================
    @MyURL(value = "/parametre/list", method = "GET")
    public ModelView listParametres() {
        ModelView mv = new ModelView();
        mv.setView("parametreList.jsp");
        try {
            mv.addItem("parametres", getAllParametres());
        } catch (SQLException e) {
            mv.addItem("error", "Erreur chargement paramètres : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  CREATE FORM
    // ========================
    @MyURL(value = "/parametre/form", method = "GET")
    public ModelView showForm() {
        ModelView mv = new ModelView();
        mv.setView("parametreForm.jsp");
        mv.addItem("action", "create");
        return mv;
    }

    // ========================
    //  SAVE
    // ========================
    @MyURL(value = "/parametre/save", method = "POST")
    public ModelView saveParametre(
            @MyParam(value = "code") String code,
            @MyParam(value = "valeur") String valeur,
            @MyParam(value = "description") String description) {

        ModelView mv = new ModelView();

        if (code == null || code.trim().isEmpty() || valeur == null || valeur.trim().isEmpty()) {
            mv.setView("parametreForm.jsp");
            mv.addItem("error", "Le code et la valeur sont obligatoires");
            mv.addItem("action", "create");
            return mv;
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO parametre (code, valeur, description) VALUES (?, ?, ?)")) {
            ps.setString(1, code.trim());
            ps.setString(2, valeur.trim());
            ps.setString(3, description != null ? description.trim() : "");
            ps.executeUpdate();
            mv.setView("parametreList.jsp");
            mv.addItem("success", "Paramètre enregistré avec succès !");
            mv.addItem("parametres", getAllParametres());
        } catch (SQLException e) {
            mv.setView("parametreForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "create");
        }
        return mv;
    }

    // ========================
    //  EDIT FORM
    // ========================
    @MyURL(value = "/parametre/edit", method = "GET")
    public ModelView showEditForm(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        mv.setView("parametreForm.jsp");
        mv.addItem("action", "edit");
        try {
            Parametre p = getParametreById(id);
            if (p == null) {
                mv.setView("parametreList.jsp");
                mv.addItem("error", "Paramètre introuvable");
                mv.addItem("parametres", getAllParametres());
            } else {
                mv.addItem("parametre", p);
            }
        } catch (SQLException e) {
            mv.addItem("error", "Erreur : " + e.getMessage());
        }
        return mv;
    }

    // ========================
    //  UPDATE
    // ========================
    @MyURL(value = "/parametre/update", method = "POST")
    public ModelView updateParametre(
            @MyParam(value = "id") int id,
            @MyParam(value = "code") String code,
            @MyParam(value = "valeur") String valeur,
            @MyParam(value = "description") String description) {

        ModelView mv = new ModelView();

        if (code == null || code.trim().isEmpty() || valeur == null || valeur.trim().isEmpty()) {
            mv.setView("parametreForm.jsp");
            mv.addItem("error", "Le code et la valeur sont obligatoires");
            mv.addItem("action", "edit");
            return mv;
        }

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE parametre SET code = ?, valeur = ?, description = ? WHERE id = ?")) {
            ps.setString(1, code.trim());
            ps.setString(2, valeur.trim());
            ps.setString(3, description != null ? description.trim() : "");
            ps.setInt(4, id);
            ps.executeUpdate();
            mv.setView("parametreList.jsp");
            mv.addItem("success", "Paramètre modifié avec succès !");
            mv.addItem("parametres", getAllParametres());
        } catch (SQLException e) {
            mv.setView("parametreForm.jsp");
            mv.addItem("error", "Erreur : " + e.getMessage());
            mv.addItem("action", "edit");
        }
        return mv;
    }

    // ========================
    //  DELETE
    // ========================
    @MyURL(value = "/parametre/delete", method = "POST")
    public ModelView deleteParametre(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement("DELETE FROM parametre WHERE id = ?")) {
            ps.setInt(1, id);
            ps.executeUpdate();
            mv.setView("parametreList.jsp");
            mv.addItem("success", "Paramètre supprimé.");
            mv.addItem("parametres", getAllParametres());
        } catch (SQLException e) {
            mv.setView("parametreList.jsp");
            mv.addItem("error", "Erreur suppression : " + e.getMessage());
            try { mv.addItem("parametres", getAllParametres()); } catch (SQLException ex) { ex.printStackTrace(); }
        }
        return mv;
    }

    // ========================
    //  HELPERS
    // ========================
    public static List<Parametre> getAllParametres() throws SQLException {
        List<Parametre> list = new ArrayList<>();
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, code, valeur, description FROM parametre ORDER BY code");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Parametre(rs.getInt("id"), rs.getString("code"),
                        rs.getString("valeur"), rs.getString("description")));
            }
        }
        return list;
    }

    /** Retourne la valeur d'un paramètre par son code (défaut retourné si absent). */
    public static double getParamDouble(String code, double defaultValue) {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT valeur FROM parametre WHERE code = ?")) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return Double.parseDouble(rs.getString("valeur"));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return defaultValue;
    }

    public static int getParamInt(String code, int defaultValue) {
        return (int) getParamDouble(code, defaultValue);
    }

    private Parametre getParametreById(int id) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT id, code, valeur, description FROM parametre WHERE id = ?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Parametre(rs.getInt("id"), rs.getString("code"),
                            rs.getString("valeur"), rs.getString("description"));
                }
            }
        }
        return null;
    }
}
