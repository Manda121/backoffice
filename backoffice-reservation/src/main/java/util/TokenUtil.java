package util;

import java.sql.*;
import itu.framework.db.DatabaseConnection;

public class TokenUtil {

    /**
     * Vérifie si un token est valide (existe en base et n'est pas expiré)
     */
    public static boolean isValidToken(String token) {
        if (token == null || token.trim().isEmpty()) {
            return false;
        }

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT id FROM token WHERE token = ? AND date_heure_expiration > NOW()";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, token.trim());
            rs = pstmt.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) { e.printStackTrace(); }
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) { e.printStackTrace(); }
            try { if (conn != null) conn.close(); } catch (SQLException e) { e.printStackTrace(); }
        }
    }
}
