<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Parametre" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Paramètres du Système</title>
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
            <a href="${pageContext.request.contextPath}/parametre/list" class="active">
                <span class="nav-icon">⚙️</span> Paramètres
            </a>
        </nav>
        <div class="sidebar-footer">© 2026 Réservation</div>
    </aside>

    <!-- MAIN -->
    <div class="main-content">
        <header class="topbar">
            <div class="page-title"><span class="title-icon">⚙️</span> Paramètres du Système</div>
            <div class="breadcrumb">Accueil / Paramètres</div>
        </header>

        <div class="page-content">
            <div class="info-box">
                Paramètres clés : <code>vitesse_moyenne</code> (km/h) &nbsp;|&nbsp; <code>temps_attente</code> (minutes avant le départ)
            </div>

            <% if (request.getAttribute("success") != null) { %>
                <div class="alert alert-success">✅ <%= request.getAttribute("success") %></div>
            <% } %>
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
            <% } %>

            <div class="card">
                <div class="card-header">
                    <h2>Liste des paramètres</h2>
                    <a href="${pageContext.request.contextPath}/parametre/form" class="btn btn-success">+ Ajouter un paramètre</a>
                </div>
                <div class="card-body">
                    <div class="table-container">
                        <table class="table">
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
                                        <div class="action-cell">
                                            <a href="${pageContext.request.contextPath}/parametre/edit?id=<%= p.getId() %>" class="btn btn-primary btn-sm">Modifier</a>
                                            <form action="${pageContext.request.contextPath}/parametre/delete" method="post" style="display:inline"
                                                  onsubmit="return confirm('Supprimer ce paramètre ?')">
                                                <input type="hidden" name="id" value="<%= p.getId() %>">
                                                <button type="submit" class="btn btn-danger btn-sm">Supprimer</button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            <% } } else { %>
                                <tr><td colspan="5" class="empty-state">Aucun paramètre enregistré.</td></tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
