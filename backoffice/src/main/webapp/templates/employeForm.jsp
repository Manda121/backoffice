<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Formulaire de Test</title>
</head>
<body>
    <h1>Formulaire d' employe</h1>
    <form action="${pageContext.request.contextPath}/employe" method="post">
        <div>
            <label for="nom">Nom:</label>
            <input type="text" id="e.nom" name="e.nom" value="Dupont" required>
        </div>
        <div>
            <label for="prenom">Prenom:</label>
            <input type="text" id="e.prenom" name="e.prenom" value="Jean" required>
        </div>
        <div>
            <label for="email">email:</label>
            <input type="text" id="e.email" name="e.email" value="Jeandupont@gmail.com" required>
        </div>
        <div>
            <label for="salaire">salaire:</label>
            <input type="number" step="0.01" id="e.salaire" name="e.salaire" value="2500.00" required>
        </div>
        <div>
            <label for="nom departement">nom departement:</label>
            <input type="text" id="e.departement.nom" name="e.departement.nom" value="ressources humaines" required>
        </div>
        <button type="submit" name="action" value="jsp">Envoyer (Vue JSP)</button>
        <button type="submit" name="action" value="json" formaction="${pageContext.request.contextPath}/api/employe">Envoyer (JSON)</button>
    </form>
</body>
</html>