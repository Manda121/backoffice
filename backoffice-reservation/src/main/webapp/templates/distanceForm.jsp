<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Distance" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> une Distance</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 520px; margin: 50px auto; padding: 20px; background-color: #f5f5f5; }
        .form-container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .form-group { margin-bottom: 18px; }
        label { display: block; margin-bottom: 5px; color: #555; font-weight: bold; }
        select, input[type="number"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; box-sizing: border-box; font-size: 14px; }
        input[type="submit"] { background-color: #009688; color: white; padding: 11px 25px; border: none; border-radius: 4px; cursor: pointer; font-size: 15px; width: 100%; }
        input[type="submit"]:hover { background-color: #00796b; }
        .btn-back { display: block; text-align: center; margin-top: 12px; color: #757575; text-decoration: none; }
        .alert-error { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; padding: 10px; border-radius: 4px; margin-bottom: 15px; }
        .info-box { background: #e3f2fd; border: 1px solid #90caf9; border-radius: 4px; padding: 9px 13px; margin-bottom: 15px; font-size: 12px; color: #1565c0; }
    </style>
</head>
<body>
<div class="form-container">
    <%
        boolean isEdit = "edit".equals(request.getAttribute("action"));
        Distance dist = (Distance) request.getAttribute("distance");
        List<Lieu> lieux = (List<Lieu>) request.getAttribute("lieux");
    %>
    <h1>📏 <%= isEdit ? "Modifier la distance" : "Nouvelle distance" %></h1>

    <div class="info-box">
        ℹ️ La distance est symétrique. Si A→B est ajouté, B→A ne peut pas l'être.
    </div>

    <% if (request.getAttribute("error") != null) { %>
        <div class="alert-error"><%= request.getAttribute("error") %></div>
    <% } %>

    <form action="${pageContext.request.contextPath}/distance/<%= isEdit ? "update" : "save" %>" method="post">
        <% if (isEdit && dist != null) { %>
            <input type="hidden" name="id" value="<%= dist.getId() %>">
        <% } %>

        <div class="form-group">
            <label for="lieuFrom">De (lieu de départ) :</label>
            <select id="lieuFrom" name="lieuFrom" required>
                <option value="">-- Sélectionnez un lieu --</option>
                <% if (lieux != null) { for (Lieu l : lieux) {
                    boolean selected = isEdit && dist != null && dist.getLieuFrom() == l.getId(); %>
                <option value="<%= l.getId() %>" <%= selected ? "selected" : "" %>><%= l.getCode() %></option>
                <% } } %>
            </select>
        </div>

        <div class="form-group">
            <label for="lieuTo">Vers (lieu d'arrivée) :</label>
            <select id="lieuTo" name="lieuTo" required>
                <option value="">-- Sélectionnez un lieu --</option>
                <% if (lieux != null) { for (Lieu l : lieux) {
                    boolean selected = isEdit && dist != null && dist.getLieuTo() == l.getId(); %>
                <option value="<%= l.getId() %>" <%= selected ? "selected" : "" %>><%= l.getCode() %></option>
                <% } } %>
            </select>
        </div>

        <div class="form-group">
            <label for="km">Distance (km) :</label>
            <input type="number" id="km" name="km" step="0.1" min="0.1" required
                   value="<%= (isEdit && dist != null) ? dist.getKm() : "" %>">
        </div>

        <div class="form-group">
            <input type="submit" value="<%= isEdit ? "Enregistrer les modifications" : "Ajouter la distance" %>">
        </div>
    </form>

    <a href="${pageContext.request.contextPath}/distance/list" class="btn-back">← Retour à la liste des distances</a>
</div>
</body>
</html>
