<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Hotel" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Nouvelle Réservation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .form-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            color: #555;
            font-weight: bold;
        }
        input[type="text"],
        input[type="number"],
        input[type="datetime-local"],
        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        input[type="submit"] {
            background-color: #4CAF50;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
        }
        input[type="submit"]:hover {
            background-color: #45a049;
        }
        .info {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        .nav-link {
            text-align: center;
            margin-top: 20px;
        }
        .nav-link a {
            color: #4CAF50;
            text-decoration: none;
        }
        .nav-link a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <h1>📝 Nouvelle Réservation</h1>
        
        <form action="${pageContext.request.contextPath}/reservation/save" method="post">
            <div class="form-group">
                <label for="idClient">ID Client:</label>
                <input type="text" id="idClient" name="idClient" maxlength="4" required pattern="[A-Za-z0-9]{4}">
                <div class="info">* Exactement 4 caractères alphanumériques</div>
            </div>

            <div class="form-group">
                <label>Lieu de départ :</label>
                <%
                    Lieu airport = (Lieu) request.getAttribute("airport");
                %>
                <input type="text" value="✈ <%= airport != null ? airport.getCode() : "Aéroport" %> (départ fixe)" readonly
                       style="background-color:#e8f5e9; color:#2e7d32; font-weight:bold; cursor:default;">
                <div class="info">* Le véhicule part toujours depuis l'aéroport</div>
            </div>

            <div class="form-group">
                <label for="idHotel">Hôtel (lieu d'arrivée) :</label>
                <select id="idHotel" name="idHotel" required>
                    <option value="">-- Sélectionnez un hôtel --</option>
                    <%
                        List<Hotel> hotels = (List<Hotel>) request.getAttribute("hotels");
                        if (hotels != null) {
                            for (Hotel hotel : hotels) {
                    %>
                    <option value="<%= hotel.getId() %>">
                        <%= hotel.getName() %> - <%= hotel.getVille() %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
                <div class="info">* Les clients sont déposés à leur hôtel</div>
            </div>

            <div class="form-group">
                <label for="nbPassager">Nombre de passagers:</label>
                <input type="number" id="nbPassager" name="nbPassager" min="1" max="100" required>
            </div>

            <div class="form-group">
                <label for="dateHeureArrivee">Date et heure d'arrivée:</label>
                <input type="datetime-local" id="dateHeureArrivee" name="dateHeureArrivee" required>
            </div>

            <input type="submit" value="Enregistrer la réservation">
        </form>

        <div class="nav-link">
            <a href="${pageContext.request.contextPath}/reservation/list">📋 Voir toutes les réservations</a>
        </div>
    </div>
</body>
</html>
