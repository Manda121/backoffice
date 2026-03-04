<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Distance" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> une Distance</title>
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
            <a href="${pageContext.request.contextPath}/distance/list" class="active">
                <span class="nav-icon">📏</span> Distances
            </a>
            <a href="${pageContext.request.contextPath}/voiture/list">
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
        <%
            boolean isEdit = "edit".equals(request.getAttribute("action"));
            Distance dist = (Distance) request.getAttribute("distance");
            List<Lieu> lieux = (List<Lieu>) request.getAttribute("lieux");
        %>
        <header class="topbar">
            <div class="page-title"><span class="title-icon">📏</span> <%= isEdit ? "Modifier la distance" : "Nouvelle distance" %></div>
            <div class="breadcrumb">Accueil / Distances / <%= isEdit ? "Modifier" : "Ajouter" %></div>
        </header>

        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2><%= isEdit ? "Modifier la distance" : "Ajouter une nouvelle distance" %></h2>
                </div>
                <div class="card-body">
                    <div class="form-container">
                        <div class="info-box">
                            ℹ️ La distance est symétrique. Si A→B est ajouté, B→A ne peut pas l'être.
                        </div>

                        <% if (request.getAttribute("error") != null) { %>
                            <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
                        <% } %>

                        <form action="${pageContext.request.contextPath}/distance/<%= isEdit ? "update" : "save" %>" method="post">
                            <% if (isEdit && dist != null) { %>
                                <input type="hidden" name="id" value="<%= dist.getId() %>">
                            <% } %>

                            <div class="form-group">
                                <label for="lieuFrom">De (lieu de départ) :</label>
                                <select id="lieuFrom" name="lieuFrom" class="form-control" required>
                                    <option value="">-- Sélectionnez un lieu --</option>
                                    <% if (lieux != null) { for (Lieu l : lieux) {
                                        boolean selected = isEdit && dist != null && dist.getLieuFrom() == l.getId(); %>
                                    <option value="<%= l.getId() %>" <%= selected ? "selected" : "" %>><%= l.getCode() %></option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="lieuTo">Vers (lieu d'arrivée) :</label>
                                <select id="lieuTo" name="lieuTo" class="form-control" required>
                                    <option value="">-- Sélectionnez un lieu --</option>
                                    <% if (lieux != null) { for (Lieu l : lieux) {
                                        boolean selected = isEdit && dist != null && dist.getLieuTo() == l.getId(); %>
                                    <option value="<%= l.getId() %>" <%= selected ? "selected" : "" %>><%= l.getCode() %></option>
                                    <% } } %>
                                </select>
                            </div>

                            <div class="form-group">
                                <label for="km">Distance (km) :</label>
                                <input type="number" id="km" name="km" class="form-control" step="0.1" min="0.1" required
                                       value="<%= (isEdit && dist != null) ? dist.getKm() : "" %>">
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-submit"><%= isEdit ? "Enregistrer les modifications" : "Ajouter la distance" %></button>
                            </div>
                        </form>

                        <a href="${pageContext.request.contextPath}/distance/list" class="form-back">← Retour à la liste des distances</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
