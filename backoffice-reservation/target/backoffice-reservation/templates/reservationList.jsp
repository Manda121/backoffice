<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Reservation" %>
<%@ page import="java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Liste des Réservations</title>
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
            <a href="${pageContext.request.contextPath}/reservation/list" class="active">
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
            <div class="page-title"><span class="title-icon">📋</span> Liste des Réservations</div>
            <div class="breadcrumb">Accueil / Réservations</div>
        </header>

        <div class="page-content">
            <%
                String error = (String) request.getAttribute("error");
                if (error != null) {
            %>
            <div class="alert alert-error">❌ <%= error %></div>
            <% } %>

            <div class="card">
                <div class="card-header">
                    <h2>Réservations enregistrées</h2>
                    <a href="${pageContext.request.contextPath}/reservation/form" class="btn btn-success">➕ Nouvelle réservation</a>
                </div>
                <div class="card-body">
                    <%
                        List<Reservation> reservations = (List<Reservation>) request.getAttribute("reservations");
                        if (reservations != null && !reservations.isEmpty()) {
                            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
                    %>
                    <div class="table-container">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>ID Client</th>
                                    <th>Hôtel</th>
                                    <th>Ville</th>
                                    <th>Nb Passagers</th>
                                    <th>Date Arrivée</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Reservation reservation : reservations) { %>
                                <tr>
                                    <td><span class="badge badge-res">R<%= reservation.getId() %></span></td>
                                    <td><strong><%= reservation.getIdClient() %></strong></td>
                                    <td><%= reservation.getHotelName() %></td>
                                    <td><%= reservation.getHotelVille() %></td>
                                    <td><%= reservation.getNbPassager() %></td>
                                    <td><%= sdf.format(reservation.getDateHeureArrivee()) %></td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                    <% } else { %>
                    <div class="empty-state">
                        <div class="icon">📋</div>
                        <p>Aucune réservation enregistrée pour le moment.</p>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
