package itu.framework.db;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseConnection {
    private static String url;
    private static String user;
    private static String password;
    private static boolean initialized = false;

    /**
     * Initialise la configuration depuis un fichier properties dans le classpath
     */
    public static void initialize() throws Exception {
        if (initialized) return;
        
        Properties props = new Properties();
        InputStream input = null;
        try {
            input = DatabaseConnection.class.getClassLoader()
                    .getResourceAsStream("database.properties");
            if (input == null) {
                throw new Exception("Fichier database.properties introuvable dans le classpath");
            }
            props.load(input);
            
            url = props.getProperty("db.url");
            user = props.getProperty("db.user");
            password = props.getProperty("db.password");
            
            if (url == null || user == null || password == null) {
                throw new Exception("Configuration incomplète dans database.properties");
            }
            
            // Charger le driver PostgreSQL
            Class.forName("org.postgresql.Driver");
            initialized = true;
        } finally {
            if (input != null) {
                try {
                    input.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Obtient une connexion à la base de données
     */
    public static Connection getConnection() throws SQLException {
        if (!initialized) {
            try {
                initialize();
            } catch (Exception e) {
                throw new SQLException("Erreur d'initialisation de la connexion: " + e.getMessage(), e);
            }
        }
        return DriverManager.getConnection(url, user, password);
    }

    /**
     * Ferme proprement une connexion
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}
