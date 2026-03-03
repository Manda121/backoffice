<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Parametre" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> un Paramètre</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 520px; margin: 50px auto; padding: 20px; background-color: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .form-group { margin-bottom: 18px; }
        label { display: block; margin-bottom: 5px; color: #555; font-weight: bold; }
        input[type="text"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; font-size: 14px; }
        input[type="submit"] { background-color: #ff5722; color: white; padding: 11px 25px; border: none; border-radius: 4px; cursor: pointer; font-size: 15px; width: 100%; }
        input[type="submit"]:hover { background-color: #e64a19; }
        .btn-back { display: block; text-align: center; margin-top: 12px; color: #757575; text-decoration: none; }
        .alert-error { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; padding: 10px; border-radius: 4px; margin-bottom: 15px; }
        .info { font-size: 12px; color: #666; margin-top: 4px; }
    </style>
</head>
<body>
<div class="form-container">
    <%
        boolean isEdit = "edit".equals(request.getAttribute("action"));
        Parametre p = (Parametre) request.getAttribute("parametre");
    %>
    <h1>⚙️ <%= isEdit ? "Modifier le paramètre" : "Nouveau paramètre" %></h1>

    <% if (request.getAttribute("error") != null) { %>
        <div class="alert-error"><%= request.getAttribute("error") %></div>
    <% } %>

    <form action="${pageContext.request.contextPath}/parametre/<%= isEdit ? "update" : "save" %>" method="post">
        <% if (isEdit && p != null) { %>
            <input type="hidden" name="id" value="<%= p.getId() %>">
        <% } %>

        <div class="form-group">
            <label for="code">Code :</label>
            <input type="text" id="code" name="code" required
                   value="<%= (isEdit && p != null) ? p.getCode() : "" %>"
                   placeholder="Ex: vitesse_moyenne, temps_attente">
            <div class="info">Identifiant unique du paramètre (sans espaces).</div>
        </div>

        <div class="form-group">
            <label for="valeur">Valeur :</label>
            <input type="text" id="valeur" name="valeur" required
                   value="<%= (isEdit && p != null) ? p.getValeur() : "" %>"
                   placeholder="Ex: 30">
        </div>

        <div class="form-group">
            <label for="description">Description :</label>
            <input type="text" id="description" name="description"
                   value="<%= (isEdit && p != null && p.getDescription() != null) ? p.getDescription() : "" %>"
                   placeholder="Description optionnelle">
        </div>

        <div class="form-group">
            <input type="submit" value="<%= isEdit ? "Enregistrer les modifications" : "Ajouter le paramètre" %>">
        </div>
    </form>

    <a href="${pageContext.request.contextPath}/parametre/list" class="btn-back">← Retour aux paramètres</a>
</div>
</body>
</html>
