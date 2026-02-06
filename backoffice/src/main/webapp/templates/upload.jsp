<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Formulaire de Test</title>
</head>
<body>
    <h1>Formulaire de Test upload</h1>
    <form action="${pageContext.request.contextPath}/upload" method="post" enctype="multipart/form-data">
        <div>
            <label for="file">Fichiers :</label>
            <input type="file" id="file" name="file" multiple required>
        </div>
        <button type="submit">Envoyer</button>
    </form>
</body>
</html>