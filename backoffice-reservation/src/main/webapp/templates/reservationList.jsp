<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Reservation" %>
<%@ page import="java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Liste des Réservations</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
        }
        .actions {
            text-align: right;
            margin-bottom: 20px;
        }
        .btn {
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            display: inline-block;
        }
        .btn:hover {
            background-color: #45a049;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #4CAF50;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .no-data {
            text-align: center;
            padding: 40px;
            color: #999;
            font-style: italic;
        }
        .error {
            background-color: #ffebee;
            color: #c62828;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📋 Liste des Réservations</h1>
        
        <div class="actions">
            <a href="${pageContext.request.contextPath}/reservation/form" class="btn">
                ➕ Nouvelle réservation
            </a>
        </div>

        <%
            String error = (String) request.getAttribute("error");
            if (error != null) {
        %>
        <div class="error">
            <%= error %>
        </div>
        <%
            }
            
            List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
            if (reservations != null && !reservations.isEmpty()) {
                SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>ID Client</th>
                    <th>Hôtel</th>
                    <th>Ville</th>
                    <th>Nb Passagers</th>
                    <th>Date Arrivée</th>
                </tr>
            </thead>
            <tbody>
                <%
                    for (Reservation reservation : reservations) {
                %>
                <tr>
                    <td><%= reservation.getId() %></td>
                    <td><%= reservation.getIdClient() %></td>
                    <td><%= reservation.getHotelName() %></td>
                    <td><%= reservation.getHotelVille() %></td>
                    <td><%= reservation.getNbPassager() %></td>
                    <td><%= sdf.format(reservation.getDateHeureArrivee()) %></td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>
        <%
            } else {
        %>
        <div class="no-data">
            Aucune réservation enregistrée pour le moment.
        </div>
        <%
            }
        %>
        <div style="margin-top:20px;">
            <a href="${pageContext.request.contextPath}/planning/form"
               style="padding:10px 20px; background:#3f51b5; color:white; text-decoration:none; border-radius:4px;">
                📊 Planning des véhicules
            </a>
            <a href="${pageContext.request.contextPath}/distance/list"
               style="padding:10px 20px; background:#757575; color:white; text-decoration:none; border-radius:4px; margin-left:8px;">
                📏 Distances
            </a>
        </div>
    </div>
</body>
</html>
