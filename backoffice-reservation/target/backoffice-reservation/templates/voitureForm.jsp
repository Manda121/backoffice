<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <%
        String action = (String) request.getAttribute("action");
        boolean isEdit = "edit".equals(action);
        String title = isEdit ? "Modifier une Voiture" : "Ajouter une Voiture";
        Voiture voiture = (Voiture) request.getAttribute("voiture");
    %>
    <title><%= title %></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
</head>
<body>
<div class="app-layout">
    <!-- SIDEBAR -->
    <aside class="sidebar">
        <div class="sidebar-brand">
            <h2>🚗 Réservation</h2>
            <div class="brand-sub">Back-office</div>
        </div>
        <nav class="sidebar-nav">
            <div class="nav-section">Navigation</div>
            <a href="${pageContext.request.contextPath}/lieu/list">
                <span class="nav-icon">📍</span> Lieux
            </a>
            <a href="${pageContext.request.contextPath}/distance/list">
                <span class="nav-icon">📏</span> Distances
            </a>
            <a href="${pageContext.request.contextPath}/voiture/list" class="active">
                <span class="nav-icon">🚐</span> Voitures
            </a>
            <div class="nav-section">Opérations</div>
            <a href="${pageContext.request.contextPath}/reservation/list">
                <span class="nav-icon">📋</span> Réservations
            </a>
            <a href="${pageContext.request.contextPath}/reservation/form">
                <span class="nav-icon">📝</span> Nouvelle réservation
            </a>
            <a href="${pageContext.request.contextPath}/planning/form">
                <span class="nav-icon">📊</span> Planning
            </a>
            <div class="nav-section">Configuration</div>
            <a href="${pageContext.request.contextPath}/parametre/list">
                <span class="nav-icon">⚙️</span> Paramètres
            </a>
        </nav>
        <div class="sidebar-footer">© 2026 Réservation</div>
    </aside>

    <!-- MAIN -->
    <div class="main-content">
        <header class="topbar">
            <div class="page-title"><span class="title-icon">🚐</span> <%= title %></div>
            <div class="breadcrumb">Accueil / Voitures / <%= isEdit ? "Modifier" : "Ajouter" %></div>
        </header>

        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2><%= title %></h2>
                </div>
                <div class="card-body">
                    <div class="form-container">
                        <%
                            String error = (String) request.getAttribute("error");
                            if (error != null) {
                        %>
                        <div class="alert alert-error">⚠️ <%= error %></div>
                        <% } %>

                        <form action="${pageContext.request.contextPath}<%= isEdit ? "/voiture/update" : "/voiture/save" %>" method="post">
                            <% if (isEdit && voiture != null) { %>
                                <input type="hidden" name="id" value="<%= voiture.getId() %>">
                            <% } %>

                            <div class="form-group">
                                <label for="marque">Marque :</label>
                                <input type="text" id="marque" name="marque" class="form-control" required
                                       value="<%= (isEdit && voiture != null) ? voiture.getMarque() : "" %>"
                                       placeholder="Ex: Toyota, Renault, BMW...">
                            </div>

                            <div class="form-group">
                                <label for="matricule">Matricule :</label>
                                <input type="text" id="matricule" name="matricule" class="form-control"
                                       value="<%= (isEdit && voiture != null && voiture.getMatricule() != null) ? voiture.getMatricule() : "" %>"
                                       placeholder="Ex: MAD-001, IMM-1234-TA...">
                            </div>

                            <div class="form-group">
                                <label for="nbPlace">Nombre de places :</label>
                                <input type="number" id="nbPlace" name="nbPlace" class="form-control" min="1" max="50" required
                                       value="<%= (isEdit && voiture != null) ? voiture.getNbPlace() : "" %>">
                            </div>

                            <div class="form-group">
                                <label for="type">Type :</label>
                                <input type="text" id="type" name="type" class="form-control" required
                                       value="<%= (isEdit && voiture != null) ? voiture.getType() : "" %>"
                                       placeholder="Ex: Berline, SUV, Citadine, Monospace...">
                            </div>

                            <div class="form-group">
                                <label for="carburant">Carburant :</label>
                                <select id="carburant" name="carburant" class="form-control" required>
                                    <option value="">-- Sélectionnez --</option>
                                    <option value="d" <%= (isEdit && voiture != null && voiture.getCarburant() == 'd') ? "selected" : "" %>>Diesel</option>
                                    <option value="e" <%= (isEdit && voiture != null && voiture.getCarburant() == 'e') ? "selected" : "" %>>Essence</option>
                                    <option value="h" <%= (isEdit && voiture != null && voiture.getCarburant() == 'h') ? "selected" : "" %>>Hybride</option>
                                </select>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-submit"><%= isEdit ? "Modifier" : "Enregistrer" %></button>
                            </div>
                        </form>

                        <a href="${pageContext.request.contextPath}/voiture/list" class="form-back">📋 Retour à la liste des voitures</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
