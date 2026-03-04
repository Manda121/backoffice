<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Liste des Voitures</title>
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
            <div class="page-title"><span class="title-icon">🚐</span> Liste des Voitures</div>
            <div class="breadcrumb">Accueil / Voitures</div>
        </header>

        <div class="page-content">
            <%
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
            <div class="alert alert-error">⚠️ <%= error %></div>
            <%
                }
                String success = (String) request.getAttribute("success");
                if (success != null) {
            %>
            <div class="alert alert-success">✅ <%= success %></div>
            <%
                }
            %>

            <div class="card">
                <div class="card-header">
                    <h2>Voitures enregistrées</h2>
                    <a href="${pageContext.request.contextPath}/voiture/form" class="btn btn-success">➕ Ajouter une voiture</a>
                </div>
                <div class="card-body">
                    <%
                        List<Voiture> voitures = (List<Voiture>) request.getAttribute("voitures");
                        if (voitures != null && !voitures.isEmpty()) {
                    %>
                    <div class="table-container">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Marque</th>
                                    <th>Matricule</th>
                                    <th>Nb Places</th>
                                    <th>Type</th>
                                    <th>Carburant</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Voiture voiture : voitures) { %>
                                <tr>
                                    <td><%= voiture.getId() %></td>
                                    <td><strong><%= voiture.getMarque() %></strong></td>
                                    <td><%= voiture.getMatricule() != null ? voiture.getMatricule() : "-" %></td>
                                    <td><%= voiture.getNbPlace() %></td>
                                    <td><%= voiture.getType() %></td>
                                    <td>
                                        <% char carb = voiture.getCarburant();
                                           String carbClass = carb == 'd' ? "badge-diesel" : (carb == 'e' ? "badge-essence" : "badge-hybride");
                                        %>
                                        <span class="badge <%= carbClass %>"><%= voiture.getCarburantLabel() %></span>
                                    </td>
                                    <td>
                                        <div class="action-cell">
                                            <a href="${pageContext.request.contextPath}/voiture/edit?id=<%= voiture.getId() %>" class="btn btn-primary btn-sm">✏️ Modifier</a>
                                            <a href="${pageContext.request.contextPath}/voiture/delete?id=<%= voiture.getId() %>" class="btn btn-danger btn-sm"
                                               onclick="return confirm('Êtes-vous sûr de vouloir supprimer cette voiture ?');">🗑️ Supprimer</a>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                    <div class="empty-state">
                        <div class="icon">🚗</div>
                        <p>Aucune voiture enregistrée pour le moment.</p>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
