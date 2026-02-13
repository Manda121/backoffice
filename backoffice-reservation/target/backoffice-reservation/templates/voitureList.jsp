<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Liste des Voitures</title>
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
            color: white;
            text-decoration: none;
            border-radius: 4px;
            display: inline-block;
            border: none;
            cursor: pointer;
            font-size: 14px;
        }
        .btn-add {
            background-color: #4CAF50;
        }
        .btn-add:hover {
            background-color: #45a049;
        }
        .btn-edit {
            background-color: #2196F3;
            padding: 6px 14px;
            font-size: 13px;
        }
        .btn-edit:hover {
            background-color: #1976D2;
        }
        .btn-delete {
            background-color: #f44336;
            padding: 6px 14px;
            font-size: 13px;
        }
        .btn-delete:hover {
            background-color: #d32f2f;
        }
        .btn-back {
            background-color: #757575;
        }
        .btn-back:hover {
            background-color: #616161;
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
            background-color: #2196F3;
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
        .success {
            background-color: #e8f5e9;
            color: #2e7d32;
            padding: 15px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .action-cell {
            white-space: nowrap;
        }
        .action-cell a {
            margin-right: 5px;
        }
        .nav-links {
            text-align: center;
            margin-top: 20px;
        }
        .nav-links a {
            color: #2196F3;
            text-decoration: none;
            margin: 0 10px;
        }
        .nav-links a:hover {
            text-decoration: underline;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚗 Liste des Voitures</h1>

        <div class="actions">
            <a href="${pageContext.request.contextPath}/voiture/form" class="btn btn-add">
                ➕ Ajouter une voiture
            </a>
        </div>

        <%
            String error = (String) request.getAttribute("error");
            if (error != null) {
        %>
        <div class="error">⚠️ <%= error %></div>
        <%
            }

            String success = (String) request.getAttribute("success");
            if (success != null) {
        %>
        <div class="success">✅ <%= success %></div>
        <%
            }

            List<Voiture> voitures = (List<Voiture>) request.getAttribute("voitures");
            if (voitures != null && !voitures.isEmpty()) {
        %>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Marque</th>
                    <th>Nb Places</th>
                    <th>Type</th>
                    <th>Carburant</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    for (Voiture voiture : voitures) {
                %>
                <tr>
                    <td><%= voiture.getId() %></td>
                    <td><%= voiture.getMarque() %></td>
                    <td><%= voiture.getNbPlace() %></td>
                    <td><%= voiture.getType() %></td>
                    <td><%= voiture.getCarburantLabel() %></td>
                    <td class="action-cell">
                        <a href="${pageContext.request.contextPath}/voiture/edit?id=<%= voiture.getId() %>" class="btn btn-edit">
                            ✏️ Modifier
                        </a>
                        <a href="${pageContext.request.contextPath}/voiture/delete?id=<%= voiture.getId() %>" class="btn btn-delete"
                           onclick="return confirm('Êtes-vous sûr de vouloir supprimer cette voiture ?');">
                            🗑️ Supprimer
                        </a>
                    </td>
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
            Aucune voiture enregistrée pour le moment.
        </div>
        <%
            }
        %>

        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/reservation/list">📋 Réservations</a>
            <a href="${pageContext.request.contextPath}/reservation/form">📝 Nouvelle réservation</a>
        </div>
    </div>
</body>
</html>
