<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Lieu" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> un Lieu</title>
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
            <a href="${pageContext.request.contextPath}/lieu/list" class="active">
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
            Lieu lieu = (Lieu) request.getAttribute("lieu");
        %>
        <header class="topbar">
            <div class="page-title"><span class="title-icon">📍</span> <%= isEdit ? "Modifier le lieu" : "Nouveau lieu" %></div>
            <div class="breadcrumb">Accueil / Lieux / <%= isEdit ? "Modifier" : "Ajouter" %></div>
        </header>

        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2><%= isEdit ? "Modifier le lieu" : "Ajouter un nouveau lieu" %></h2>
                </div>
                <div class="card-body">
                    <div class="form-container">
                        <% if (request.getAttribute("error") != null) { %>
                            <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
                        <% } %>

                        <form action="${pageContext.request.contextPath}/lieu/<%= isEdit ? "update" : "save" %>" method="post">
                            <% if (isEdit && lieu != null) { %>
                                <input type="hidden" name="id" value="<%= lieu.getId() %>">
                            <% } %>

                            <div class="form-group">
                                <label for="code">Code du lieu :</label>
                                <input type="text" id="code" name="code" class="form-control" maxlength="100" required
                                       value="<%= (isEdit && lieu != null) ? lieu.getCode() : "" %>"
                                       placeholder="Ex: IVATO, COLBERT, HILTON…">
                            </div>

                            <div class="form-group">
                                <label>Type :</label>
                                <div class="checkbox-group">
                                    <input type="checkbox" id="isAirport" name="isAirport"
                                           <%= (isEdit && lieu != null && lieu.isAirport()) ? "checked" : "" %>>
                                    <label for="isAirport" style="font-weight: normal; margin-bottom: 0;">C'est l'aéroport (point de départ des véhicules)</label>
                                </div>
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-submit"><%= isEdit ? "Enregistrer les modifications" : "Ajouter le lieu" %></button>
                            </div>
                        </form>

                        <a href="${pageContext.request.contextPath}/lieu/list" class="form-back">← Retour à la liste des lieux</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
