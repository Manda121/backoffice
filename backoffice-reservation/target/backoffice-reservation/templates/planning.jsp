<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="models.PlanningEntry" %>
<%@ page import="models.Reservation" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Planning des Véhicules</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/theme.css">
    <style>
        .itin-row td { background:#f9fbe7; border-bottom:2px solid #e0e0e0; padding:6px 18px 10px; }
        .itin-label  { font-weight:bold; color:#5c6bc0; margin-right:8px; font-size:13px; }
        .itin-node   { display:inline-block; padding:2px 9px; border-radius:12px;
                       font-weight:bold; font-size:12px; margin:0 1px; }
        .itin-airport { background:#e3f2fd; color:#1565c0; }
        .itin-hotel   { background:#f3e5f5; color:#4527a0; }
        .itin-arrow   { color:#9e9e9e; font-size:12px; margin:0 3px; }
    </style>
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
            <a href="${pageContext.request.contextPath}/planning/form" class="active">
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
            <div class="page-title"><span class="title-icon">📊</span> Planning des Véhicules</div>
            <div class="breadcrumb">Accueil / Planning</div>
        </header>

        <div class="page-content">
            <!-- Date picker card -->
            <div class="card">
                <div class="card-header">
                    <h2>🗓 Sélectionner une date</h2>
                </div>
                <div class="card-body">
                    <form action="${pageContext.request.contextPath}/planning/result" method="get">
                        <div class="form-inline">
                            <div class="form-group">
                                <label for="date">Date de départ :</label>
                                <input type="date" id="date" name="date" class="form-control"
                                       value="${not empty date ? date : ''}">
                            </div>
                            <button type="submit" class="btn btn-primary">🔍 Générer le planning</button>
                        </div>
                    </form>
                </div>
            </div>

            <!-- Error -->
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
            <% } %>

            <%
                List<PlanningEntry> planning = (List<PlanningEntry>) request.getAttribute("planning");
                String date = (String) request.getAttribute("date");
                Integer totalResas = (Integer) request.getAttribute("totalReservations");
                Integer tempsAttente = (Integer) request.getAttribute("tempsAttente");
                Double vitesse = (Double) request.getAttribute("vitesse");

                if (planning != null) {
            %>

            <!-- Summary -->
            <div class="summary-bar">
                <div class="summary-item">
                    <div class="val"><%= totalResas != null ? totalResas : 0 %></div>
                    <div class="lbl">Réservations du jour</div>
                </div>
                <div class="summary-item">
                    <div class="val"><%= planning.size() %></div>
                    <div class="lbl">Départs planifiés</div>
                </div>
                <div class="summary-item">
                    <div class="val"><%= tempsAttente != null ? tempsAttente : 30 %> min</div>
                    <div class="lbl">Temps d'attente</div>
                </div>
                <div class="summary-item">
                    <div class="val"><%= vitesse != null ? vitesse.intValue() : 30 %> km/h</div>
                    <div class="lbl">Vitesse moyenne</div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h2>🚐 Planning du <%= date %></h2>
                </div>
                <div class="card-body">
                    <% if (planning.isEmpty()) { %>
                        <div class="empty-state">
                            <div class="icon">🗓</div>
                            <p>Aucune réservation pour ce jour.</p>
                        </div>
                    <% } else { %>

                    <div class="table-container">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th>Véhicule</th>
                                    <th>Réservations</th>
                                    <th>Départ (✈ Aéroport)</th>
                                    <th>Arrivée hôtel / Retour ✈</th>
                                    <th>Passagers / Capacité</th>
                                    <th>Distance</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (PlanningEntry entry : planning) {
                                   Voiture v = entry.getVoiture();
                                   String carbClass = v.getCarburant() == 'd' ? "badge-diesel" : (v.getCarburant() == 'e' ? "badge-essence" : "badge-hybride");
                                   String carbLabel = v.getCarburant() == 'd' ? "Diesel" : (v.getCarburant() == 'e' ? "Essence" : "Hybride");
                                   int passTotal = entry.getTotalPassagers();
                                   int capacity  = v.getNbPlace();
                                   int pct = capacity > 0 ? Math.min(100, 100 * passTotal / capacity) : 0;
                            %>
                            <tr>
                                <td>
                                    <div class="vehicle-badge">V<%= v.getId() %> — <%= v.getMarque() %><%= v.getMatricule() != null ? " (" + v.getMatricule() + ")" : "" %></div><br>
                                    <span class="badge <%= carbClass %>" style="margin-top:4px;">
                                        <%= carbLabel %> &bull; <%= capacity %> places
                                    </span>
                                </td>
                                <td>
                                    <% for (Reservation r : entry.getReservations()) { %>
                                        <span class="res-tag">R<%= r.getId() %></span>
                                    <% } %>
                                    <div class="res-detail">
                                    <% for (Reservation r : entry.getReservations()) { %>
                                        R<%= r.getId() %> : <%= r.getNbPassager() %> passagers
                                        <% if (r.getLieuCode() != null) { %>&rarr; <%= r.getLieuCode() %><% } %><br>
                                    <% } %>
                                    </div>
                                </td>
                                <td><span class="time-depart">✈ Départ : <%= entry.getDepartureFormatted() %></span></td>
                                <td>
                                    <span class="time-arrivee">🏨 Hôtel : <%= entry.getArrivalFormatted() %></span><br>
                                    <span style="color:var(--accent); font-weight:bold; font-size:15px;">✈ Aéroport : <%= entry.getReturnToAirportFormatted() %></span>
                                    <div style="font-size:11px; color:var(--text-muted); margin-top:3px;">Disponible à partir de <%= entry.getReturnToAirportFormatted() %></div>
                                </td>
                                <td>
                                    <strong><%= String.format("%.0f", entry.getTotalKm()) %> km</strong>
                                    <div style="font-size:11px; color:var(--text-muted);">trajet complet</div>
                                </td>
                                <td>
                                    <%= passTotal %> / <%= capacity %> places
                                    <div class="cap-bar-wrap">
                                        <div class="cap-bar" style="width:<%= pct %>%;"></div>
                                    </div>
                                </td>
                            </tr>
                            <tr class="itin-row">
                                <td colspan="6">
                                    <span class="itin-label">&#x1F5FA; Itin&eacute;raire :</span>
                                    <%
                                        java.util.List<String[]> itinSteps = entry.getItinerarySteps();
                                        for (int si = 0; si < itinSteps.size(); si++) {
                                            String[] step = itinSteps.get(si);
                                            boolean isEndpoint = (si == 0 || si == itinSteps.size() - 1);
                                    %>
                                    <% if (si > 0) { %>
                                        <span class="itin-arrow">&rarr; (<%= step[1] %>) &rarr;</span>
                                    <% } %>
                                    <span class="itin-node <%= isEndpoint ? "itin-airport" : "itin-hotel" %>">
                                        <%= isEndpoint ? "&#x2708;" : "&#x1F3E8;" %> <%= step[0] %>
                                    </span>
                                    <% } %>
                                </td>
                            </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>

                    <% } %>
                </div>
            </div>

            <%
                List<Reservation> unassigned = (List<Reservation>) request.getAttribute("unassigned");
                if (unassigned != null && !unassigned.isEmpty()) {
                    SimpleDateFormat sdfU = new SimpleDateFormat("HH'h'mm");
            %>
            <div class="card card-warning">
                <div class="card-header">
                    <h2>⚠️ Réservations non assignées (<%= unassigned.size() %>)</h2>
                </div>
                <div class="card-body">
                    <div class="table-container">
                        <table class="table">
                            <thead>
                                <tr>
                                    <th style="background-color:var(--warning);">ID</th>
                                    <th style="background-color:var(--warning);">Client</th>
                                    <th style="background-color:var(--warning);">Hôtel de destination</th>
                                    <th style="background-color:var(--warning);">Passagers</th>
                                    <th style="background-color:var(--warning);">Heure prévue</th>
                                    <th style="background-color:var(--warning);">Raison</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (Reservation r : unassigned) { %>
                                <tr style="background-color:var(--warning-light);">
                                    <td><strong style="color:var(--warning);">R<%= r.getId() %></strong></td>
                                    <td><%= r.getIdClient() %></td>
                                    <td><%= r.getLieuCode() != null ? r.getLieuCode() : "Hôtel #" + r.getIdHotel() %></td>
                                    <td><%= r.getNbPassager() %> passager(s)</td>
                                    <td><%= sdfU.format(r.getDateHeureArrivee()) %></td>
                                    <td style="color:var(--danger);"><%= r.getUnassignedReason() != null ? r.getUnassignedReason() : "Non assigné" %></td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <% } %>

            <% } %>
        </div>
    </div>
</div>
</body>
</html>
