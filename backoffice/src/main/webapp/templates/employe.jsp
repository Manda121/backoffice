<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Résultat du Formulaire d'employe</title>
</head>
<body>
    <h1>Résultat du Formulaire d'employe</h1>
    <p><strong>Nom:</strong> ${employe.nom}</p>
    <p><strong>Prenom:</strong> ${employe.prenom}</p>
    <p><strong>Email:</strong> ${employe.email}</p>
    <p><strong>Salaire:</strong> ${employe.salaire}</p>
    <p><strong>nom deartement:</strong> ${employe.departement.nom}</p>
</body>
</html>