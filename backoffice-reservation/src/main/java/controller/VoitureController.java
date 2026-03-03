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
import models.Voiture;
import util.TokenUtil;

@MyController
public class VoitureController {

    // ========================
    //  LIST - Afficher toutes les voitures
    // ========================
    @MyURL(value = "/voiture/list", method = "GET")
    public ModelView listVoitures() {
        ModelView mv = new ModelView();
        mv.setView("voitureList.jsp");

        try {
            List<Voiture> voitures = getAllVoitures();
            mv.addItem("voitures", voitures);
        } catch (SQLException e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors du chargement des voitures: " + e.getMessage());
        }

        return mv;
    }

    // ========================
    //  CREATE - Afficher le formulaire d'ajout
    // ========================
    @MyURL(value = "/voiture/form", method = "GET")
    public ModelView showCreateForm() {
        ModelView mv = new ModelView();
        mv.setView("voitureForm.jsp");
        mv.addItem("action", "create");
        return mv;
    }

    // ========================
    //  CREATE - Enregistrer une nouvelle voiture
    // ========================
    @MyURL(value = "/voiture/save", method = "POST")
    public ModelView saveVoiture(
            @MyParam(value = "marque") String marque,
            @MyParam(value = "nbPlace") int nbPlace,
            @MyParam(value = "type") String type,
            @MyParam(value = "carburant") String carburant,
            @MyParam(value = "matricule") String matricule) {

        ModelView mv = new ModelView();

        // Validation
        if (marque == null || marque.trim().isEmpty()) {
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "La marque est obligatoire");
            mv.addItem("action", "create");
            return mv;
        }

        if (carburant == null || carburant.length() != 1 || "deh".indexOf(carburant.charAt(0)) == -1) {
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "Le carburant doit être 'd' (diesel), 'e' (essence) ou 'h' (hybride)");
            mv.addItem("action", "create");
            return mv;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();

            String sql = "INSERT INTO voiture (marque, nb_place, type, carburant, matricule) VALUES (?, ?, ?, ?, ?)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, marque.trim());
            pstmt.setInt(2, nbPlace);
            pstmt.setString(3, type.trim());
            pstmt.setString(4, carburant);
            pstmt.setString(5, matricule != null ? matricule.trim() : null);

            pstmt.executeUpdate();

