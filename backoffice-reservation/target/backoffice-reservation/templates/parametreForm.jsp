<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="models.Parametre" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= "edit".equals(request.getAttribute("action")) ? "Modifier" : "Ajouter" %> un Paramètre</title>
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
        <%
            boolean isEdit = "edit".equals(request.getAttribute("action"));
            Parametre p = (Parametre) request.getAttribute("parametre");
        %>
        <header class="topbar">
            <div class="page-title"><span class="title-icon">⚙️</span> <%= isEdit ? "Modifier le paramètre" : "Nouveau paramètre" %></div>
            <div class="breadcrumb">Accueil / Paramètres / <%= isEdit ? "Modifier" : "Ajouter" %></div>
        </header>

        <div class="page-content">
            <div class="card">
                <div class="card-header">
                    <h2><%= isEdit ? "Modifier le paramètre" : "Ajouter un nouveau paramètre" %></h2>
                </div>
                <div class="card-body">
                    <div class="form-container">
                        <% if (request.getAttribute("error") != null) { %>
                            <div class="alert alert-error">❌ <%= request.getAttribute("error") %></div>
                        <% } %>

                        <form action="${pageContext.request.contextPath}/parametre/<%= isEdit ? "update" : "save" %>" method="post">
                            <% if (isEdit && p != null) { %>
                                <input type="hidden" name="id" value="<%= p.getId() %>">
                            <% } %>

                            <div class="form-group">
                                <label for="code">Code :</label>
                                <input type="text" id="code" name="code" class="form-control" required
                                       value="<%= (isEdit && p != null) ? p.getCode() : "" %>"
                                       placeholder="Ex: vitesse_moyenne, temps_attente">
                                <div class="form-info">Identifiant unique du paramètre (sans espaces).</div>
                            </div>

                            <div class="form-group">
                                <label for="valeur">Valeur :</label>
                                <input type="text" id="valeur" name="valeur" class="form-control" required
                                       value="<%= (isEdit && p != null) ? p.getValeur() : "" %>"
                                       placeholder="Ex: 30">
                            </div>

                            <div class="form-group">
                                <label for="description">Description :</label>
                                <input type="text" id="description" name="description" class="form-control"
                                       value="<%= (isEdit && p != null && p.getDescription() != null) ? p.getDescription() : "" %>"
                                       placeholder="Description optionnelle">
                            </div>

                            <div class="form-group">
                                <button type="submit" class="btn-submit"><%= isEdit ? "Enregistrer les modifications" : "Ajouter le paramètre" %></button>
                            </div>
                        </form>

                        <a href="${pageContext.request.contextPath}/parametre/list" class="form-back">← Retour aux paramètres</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
