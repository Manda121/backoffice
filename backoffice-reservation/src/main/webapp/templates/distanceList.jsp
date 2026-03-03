<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Distance" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Gestion des Distances</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 900px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; margin-bottom: 25px; }
        .actions { text-align: right; margin-bottom: 15px; }
        .btn { padding: 9px 18px; color: white; text-decoration: none; border-radius: 4px; display: inline-block; border: none; cursor: pointer; font-size: 14px; }
        .btn-add    { background-color: #4CAF50; } .btn-add:hover    { background-color: #45a049; }
        .btn-edit   { background-color: #2196F3; padding: 5px 12px; } .btn-edit:hover   { background-color: #1976D2; }
        .btn-delete { background-color: #f44336; padding: 5px 12px; } .btn-delete:hover { background-color: #d32f2f; }
        .btn-back   { background-color: #757575; } .btn-back:hover   { background-color: #616161; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 11px 14px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #009688; color: white; }
        tr:hover { background-color: #f9f9f9; }
        .alert { padding: 12px; margin-bottom: 15px; border-radius: 4px; }
        .alert-success { background: #e8f5e9; color: #2e7d32; border: 1px solid #a5d6a7; }
        .alert-error   { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; }
        .info-box { background: #e3f2fd; border: 1px solid #90caf9; border-radius: 4px; padding: 10px 14px; margin-bottom: 15px; font-size: 13px; color: #1565c0; }
        .nav-links { margin-top: 20px; }
        .nav-links a { margin-right: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>📏 Gestion des Distances</h1>

    <div class="info-box">
        ℹ️ Contrainte : si la distance <strong>A → B</strong> existe, la distance <strong>B → A</strong> ne peut pas être ajoutée (symétrie).
    </div>

    <% if (request.getAttribute("success") != null) { %>
        <div class="alert alert-success"><%= request.getAttribute("success") %></div>
    <% } %>
    <% if (request.getAttribute("error") != null) { %>
        <div class="alert alert-error"><%= request.getAttribute("error") %></div>
    <% } %>

    <div class="actions">
        <a href="${pageContext.request.contextPath}/distance/form" class="btn btn-add">+ Ajouter une distance</a>
    </div>

    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>De</th>
                <th>Vers</th>
                <th>Distance (km)</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
        <%
            List<Distance> distances = (List<Distance>) request.getAttribute("distances");
            if (distances != null && !distances.isEmpty()) {
                for (Distance d : distances) {
        %>
            <tr>
                <td><%= d.getId() %></td>
                <td><strong><%= d.getLieuFromCode() %></strong></td>
                <td><strong><%= d.getLieuToCode() %></strong></td>
                <td><%= d.getKm() %> km</td>
                <td>
                    <a href="${pageContext.request.contextPath}/distance/edit?id=<%= d.getId() %>" class="btn btn-edit">Modifier</a>
                    <form action="${pageContext.request.contextPath}/distance/delete" method="post" style="display:inline"
                          onsubmit="return confirm('Supprimer cette distance ?')">
                        <input type="hidden" name="id" value="<%= d.getId() %>">
                        <button type="submit" class="btn btn-delete">Supprimer</button>
                    </form>
                </td>
            </tr>
        <% } } else { %>
            <tr><td colspan="5" style="text-align:center; color:#999;">Aucune distance enregistrée.</td></tr>
        <% } %>
        </tbody>
    </table>

    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/lieu/list" class="btn btn-back">📍 Lieux</a>
        <a href="${pageContext.request.contextPath}/parametre/list" class="btn btn-back">⚙ Paramètres</a>
        <a href="${pageContext.request.contextPath}/planning/form" class="btn" style="background:#3f51b5">📊 Planning</a>
    </div>
</div>
</body>
</html>
