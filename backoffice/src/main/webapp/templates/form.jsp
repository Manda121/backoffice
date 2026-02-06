<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Formulaire de Test</title>
</head>
<body>
    <h1>Formulaire de Test</h1>
    <form action="${pageContext.request.contextPath}/form" method="post">
        <div>
            <label for="name">Nom:</label>
            <input type="text" id="name" name="name" value="Blabla" required>
        </div>
        <div>
            <label for="age">Âge:</label>
            <input type="number" id="age" name="age" value="12">
        </div>
        <button type="submit">Envoyer</button>
    </form>
</body>
</html>