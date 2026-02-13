package util;

import java.sql.*;
import java.util.UUID;

/**
 * Programme standalone pour générer un token d'API et l'enregistrer en base de données.
 * Le token expire après 24 heures.
 * 
 * Usage: java -cp "target/classes;target/libs/*" util.Main
 */
public class Main {

    // Configuration de la base de données (même que database.properties)
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/reservation";
    private static final String DB_USER = "postgres";
    private static final String DB_PASSWORD = "postgres";

    public static void main(String[] args) {
        // Générer un token UUID unique
        String token = UUID.randomUUID().toString();

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            // Charger le driver PostgreSQL
            Class.forName("org.postgresql.Driver");

            // Connexion à la base
            conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);

            // Insérer le token avec expiration dans 24h
            String sql = "INSERT INTO token (token, date_heure_expiration) VALUES (?, NOW() + INTERVAL '24 hours')";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, token);
            pstmt.executeUpdate();

            // Récupérer la date d'expiration pour l'afficher
            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery(
                "SELECT date_heure_expiration FROM token WHERE token = '" + token + "'"
            );

            String expiration = "";
            if (rs.next()) {
                expiration = rs.getTimestamp("date_heure_expiration").toString();
            }
            rs.close();
            stmt.close();

            System.out.println();
            System.out.println("=============================================");
            System.out.println("   TOKEN GENERE AVEC SUCCES !");
            System.out.println("=============================================");
            System.out.println("   Token      : " + token);
            System.out.println("   Expiration : " + expiration);
            System.out.println("=============================================");
            System.out.println();
            System.out.println("   Utilisez ce token pour appeler les API :");
            System.out.println("   /api/voitures?token=" + token);
            System.out.println("   /api/reservations?token=" + token);
            System.out.println("=============================================");
            System.out.println();

        } catch (ClassNotFoundException e) {
            System.err.println("ERREUR: Driver PostgreSQL introuvable !");
            System.err.println("Assurez-vous que le JAR postgresql est dans le classpath.");
            e.printStackTrace();
        } catch (SQLException e) {
            System.err.println("ERREUR SQL: " + e.getMessage());
            System.err.println("Vérifiez que la base 'reservation' existe et que la table 'token' est créée.");
            e.printStackTrace();
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
}
