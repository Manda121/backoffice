<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Parametre" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Paramètres du Système</title>
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
        th { background-color: #ff5722; color: white; }
        tr:hover { background-color: #f9f9f9; }
        .alert { padding: 12px; margin-bottom: 15px; border-radius: 4px; }
        .alert-success { background: #e8f5e9; color: #2e7d32; border: 1px solid #a5d6a7; }
        .alert-error   { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; }
        .info-box { background: #fff8e1; border: 1px solid #ffe082; border-radius: 4px; padding: 10px 14px; margin-bottom: 15px; font-size: 13px; color: #f57f17; }
        code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
        .nav-links { margin-top: 20px; }
        .nav-links a { margin-right: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h1>⚙️ Paramètres du Système</h1>

    <div class="info-box">
        Paramètres clés : <code>vitesse_moyenne</code> (km/h) &nbsp;|&nbsp; <code>temps_attente</code> (minutes avant le départ)
    </div>

    <% if (request.getAttribute("success") != null) { %>
        <div class="alert alert-success"><%= request.getAttribute("success") %></div>
    <% } %>
    <% if (request.getAttribute("error") != null) { %>
        <div class="alert alert-error"><%= request.getAttribute("error") %></div>
    <% } %>

    <div class="actions">
        <a href="${pageContext.request.contextPath}/parametre/form" class="btn btn-add">+ Ajouter un paramètre</a>
    </div>

    <table>
        <thead>
            <tr>
                <th>#</th>
                <th>Code</th>
                <th>Valeur</th>
                <th>Description</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
        <%
            List<Parametre> parametres = (List<Parametre>) request.getAttribute("parametres");
            if (parametres != null && !parametres.isEmpty()) {
                for (Parametre p : parametres) {
        %>
            <tr>
                <td><%= p.getId() %></td>
                <td><code><%= p.getCode() %></code></td>
                <td><strong><%= p.getValeur() %></strong></td>
                <td><%= p.getDescription() != null ? p.getDescription() : "" %></td>
                <td>
                    <a href="${pageContext.request.contextPath}/parametre/edit?id=<%= p.getId() %>" class="btn btn-edit">Modifier</a>
                    <form action="${pageContext.request.contextPath}/parametre/delete" method="post" style="display:inline"
                          onsubmit="return confirm('Supprimer ce paramètre ?')">
                        <input type="hidden" name="id" value="<%= p.getId() %>">
                        <button type="submit" class="btn btn-delete">Supprimer</button>
                    </form>
                </td>
            </tr>
        <% } } else { %>
            <tr><td colspan="5" style="text-align:center; color:#999;">Aucun paramètre enregistré.</td></tr>
        <% } %>
        </tbody>
    </table>

    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/lieu/list" class="btn btn-back">📍 Lieux</a>
        <a href="${pageContext.request.contextPath}/distance/list" class="btn btn-back">📏 Distances</a>
        <a href="${pageContext.request.contextPath}/planning/form" class="btn" style="background:#3f51b5">📊 Planning</a>
    </div>
</div>
</body>
</html>
