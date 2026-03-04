<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.Hotel" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nouvelle Réservation</title>
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
            <a href="${pageContext.request.contextPath}/reservation/form" class="active">
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
            <div class="page-title"><span class="title-icon">📝</span> Nouvelle Réservation</div>
            <div class="breadcrumb">Accueil / Réservations / Nouvelle</div>
        </header>

        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2>Formulaire de réservation</h2>
                </div>
                <div class="card-body">
                    <div class="form-container">
                        <form action="${pageContext.request.contextPath}/reservation/save" method="post">
                            <div class="form-group">
                                <label for="idClient">ID Client :</label>
                                <input type="text" id="idClient" name="idClient" class="form-control" maxlength="4" required pattern="[A-Za-z0-9]{4}">
                                <div class="form-info">* Exactement 4 caractères alphanumériques</div>
                            </div>

                            <div class="form-group">
                                <label>Lieu de départ :</label>
                                <%
                                    Lieu airport = (Lieu) request.getAttribute("airport");
                                %>
                                <input type="text" class="form-control" value="✈ <%= airport != null ? airport.getCode() : "Aéroport" %> (départ fixe)" readonly>
                                <div class="form-info">* Le véhicule part toujours depuis l'aéroport</div>
                            </div>

                            <div class="form-group">
                                <label for="idHotel">Hôtel (lieu d'arrivée) :</label>
                                <select id="idHotel" name="idHotel" class="form-control" required>
                                    <option value="">-- Sélectionnez un hôtel --</option>
                                    <%
                                        List<Hotel> hotels = (List<Hotel>) request.getAttribute("hotels");
                                        if (hotels != null) {
                                            for (Hotel hotel : hotels) {
                                    %>
                                    <option value="<%= hotel.getId() %>">
                                        <%= hotel.getName() %> - <%= hotel.getVille() %>
                                    </option>
                                    <%
                                            }
                                        }
                                    %>
                                </select>
                                <div class="form-info">* Les clients sont déposés à leur hôtel</div>
                            </div>

                            <div class="form-group">
                                <label for="nbPassager">Nombre de passagers :</label>
                                <input type="number" id="nbPassager" name="nbPassager" class="form-control" min="1" max="100" required>
                            </div>

                            <div class="form-group">
                                <label for="dateHeureArrivee">Date et heure d'arrivée :</label>
                                <input type="datetime-local" id="dateHeureArrivee" name="dateHeureArrivee" class="form-control" required>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-submit">Enregistrer la réservation</button>
                            </div>
                        </form>

                        <a href="${pageContext.request.contextPath}/reservation/list" class="form-back">📋 Voir toutes les réservations</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
