<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<%@ page import="models.PlanningEntry" %>
<%@ page import="models.Reservation" %>
<%@ page import="models.Voiture" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Planning des Véhicules</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f0f4f8; }
        .container { max-width: 1100px; margin: 0 auto; }

        /* Header */
        .page-header {
            background: linear-gradient(135deg, #3f51b5, #283593);
            color: white; padding: 28px 30px; border-radius: 10px;
            margin-bottom: 25px; text-align: center;
        }
        .page-header h1 { margin: 0 0 8px; font-size: 26px; }
        .page-header p  { margin: 0; opacity: 0.85; }

        /* Card */
        .card { background: white; padding: 24px; border-radius: 8px; box-shadow: 0 2px 6px rgba(0,0,0,0.08); margin-bottom: 22px; }
        .card h2 { margin-top: 0; color: #3f51b5; font-size: 18px; }

        /* Form */
        .form-inline { display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap; }
        .form-inline .form-group { display: flex; flex-direction: column; }
        .form-inline label { font-size: 13px; color: #555; margin-bottom: 4px; font-weight: bold; }
        .form-inline input[type="date"] {
            padding: 10px 14px; border: 1px solid #ddd; border-radius: 4px; font-size: 15px;
        }
        .btn-compute {
            padding: 10px 24px; background-color: #3f51b5; color: white;
            border: none; border-radius: 4px; cursor: pointer; font-size: 15px;
        }
        .btn-compute:hover { background-color: #303f9f; }

        /* Alert */
        .alert { padding: 12px 16px; margin-bottom: 18px; border-radius: 4px; }
        .alert-error   { background: #ffebee; color: #c62828; border: 1px solid #ef9a9a; }
        .alert-info    { background: #e3f2fd; color: #1565c0; border: 1px solid #90caf9; }

        /* Summary bar */
        .summary-bar {
            display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 20px;
        }
        .summary-item {
            background: #f5f5f5; border-radius: 6px; padding: 10px 18px; flex: 1; min-width: 150px;
            text-align: center;
        }
        .summary-item .val { font-size: 24px; font-weight: bold; color: #3f51b5; }
        .summary-item .lbl { font-size: 12px; color: #666; margin-top: 2px; }

        /* Planning table */
        .planning-table { width: 100%; border-collapse: collapse; }
        .planning-table th {
            background-color: #3f51b5; color: white; padding: 12px 14px; text-align: left;
        }
        .planning-table td {
            padding: 14px; border-bottom: 1px solid #e0e0e0; vertical-align: top;
        }
        .planning-table tr:hover td { background-color: #f5f7ff; }

        /* Vehicle badge */
        .vehicle-badge {
            display: inline-block; background: #e8eaf6; color: #3f51b5;
            border-radius: 20px; padding: 4px 14px; font-weight: bold; font-size: 14px;
        }
        .carb-d { background: #e8f5e9; color: #2e7d32; }
        .carb-e { background: #fff8e1; color: #f57f17; }
        .carb-h { background: #e3f2fd; color: #1565c0; }

        /* Time badges */
        .time-depart { color: #1b5e20; font-weight: bold; font-size: 16px; }
        .time-arrivee { color: #b71c1c; font-weight: bold; font-size: 16px; }

        /* Reservation tags */
        .res-tag {
            display: inline-block; background: #ede7f6; color: #4527a0;
            border-radius: 4px; padding: 3px 10px; margin: 2px 3px;
            font-size: 13px;
        }
        .res-detail { font-size: 12px; color: #777; margin-top: 3px; }

        /* Capacity bar */
        .cap-bar-wrap { background: #e0e0e0; border-radius: 4px; height: 8px; margin-top: 5px; overflow: hidden; }
        .cap-bar { height: 100%; border-radius: 4px; background: #4caf50; }

        /* Empty state */
        .empty-state { text-align: center; padding: 40px; color: #999; }
        .empty-state .icon { font-size: 52px; }

        /* Nav */
        .nav-links { margin-top: 20px; }
        .nav-links a { display: inline-block; margin-right: 10px; margin-bottom: 6px;
                       padding: 8px 16px; background: #757575; color: white;
                       border-radius: 4px; text-decoration: none; font-size: 13px; }
        .nav-links a:hover { background: #616161; }
    </style>
</head>
<body>
<div class="container">

    <!-- Header -->
    <div class="page-header">
        <h1>📊 Planning des Véhicules</h1>
        <p>Visualisez l'assignation des réservations aux véhicules pour une date donnée</p>
    </div>

    <!-- Formulaire de sélection de date -->
    <div class="card">
        <h2>🗓 Sélectionner une date</h2>
        <form action="${pageContext.request.contextPath}/planning/result" method="get">
            <div class="form-inline">
                <div class="form-group">
                    <label for="date">Date de départ :</label>
                    <input type="date" id="date" name="date"
                           value="${not empty date ? date : ''}">
                </div>
                <button type="submit" class="btn-compute">🔍 Générer le planning</button>
            </div>
        </form>
    </div>

    <!-- Erreur -->
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

    <!-- Résumé -->
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
        <h2>🚐 Planning du <%= date %></h2>

        <% if (planning.isEmpty()) { %>
            <div class="empty-state">
                <div class="icon">🗓</div>
                <p>Aucune réservation avec lieu de destination pour ce jour.</p>
                <p style="font-size:13px; color:#bbb;">Vérifiez que les réservations ont un lieu de destination assigné.</p>
            </div>
        <% } else { %>

        <table class="planning-table">
            <thead>
                <tr>
                    <th>Véhicule</th>
                    <th>Réservations</th>
                    <th>Départ</th>
                    <th>Arrivée</th>
                    <th>Passagers / Capacité</th>
                </tr>
            </thead>
            <tbody>
            <% for (PlanningEntry entry : planning) {
                   Voiture v = entry.getVoiture();
                   String carbClass = v.getCarburant() == 'd' ? "carb-d" : (v.getCarburant() == 'e' ? "carb-e" : "carb-h");
                   String carbLabel = v.getCarburant() == 'd' ? "Diesel" : (v.getCarburant() == 'e' ? "Essence" : "Hybride");
                   int passTotal = entry.getTotalPassagers();
                   int capacity  = v.getNbPlace();
                   int pct = capacity > 0 ? Math.min(100, 100 * passTotal / capacity) : 0;
            %>
            <tr>
                <td>
                    <div class="vehicle-badge">V<%= v.getId() %> — <%= v.getMarque() %><%= v.getMatricule() != null ? " (" + v.getMatricule() + ")" : "" %></div><br>
                    <span class="<%= carbClass %>" style="font-size:12px; padding:2px 8px; border-radius:10px; display:inline-block; margin-top:4px;">
                        <%= carbLabel %> &bull; <%= capacity %> places
                    </span>
                </td>
                <td>
                    <% for (Reservation r : entry.getReservations()) { %>
                        <span class="res-tag">R<%= r.getId() %></span>
                    <% } %>
                    <div class="res-detail">
                    <% for (Reservation r : entry.getReservations()) { %>
                        R<%= r.getId() %> : <%= r.getNbPassager() %> pax
                        <% if (r.getLieuCode() != null) { %>&rarr; <%= r.getLieuCode() %><% } %><br>
                    <% } %>
                    </div>
                </td>
                <td><span class="time-depart">⬆ <%= entry.getDepartureFormatted() %></span></td>
                <td><span class="time-arrivee">⬇ <%= entry.getArrivalFormatted() %></span></td>
                <td>
                    <%= passTotal %> / <%= capacity %> places
                    <div class="cap-bar-wrap">
                        <div class="cap-bar" style="width:<%= pct %>%;"></div>
                    </div>
                </td>
            </tr>
            <% } %>
            </tbody>
        </table>

        <% } %>
    </div>

    <% } %>

    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/reservation/form">📝 Nouvelle réservation</a>
        <a href="${pageContext.request.contextPath}/reservation/list">📋 Réservations</a>
        <a href="${pageContext.request.contextPath}/voiture/list">🚐 Voitures</a>
        <a href="${pageContext.request.contextPath}/lieu/list">📍 Lieux</a>
        <a href="${pageContext.request.contextPath}/distance/list">📏 Distances</a>
        <a href="${pageContext.request.contextPath}/parametre/list">⚙ Paramètres</a>
    </div>

</div>
</body>
</html>
