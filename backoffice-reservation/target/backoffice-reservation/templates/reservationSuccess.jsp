<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Réservation Enregistrée</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .message-container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .success {
            color: #4CAF50;
            font-size: 48px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
        .actions {
            margin-top: 30px;
        }
        .btn {
            display: inline-block;
            padding: 12px 24px;
            margin: 5px;
            border-radius: 4px;
            text-decoration: none;
            font-weight: bold;
        }
        .btn-primary {
            background-color: #4CAF50;
            color: white;
        }
        .btn-secondary {
            background-color: #2196F3;
            color: white;
        }
        .btn:hover {
            opacity: 0.9;
        }
    </style>
</head>
<body>
    <div class="message-container">
        <div class="success">✅</div>
        <h1>Réservation enregistrée avec succès!</h1>
        <p>Votre réservation a été enregistrée dans le système.</p>
        
        <div class="actions">
            <a href="${pageContext.request.contextPath}/reservation/form" class="btn btn-primary">
                Nouvelle réservation
            </a>
            <a href="${pageContext.request.contextPath}/reservation/list" class="btn btn-secondary">
                Voir les réservations
            </a>
        </div>
    </div>
</body>
</html>
