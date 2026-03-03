<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> un Lieu</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 520px; margin: 50px auto; padding: 20px; background-color: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .form-group { margin-bottom: 18px; }
        label { display: block; margin-bottom: 5px; color: #555; font-weight: bold; }
        input[type="text"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; font-size: 14px; }
        .checkbox-group { display: flex; align-items: center; gap: 8px; }
        input[type="submit"] { background-color: #4CAF50; color: white; padding: 11px 25px; border: none; border-radius: 4px; cursor: pointer; font-size: 15px; width: 100%; }
        input[type="submit"]:hover { background-color: #45a049; }
        .btn-back { display: block; text-align: center; margin-top: 12px; color: #757575; text-decoration: none; }
        .alert-error { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; padding: 10px; border-radius: 4px; margin-bottom: 15px; }
    </style>
</head>
<body>
<div class="form-container">
    <%
        boolean isEdit = "edit".equals(request.getAttribute("action"));
        Lieu lieu = (Lieu) request.getAttribute("lieu");
    %>
    <h1>📍 <%= isEdit ? "Modifier le lieu" : "Nouveau lieu" %></h1>

    <% if (request.getAttribute("error") != null) { %>
        <div class="alert-error"><%= request.getAttribute("error") %></div>
    <% } %>

    <form action="${pageContext.request.contextPath}/lieu/<%= isEdit ? "update" : "save" %>" method="post">
        <% if (isEdit && lieu != null) { %>
            <input type="hidden" name="id" value="<%= lieu.getId() %>">
        <% } %>

        <div class="form-group">
            <label for="code">Code du lieu :</label>
            <input type="text" id="code" name="code" maxlength="100" required
                   value="<%= (isEdit && lieu != null) ? lieu.getCode() : "" %>"
                   placeholder="Ex: IVATO, COLBERT, HILTON…">
        </div>

        <div class="form-group">
            <label>Type :</label>
            <div class="checkbox-group">
                <input type="checkbox" id="isAirport" name="isAirport"
                       <%= (isEdit && lieu != null && lieu.isAirport()) ? "checked" : "" %>>
                <label for="isAirport" style="font-weight: normal;">C'est l'aéroport (point de départ des véhicules)</label>
            </div>
        </div>

        <div class="form-group">
            <input type="submit" value="<%= isEdit ? "Enregistrer les modifications" : "Ajouter le lieu" %>">
        </div>
    </form>

    <a href="${pageContext.request.contextPath}/lieu/list" class="btn-back">← Retour à la liste des lieux</a>
</div>
</body>
</html>
