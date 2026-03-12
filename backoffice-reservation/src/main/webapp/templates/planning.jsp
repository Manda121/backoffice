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
        /* ── PLANNING CARDS ─────────────────────────── */
        .plan-list        { display: flex; flex-direction: column; gap: 16px; }

        .plan-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            overflow: hidden;
        }

        /* ── Header strip ───────────────────────────── */
        .plan-head {
            display: flex;
            align-items: center;
            gap: 0;
            border-bottom: 1px solid #e2e8f0;
            color: #f8fafc;
            background-color: #1e3a5f;
        }

        .plan-head-vehicle {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 14px 20px;
            min-width: 260px;
            border-right: 1px solid #e2e8f0;
        }

        .plan-num {
            width: 32px; height: 32px;
            border-radius: 50%;
            background: #1e3a5f;
            color: #fff;
            font-size: 13px;
            font-weight: 700;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }

        .plan-vehicle-name {
            font-size: 14px;
            font-weight: 700;
            color: #e2e8f0;
            line-height: 1.3;
        }

        .plan-vehicle-sub {
            font-size: 11px;
            color: #718096;
            margin-top: 2px;
        }

        .plan-head-times {
            display: flex;
            align-items: center;
            gap: 0;
            flex: 1;
            padding: 0 8px;
        }

        .plan-time-block {
            padding: 12px 16px;
            text-align: center;
        }

        .plan-time-label {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #a0aec0;
            font-weight: 600;
        }

        .plan-time-value {
            font-size: 17px;
            font-weight: 700;
            color: #e2e8f0;
            margin-top: 2px;
            font-variant-numeric: tabular-nums;
        }

        .plan-time-arrow {
            color: #cbd5e0;
            font-size: 18px;
            padding: 0 4px;
        }

        .plan-head-km {
            padding: 12px 20px;
            text-align: center;
            border-left: 1px solid #e2e8f0;
            min-width: 100px;
        }

        .plan-km-value {
            font-size: 17px;
            font-weight: 700;
            color: #e2e8f0;
        }

        .plan-km-label {
            font-size: 10px;
            color: #a0aec0;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-top: 2px;
        }

        /* ── Capacity bar in header ──────────────────── */
        .plan-head-cap {
            padding: 12px 20px;
            border-left: 1px solid #e2e8f0;
            min-width: 120px;
        }

        .cap-label {
            font-size: 12px;
            font-weight: 600;
            color: #e2e8f0;
        }

        .cap-bar-wrap {
            background: #e2e8f0;
            border-radius: 4px;
            height: 5px;
            margin-top: 6px;
            overflow: hidden;
        }

        .cap-bar {
            height: 100%;
            border-radius: 4px;
            background: #3182ce;
        }

        /* ── Fuel/type tags ────────────────────────── */
        .tag {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            margin-right: 4px;
        }
        .tag-d { background: #f0fff4; color: #276749; border: 1px solid #c6f6d5; }
        .tag-e { background: #fffaf0; color: #9c4221; border: 1px solid #feebc8; }
        .tag-h { background: #ebf8ff; color: #2b6cb0; border: 1px solid #bee3f8; }

        /* ── Reservations table ──────────────────────── */
        .plan-body {
            padding: 0;
        }

        .plan-table {
            width: 100%;
            border-collapse: collapse;
        }

        .plan-table thead tr {
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
        }

        .plan-table th {
            padding: 9px 16px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #718096;
            text-align: left;
        }

        .plan-table td {
            padding: 10px 16px;
            font-size: 13px;
            color: #2d3748;
            border-bottom: 1px solid #f0f4f8;
            vertical-align: middle;
        }

        .plan-table tbody tr:last-child td {
            border-bottom: none;
        }

        .plan-table tbody tr:hover td {
            background: #f8fafc;
        }

        .res-id {
            font-weight: 700;
            color: #1e3a5f;
            background: #ebf4ff;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 12px;
        }

        .res-arrive {
            font-weight: 600;
            color: #2d3748;
            font-variant-numeric: tabular-nums;
        }

        .pax-count {
            font-weight: 600;
            color: #4a5568;
        }

        .hotel-code {
            font-weight: 500;
            color: #4a5568;
        }

        /* ── Itinerary footer ────────────────────────── */
        .plan-foot {
            background: #f8fafc;
            border-top: 1px solid #e2e8f0;
            padding: 10px 20px;
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 0;
        }

        .itin-airport-node {
            background: #e2e8f0;
            color: #1e3a5f;
            font-weight: 700;
            padding: 3px 10px;
            border-radius: 4px;
            font-size: 12px;
        }

        .itin-hotel-node {
            background: #fff;
            color: #2d3748;
            font-weight: 600;
            padding: 3px 10px;
            border-radius: 4px;
            font-size: 12px;
            border: 1px solid #e2e8f0;
        }

        .itin-leg {
            color: #a0aec0;
            font-size: 11px;
            padding: 0 4px;
        }

        .itin-arrow-char {
            color: #cbd5e0;
            font-size: 14px;
            padding: 0 2px;
        }

        /* ── Unassigned section ──────────────────────── */
        .unassigned-card {
            border: 1px solid #fed7d7;
            border-radius: 10px;
            background: #fff;
            overflow: hidden;
            margin-top: 8px;
        }

        .unassigned-head {
            background: #fff5f5;
            padding: 14px 20px;
            border-bottom: 1px solid #fed7d7;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .unassigned-head h3 {
            font-size: 14px;
            font-weight: 700;
            color: #9b2c2c;
            margin: 0;
        }

        .unassigned-badge {
            background: #e53e3e;
            color: #fff;
            border-radius: 20px;
            padding: 1px 10px;
            font-size: 12px;
            font-weight: 700;
        }

        .unassigned-table {
            width: 100%;
            border-collapse: collapse;
        }

        .unassigned-table th {
            padding: 9px 16px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #718096;
            background: #fffafa;
            border-bottom: 1px solid #fed7d7;
            text-align: left;
        }

        .unassigned-table td {
            padding: 10px 16px;
            font-size: 13px;
            border-bottom: 1px solid #fff5f5;
            vertical-align: middle;
        }

        .unassigned-table tbody tr:last-child td { border-bottom: none; }

        .reason-text {
            color: #c53030;
            font-size: 12px;
        }

        /* ── Summary stats ───────────────────────────── */
        .stats-row {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .stat-box {
            flex: 1;
            min-width: 130px;
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 14px 16px;
            display: flex;
            align-items: center;
            gap: 12px;
        }

        .stat-icon {
            font-size: 22px;
            width: 36px;
            text-align: center;
            flex-shrink: 0;
        }

        .stat-val {
            font-size: 22px;
            font-weight: 700;
            color: #1e3a5f;
            line-height: 1;
        }

        .stat-lbl {
            font-size: 11px;
            color: #a0aec0;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            margin-top: 3px;
        }

        /* ── date form ───────────────────────────────── */
        .date-form-wrap {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 10px;
            padding: 20px 24px;
            margin-bottom: 20px;
            display: flex;
            align-items: flex-end;
            gap: 14px;
            flex-wrap: wrap;
        }

        .date-form-wrap .form-group { margin-bottom: 0; }
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
            <div class="page-title">📊 Planning des Véhicules</div>
            <div class="breadcrumb">Accueil / Planning</div>
        </header>

        <div class="page-content">

            <%-- ── Date picker ─────────────────────────────────────── --%>
            <div class="date-form-wrap">
                <form action="${pageContext.request.contextPath}/planning/result" method="get"
                      style="display:flex; gap:12px; align-items:flex-end; flex-wrap:wrap; width:100%;">
                    <div class="form-group">
                        <label for="date" style="font-size:12px; font-weight:600; color:#718096; text-transform:uppercase; letter-spacing:.4px; margin-bottom:6px; display:block;">
                            Date
                        </label>
                        <input type="date" id="date" name="date" class="form-control"
                               style="width:200px;"
                               value="${not empty date ? date : ''}">
                    </div>
                    <button type="submit" class="btn btn-primary">Générer le planning</button>
                </form>
            </div>

            <%-- ── Error ─────────────────────────────────────────── --%>
            <% if (request.getAttribute("error") != null) { %>
                <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
            <% } %>

            <%
                List<PlanningEntry> planning = (List<PlanningEntry>) request.getAttribute("planning");
                String date          = (String)  request.getAttribute("date");
                Integer totalResas   = (Integer) request.getAttribute("totalReservations");
                Integer tempsAttente = (Integer) request.getAttribute("tempsAttente");
                Double  vitesse      = (Double)  request.getAttribute("vitesse");
                SimpleDateFormat sdfH = new SimpleDateFormat("HH'h'mm");

                if (planning != null) {
                    List<Reservation> unassigned = (List<Reservation>) request.getAttribute("unassigned");
                    int nbUnassigned = (unassigned != null) ? unassigned.size() : 0;
            %>

            <%-- ── Stats ─────────────────────────────────────────── --%>
            <div class="stats-row">
                <div class="stat-box">
                    <div class="stat-icon">📋</div>
                    <div>
                        <div class="stat-val"><%= totalResas != null ? totalResas : 0 %></div>
                        <div class="stat-lbl">Réservations</div>
                    </div>
                </div>
                <div class="stat-box">
                    <div class="stat-icon">🚐</div>
                    <div>
                        <div class="stat-val"><%= planning.size() %></div>
                        <div class="stat-lbl">Départs planifiés</div>
                    </div>
                </div>
                <div class="stat-box">
                    <div class="stat-icon">⏱</div>
                    <div>
                        <div class="stat-val"><%= tempsAttente != null ? tempsAttente : 30 %> min</div>
                        <div class="stat-lbl">Temps d'attente</div>
                    </div>
                </div>
                <div class="stat-box">
                    <div class="stat-icon">🏎</div>
                    <div>
                        <div class="stat-val"><%= vitesse != null ? vitesse.intValue() : 30 %> km/h</div>
                        <div class="stat-lbl">Vitesse moyenne</div>
                    </div>
                </div>
                <% if (nbUnassigned > 0) { %>
                <div class="stat-box" style="border-color:#fed7d7; background:#fff5f5;">
                    <div class="stat-icon">⚠️</div>
                    <div>
                        <div class="stat-val" style="color:#e53e3e;"><%= nbUnassigned %></div>
                        <div class="stat-lbl">Non assignées</div>
                    </div>
                </div>
                <% } %>
            </div>

            <%-- ── Planning entries ────────────────────────────────── --%>
            <% if (planning.isEmpty()) { %>
                <div style="background:#fff; border:1px solid #e2e8f0; border-radius:10px; padding:48px; text-align:center; color:#a0aec0;">
                    <div style="font-size:48px; margin-bottom:12px;">🗓</div>
                    <div style="font-size:15px;">Aucune réservation pour le <%= date %>.</div>
                </div>
            <% } else { %>

            <div style="font-size:12px; color:#718096; margin-bottom:10px; font-weight:600; text-transform:uppercase; letter-spacing:.5px;">
                Planning du <%= date %> — <%= planning.size() %> départ<%= planning.size() > 1 ? "s" : "" %>
            </div>

            <div class="plan-list">
            <%
                int entryNum = 0;
                for (PlanningEntry entry : planning) {
                    entryNum++;
                    Voiture v = entry.getVoiture();
                    int passTotal = entry.getTotalPassagers();
                    int capacity  = v.getNbPlace();
                    int pct       = capacity > 0 ? Math.min(100, 100 * passTotal / capacity) : 0;
                    String carbClass = v.getCarburant() == 'd' ? "tag-d" : (v.getCarburant() == 'e' ? "tag-e" : "tag-h");
                    String carbLabel = v.getCarburant() == 'd' ? "Diesel" : (v.getCarburant() == 'e' ? "Essence" : "Hybride");
                    java.util.List<String[]> itinSteps = entry.getItinerarySteps();
            %>
                <div class="plan-card">

                    <%-- ── Card header ─────────────────────────────── --%>
                    <div class="plan-head">

                        <%-- Vehicle info --%>
                        <div class="plan-head-vehicle">
                            <div class="plan-num"><%= entryNum %></div>
                            <div>
                                <div class="plan-vehicle-name">
                                    <%= v.getMatricule() != null ? v.getMatricule() : "Véhicule #" + v.getId() %>
                                </div>
                                <div class="plan-vehicle-sub">
                                    <%= v.getMarque() %> &bull; <%= v.getType() %>
                                    &nbsp;<span class="tag <%= carbClass %>"><%= carbLabel %></span>
                                    <span class="tag" style="background:#f7fafc; color:#4a5568; border:1px solid #e2e8f0;"><%= capacity %> places</span>
                                </div>
                            </div>
                        </div>

                        <%-- Times --%>
                        <div class="plan-head-times">
                            <div class="plan-time-block">
                                <div class="plan-time-label">✈ Départ</div>
                                <div class="plan-time-value"><%= entry.getDepartureFormatted() %></div>
                            </div>
                            <div class="plan-time-arrow">→</div>
                            <div class="plan-time-block">
                                <div class="plan-time-label">🏨 Arrivée hôtel</div>
                                <div class="plan-time-value"><%= entry.getArrivalFormatted() %></div>
                            </div>
                            <div class="plan-time-arrow">→</div>
                            <div class="plan-time-block">
                                <div class="plan-time-label">✈ Retour</div>
                                <div class="plan-time-value"><%= entry.getReturnToAirportFormatted() %></div>
                            </div>
                        </div>

                        <%-- Distance --%>
                        <div class="plan-head-km">
                            <div class="plan-time-label">Distance</div>
                            <div class="plan-km-value"><%= String.format("%.0f", entry.getTotalKm()) %> km</div>
                        </div>

                        <%-- Capacity --%>
                        <div class="plan-head-cap">
                            <div class="cap-label"><%= passTotal %> / <%= capacity %> places</div>
                            <div class="cap-bar-wrap">
                                <div class="cap-bar" style="width:<%= pct %>%;"></div>
                            </div>
                        </div>
                    </div>

                    <%-- ── Reservations table ──────────────────────── --%>
                    <div class="plan-body">
                        <table class="plan-table">
                            <thead>
                                <tr>
                                    <th>Réservation</th>
                                    <th>Client</th>
                                    <th>Destination</th>
                                    <th>Heure d'arrivée</th>
                                    <th>Passagers</th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for (Reservation r : entry.getReservations()) { %>
                                <tr>
                                    <td><span class="res-id">R<%= r.getId() %></span></td>
                                    <td style="color:#4a5568;"><%= r.getIdClient() %></td>
                                    <td class="hotel-code">
                                        <%= r.getLieuCode() != null ? r.getLieuCode() : "Hôtel #" + r.getIdHotel() %>
                                    </td>
                                    <td class="res-arrive">
                                        <%= r.getDateHeureArrivee() != null ? sdfH.format(r.getDateHeureArrivee()) : "—" %>
                                    </td>
                                    <td class="pax-count"><%= r.getNbPassager() %> pax</td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>
                    </div>

                    <%-- ── Itinerary footer ────────────────────────── --%>
                    <div class="plan-foot">
                        <span style="font-size:11px; color:#a0aec0; font-weight:600; text-transform:uppercase; letter-spacing:.4px; margin-right:12px;">Itinéraire</span>
                        <% for (int si = 0; si < itinSteps.size(); si++) {
                               String[] step = itinSteps.get(si);
                               boolean isEndpoint = (si == 0 || si == itinSteps.size() - 1);
                        %>
                            <% if (si > 0) { %>
                                <span class="itin-leg"><%= step[1] %></span>
                                <span class="itin-arrow-char">›</span>
                            <% } %>
                            <span class="<%= isEndpoint ? "itin-airport-node" : "itin-hotel-node" %>">
                                <%= step[0] %>
                            </span>
                        <% } %>
                    </div>

                </div>
            <% } %>
            </div>

            <% } /* end if planning not empty */ %>

            <%-- ── Non assignées ───────────────────────────────────── --%>
            <% if (nbUnassigned > 0) { %>
            <div class="unassigned-card" style="margin-top:24px;">
                <div class="unassigned-head">
                    <span style="font-size:16px;">⚠️</span>
                    <h3>Réservations non assignées</h3>
                    <span class="unassigned-badge"><%= nbUnassigned %></span>
                </div>
                <table class="unassigned-table">
                    <thead>
                        <tr>
                            <th>Réservation</th>
                            <th>Client</th>
                            <th>Destination</th>
                            <th>Heure d'arrivée</th>
                            <th>Passagers</th>
                            <th>Raison</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% for (Reservation r : unassigned) { %>
                        <tr>
                            <td><span class="res-id" style="background:#fff5f5; color:#c53030;">R<%= r.getId() %></span></td>
                            <td style="color:#4a5568;"><%= r.getIdClient() %></td>
                            <td class="hotel-code">
                                <%= r.getLieuCode() != null ? r.getLieuCode() : "Hôtel #" + r.getIdHotel() %>
                            </td>
                            <td class="res-arrive">
                                <%= r.getDateHeureArrivee() != null ? sdfH.format(r.getDateHeureArrivee()) : "—" %>
                            </td>
                            <td class="pax-count"><%= r.getNbPassager() %> pax</td>
                            <td class="reason-text">
                                <%= r.getUnassignedReason() != null ? r.getUnassignedReason() : "Aucun véhicule disponible" %>
                            </td>
                        </tr>
                    <% } %>
                    </tbody>
                </table>
            </div>
            <% } %>

            <% } /* end if planning != null */ %>

        </div><!-- /page-content -->
    </div><!-- /main-content -->
</div><!-- /app-layout -->
</body>
</html>
