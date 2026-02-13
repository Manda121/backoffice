<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <%
        String action = (String) request.getAttribute("action");
        boolean isEdit = "edit".equals(action);
        String title = isEdit ? "Modifier une Voiture" : "Ajouter une Voiture";

        Voiture voiture = (Voiture) request.getAttribute("voiture");
    %>
    <title><%= title %></title>
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
        select {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
            box-sizing: border-box;
            font-size: 14px;
        }
        input[type="submit"] {
            background-color: #2196F3;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 16px;
            width: 100%;
        }
        input[type="submit"]:hover {
            background-color: #1976D2;
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
            color: #2196F3;
            text-decoration: none;
        }
        .nav-link a:hover {
            text-decoration: underline;
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
    <div class="form-container">
        <h1>🚗 <%= title %></h1>

        <%
            String error = (String) request.getAttribute("error");
            if (error != null) {
        %>
        <div class="error">⚠️ <%= error %></div>
        <%
            }
        %>

        <form action="${pageContext.request.contextPath}<%= isEdit ? "/voiture/update" : "/voiture/save" %>" method="post">

            <% if (isEdit && voiture != null) { %>
                <input type="hidden" name="id" value="<%= voiture.getId() %>">
            <% } %>

            <div class="form-group">
                <label for="marque">Marque :</label>
                <input type="text" id="marque" name="marque" required
                       value="<%= (isEdit && voiture != null) ? voiture.getMarque() : "" %>"
                       placeholder="Ex: Toyota, Renault, BMW...">
            </div>

            <div class="form-group">
                <label for="nbPlace">Nombre de places :</label>
                <input type="number" id="nbPlace" name="nbPlace" min="1" max="50" required
                       value="<%= (isEdit && voiture != null) ? voiture.getNbPlace() : "" %>">
            </div>

            <div class="form-group">
                <label for="type">Type :</label>
                <input type="text" id="type" name="type" required
                       value="<%= (isEdit && voiture != null) ? voiture.getType() : "" %>"
                       placeholder="Ex: Berline, SUV, Citadine, Monospace...">
            </div>

            <div class="form-group">
                <label for="carburant">Carburant :</label>
                <select id="carburant" name="carburant" required>
                    <option value="">-- Sélectionnez --</option>
                    <option value="d" <%= (isEdit && voiture != null && voiture.getCarburant() == 'd') ? "selected" : "" %>>
                        Diesel
                    </option>
                    <option value="e" <%= (isEdit && voiture != null && voiture.getCarburant() == 'e') ? "selected" : "" %>>
                        Essence
                    </option>
                    <option value="h" <%= (isEdit && voiture != null && voiture.getCarburant() == 'h') ? "selected" : "" %>>
                        Hybride
                    </option>
                </select>
            </div>

            <input type="submit" value="<%= isEdit ? "Modifier" : "Enregistrer" %>">
        </form>

        <div class="nav-link">
            <a href="${pageContext.request.contextPath}/voiture/list">📋 Retour à la liste des voitures</a>
        </div>
    </div>
</body>
</html>