            // Rediriger vers la liste après succès
            mv.setView("voitureList.jsp");
            mv.addItem("success", "Voiture ajoutée avec succès !");
            mv.addItem("voitures", getAllVoitures());

        } catch (SQLException e) {
            e.printStackTrace();
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "Erreur lors de l'enregistrement: " + e.getMessage());
            mv.addItem("action", "create");
        } finally {
            closeResources(null, pstmt, conn);
        }

        return mv;
    }

    // ========================
    //  EDIT - Afficher le formulaire de modification
    // ========================
    @MyURL(value = "/voiture/edit", method = "GET")
    public ModelView showEditForm(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        mv.setView("voitureForm.jsp");
        mv.addItem("action", "edit");

        try {
            Voiture voiture = getVoitureById(id);
            if (voiture == null) {
                mv.setView("voitureList.jsp");
                mv.addItem("error", "Voiture introuvable (ID: " + id + ")");
                mv.addItem("voitures", getAllVoitures());
            } else {
                mv.addItem("voiture", voiture);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            mv.setView("voitureList.jsp");
            mv.addItem("error", "Erreur: " + e.getMessage());
            try {
                mv.addItem("voitures", getAllVoitures());
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        }

        return mv;
    }

    // ========================
    //  UPDATE - Mettre à jour une voiture
    // ========================
    @MyURL(value = "/voiture/update", method = "POST")
    public ModelView updateVoiture(
            @MyParam(value = "id") int id,
            @MyParam(value = "marque") String marque,
            @MyParam(value = "nbPlace") int nbPlace,
            @MyParam(value = "type") String type,
            @MyParam(value = "carburant") String carburant,
            @MyParam(value = "matricule") String matricule) {

        ModelView mv = new ModelView();

        // Validation
        if (marque == null || marque.trim().isEmpty()) {
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "La marque est obligatoire");
            mv.addItem("action", "edit");
            try { mv.addItem("voiture", getVoitureById(id)); } catch (SQLException e) { e.printStackTrace(); }
            return mv;
        }

        if (carburant == null || carburant.length() != 1 || "deh".indexOf(carburant.charAt(0)) == -1) {
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "Le carburant doit être 'd' (diesel), 'e' (essence) ou 'h' (hybride)");
            mv.addItem("action", "edit");
            try { mv.addItem("voiture", getVoitureById(id)); } catch (SQLException e) { e.printStackTrace(); }
            return mv;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();

            String sql = "UPDATE voiture SET marque = ?, nb_place = ?, type = ?, carburant = ?, matricule = ? WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, marque.trim());
            pstmt.setInt(2, nbPlace);
            pstmt.setString(3, type.trim());
            pstmt.setString(4, carburant);
            pstmt.setString(5, matricule != null ? matricule.trim() : null);
            pstmt.setInt(6, id);

            int rows = pstmt.executeUpdate();

            mv.setView("voitureList.jsp");
            if (rows > 0) {
                mv.addItem("success", "Voiture modifiée avec succès !");
            } else {
                mv.addItem("error", "Aucune voiture trouvée avec l'ID: " + id);
            }
            mv.addItem("voitures", getAllVoitures());

        } catch (SQLException e) {
            e.printStackTrace();
            mv.setView("voitureForm.jsp");
            mv.addItem("error", "Erreur lors de la modification: " + e.getMessage());
            mv.addItem("action", "edit");
            try { mv.addItem("voiture", getVoitureById(id)); } catch (SQLException ex) { ex.printStackTrace(); }
        } finally {
            closeResources(null, pstmt, conn);
        }

        return mv;
    }

    // ========================
    //  DELETE - Supprimer une voiture
    // ========================
    @MyURL(value = "/voiture/delete", method = "GET")
    public ModelView deleteVoiture(@MyParam(value = "id") int id) {
        ModelView mv = new ModelView();
        mv.setView("voitureList.jsp");

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();

            String sql = "DELETE FROM voiture WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, id);

            int rows = pstmt.executeUpdate();

            if (rows > 0) {
                mv.addItem("success", "Voiture supprimée avec succès !");
            } else {
                mv.addItem("error", "Aucune voiture trouvée avec l'ID: " + id);
            }

            mv.addItem("voitures", getAllVoitures());

        } catch (SQLException e) {
            e.printStackTrace();
            mv.addItem("error", "Erreur lors de la suppression: " + e.getMessage());
            try {
                mv.addItem("voitures", getAllVoitures());
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
        } finally {
            closeResources(null, pstmt, conn);
        }

        return mv;
    }

    // ===================================================
    //  API JSON (avec contrôle de token)
    // ===================================================

    /**
     * API: Liste toutes les voitures
     * GET /api/voitures?token=xxx
     */
    @MyURL(value = "/api/voitures", method = "GET")
    public JsonResponse apiListVoitures(@MyParam(value = "token") String token) {
        if (!TokenUtil.isValidToken(token)) {
            return JsonResponse.unauthorized("Token invalide ou expiré");
        }
        try {
            List<Voiture> voitures = getAllVoitures();
            return JsonResponse.success(voitures, "Liste des voitures récupérée avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
            return JsonResponse.serverError("Erreur: " + e.getMessage());
        }
    }

    /**
     * API: Récupérer une voiture par ID
     * GET /api/voiture?id=X&token=xxx
     */
    @MyURL(value = "/api/voiture", method = "GET")
    public JsonResponse apiGetVoiture(@MyParam(value = "id") int id, @MyParam(value = "token") String token) {
        if (!TokenUtil.isValidToken(token)) {
            return JsonResponse.unauthorized("Token invalide ou expiré");
        }
        try {
            Voiture voiture = getVoitureById(id);
            if (voiture == null) {
                return JsonResponse.notFound("Voiture introuvable (ID: " + id + ")");
            }
            return JsonResponse.success(voiture, "Voiture récupérée avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
            return JsonResponse.serverError("Erreur: " + e.getMessage());
        }
    }

    /**
     * API: Créer une voiture
     * POST /api/voiture/save?token=xxx  (params: marque, nbPlace, type, carburant)
     */
    @MyURL(value = "/api/voiture/save", method = "POST")
    public JsonResponse apiSaveVoiture(
            @MyParam(value = "token") String token,
            @MyParam(value = "marque") String marque,
            @MyParam(value = "nbPlace") int nbPlace,
            @MyParam(value = "type") String type,
            @MyParam(value = "carburant") String carburant,
            @MyParam(value = "matricule") String matricule) {

        if (!TokenUtil.isValidToken(token)) {
            return JsonResponse.unauthorized("Token invalide ou expiré");
        }
        if (marque == null || marque.trim().isEmpty()) {
            return JsonResponse.badRequest("La marque est obligatoire");
        }
        if (carburant == null || carburant.length() != 1 || "deh".indexOf(carburant.charAt(0)) == -1) {
            return JsonResponse.badRequest("Le carburant doit être 'd', 'e' ou 'h'");
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "INSERT INTO voiture (marque, nb_place, type, carburant, matricule) VALUES (?, ?, ?, ?, ?)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, marque.trim());
            pstmt.setInt(2, nbPlace);
            pstmt.setString(3, type.trim());
            pstmt.setString(4, carburant);
            pstmt.setString(5, matricule != null ? matricule.trim() : null);
            pstmt.executeUpdate();

            return JsonResponse.success(null, "Voiture créée avec succès");
        } catch (SQLException e) {
            e.printStackTrace();
            return JsonResponse.serverError("Erreur: " + e.getMessage());
        } finally {
            closeResources(null, pstmt, conn);
        }
    }

    /**
     * API: Modifier une voiture
     * POST /api/voiture/update?token=xxx  (params: id, marque, nbPlace, type, carburant)
     */
    @MyURL(value = "/api/voiture/update", method = "POST")
    public JsonResponse apiUpdateVoiture(
            @MyParam(value = "token") String token,
            @MyParam(value = "id") int id,
            @MyParam(value = "marque") String marque,
            @MyParam(value = "nbPlace") int nbPlace,
            @MyParam(value = "type") String type,
            @MyParam(value = "carburant") String carburant,
            @MyParam(value = "matricule") String matricule) {

        if (!TokenUtil.isValidToken(token)) {
            return JsonResponse.unauthorized("Token invalide ou expiré");
        }
        if (marque == null || marque.trim().isEmpty()) {
            return JsonResponse.badRequest("La marque est obligatoire");
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "UPDATE voiture SET marque = ?, nb_place = ?, type = ?, carburant = ?, matricule = ? WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, marque.trim());
            pstmt.setInt(2, nbPlace);
            pstmt.setString(3, type.trim());
            pstmt.setString(4, carburant);
            pstmt.setString(5, matricule != null ? matricule.trim() : null);
            pstmt.setInt(6, id);

            int rows = pstmt.executeUpdate();
            if (rows > 0) {
                return JsonResponse.success(null, "Voiture modifiée avec succès");
            } else {
                return JsonResponse.notFound("Voiture introuvable (ID: " + id + ")");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return JsonResponse.serverError("Erreur: " + e.getMessage());
        } finally {
            closeResources(null, pstmt, conn);
        }
    }

    /**
     * API: Supprimer une voiture
     * GET /api/voiture/delete?id=X&token=xxx
     */
    @MyURL(value = "/api/voiture/delete", method = "GET")
    public JsonResponse apiDeleteVoiture(@MyParam(value = "id") int id, @MyParam(value = "token") String token) {
        if (!TokenUtil.isValidToken(token)) {
            return JsonResponse.unauthorized("Token invalide ou expiré");
        }

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "DELETE FROM voiture WHERE id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, id);

            int rows = pstmt.executeUpdate();
            if (rows > 0) {
                return JsonResponse.success(null, "Voiture supprimée avec succès");
            } else {
                return JsonResponse.notFound("Voiture introuvable (ID: " + id + ")");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return JsonResponse.serverError("Erreur: " + e.getMessage());
        } finally {
            closeResources(null, pstmt, conn);
        }
    }

    // ===========================
    //  Méthodes utilitaires
    // ===========================

    /**
     * Récupère toutes les voitures
     */
    private List<Voiture> getAllVoitures() throws SQLException {
        List<Voiture> voitures = new ArrayList<>();
        Connection conn = null;
        Statement stmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            stmt = conn.createStatement();
            rs = stmt.executeQuery("SELECT id, marque, nb_place, type, carburant, matricule FROM voiture ORDER BY id");

            while (rs.next()) {
                Voiture v = new Voiture();
                v.setId(rs.getInt("id"));
                v.setMarque(rs.getString("marque"));
                v.setNbPlace(rs.getInt("nb_place"));
                v.setType(rs.getString("type"));
                v.setCarburant(rs.getString("carburant").charAt(0));
                v.setMatricule(rs.getString("matricule"));
                voitures.add(v);
            }
        } finally {
            closeResources(rs, stmt, conn);
        }

        return voitures;
    }

    /**
     * Récupère une voiture par son ID
     */
    private Voiture getVoitureById(int id) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement("SELECT id, marque, nb_place, type, carburant, matricule FROM voiture WHERE id = ?");
            pstmt.setInt(1, id);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                Voiture v = new Voiture();
                v.setId(rs.getInt("id"));
                v.setMarque(rs.getString("marque"));
                v.setNbPlace(rs.getInt("nb_place"));
                v.setType(rs.getString("type"));
                v.setCarburant(rs.getString("carburant").charAt(0));
                v.setMatricule(rs.getString("matricule"));
                return v;
            }
        } finally {
            closeResources(rs, pstmt, conn);
        }

        return null;
    }

    /**
     * Ferme proprement les ressources JDBC
     */
    private void closeResources(ResultSet rs, Statement stmt, Connection conn) {
        try { if (rs != null) rs.close(); } catch (SQLException e) { e.printStackTrace(); }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { e.printStackTrace(); }
        try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
    }
}
