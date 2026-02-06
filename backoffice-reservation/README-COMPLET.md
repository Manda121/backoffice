# Backoffice Reservation

Application de gestion de réservations d'hôtels utilisant le framework maison.

## ✅ État du Projet

**LE PROJET EST PRÊT À UTILISER !**

Le framework a été installé dans le repository Maven local et backoffice-reservation utilise directement cette dépendance.  
Lors de la compilation, Maven inclut automatiquement le JAR du framework dans le WAR final (dans `WEB-INF/lib/`).

## Fonctionnalités

- **Formulaire de réservation** : Permet de créer une réservation avec :
  - ID client (4 caractères exactement)
  - Sélection de l'hôtel
  - Nombre de passagers
  - Date et heure d'arrivée

- **Liste des réservations** : Affichage HTML de toutes les réservations avec les détails des hôtels

- **API REST** : Endpoint JSON pour récupérer la liste des réservations
  - URL : `/api/reservations`
  - Méthode : GET
  - Format de réponse : JSON

## Prérequis

- Java 8 ou supérieur
- Maven 3.6+
- PostgreSQL
- Apache Tomcat 10.1+

## Installation

### 1. Initialiser la base de données

```bash
psql -U postgres -f init-database.sql
```

Ce script va :
- Créer la base de données `reservation`
- Créer les tables `hotel` et `reservation`
- Insérer 20 hôtels de démonstration à Madagascar
- Insérer quelques réservations exemples

### 2. Configurer la connexion à la base

Modifier le fichier `src/main/resources/database.properties` si nécessaire :

```properties
db.url=jdbc:postgresql://localhost:5432/reservation
db.user=postgres
db.password=admin
```

### 3. Compiler le framework (SI PAS DÉJÀ FAIT)

Le framework doit d'abord être installé dans le repository Maven local :

```bash
cd ../framework
mvn clean install
```

**Note** : Le framework a déjà été compilé et installé avec succès.

### 4. Compiler et déployer

**Méthode automatique (recommandée)** :

```bash
deploy-tomcat.bat
```

Ce script va :
1. Compiler le projet avec Maven
2. Copier automatiquement le WAR vers Tomcat (`C:\apache-tomcat-10.1.28\webapps`)

**Méthode manuelle** :

```bash
# Compilation
mvn clean package

# Copie vers Tomcat
copy target\backoffice-reservation.war C:\apache-tomcat-10.1.28\webapps\
```

## Utilisation

Une fois Tomcat démarré, accédez à :

- **Formulaire de réservation** : http://localhost:8080/backoffice-reservation/reservation/form
- **Liste des réservations** : http://localhost:8080/backoffice-reservation/reservation/list
- **API JSON** : http://localhost:8080/backoffice-reservation/api/reservations

### Exemple d'appel API

```bash
curl http://localhost:8080/backoffice-reservation/api/reservations
```

Réponse JSON :
```json
{
  "status": 200,
  "data": [
    {
      "id": 1,
      "idClient": "A001",
      "idHotel": 1,
      "nbPassager": 2,
      "dateHeureArrivee": "2026-03-15T14:00:00",
      "hotelName": "Hôtel Colbert",
      "hotelVille": "Antananarivo"
    }
  ],
  "message": "Liste des réservations récupérée avec succès"
}
```

### Tester l'API depuis un autre projet

```java
// Exemple Java
URL url = new URL("http://localhost:8080/backoffice-reservation/api/reservations");
HttpURLConnection conn = (HttpURLConnection) url.openConnection();
conn.setRequestMethod("GET");
// ... lire la réponse JSON
```

```javascript
// Exemple JavaScript/Fetch
fetch('http://localhost:8080/backoffice-reservation/api/reservations')
  .then(response => response.json())
  .then(data => console.log(data));
```

## Structure du projet

```
backoffice-reservation/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── controller/
│   │   │   │   └── ReservationController.java    # Controller principal
│   │   │   └── models/
│   │   │       ├── Hotel.java                    # Modèle Hotel
│   │   │       └── Reservation.java              # Modèle Reservation
│   │   ├── resources/
│   │   │   └── database.properties               # Configuration BDD
│   │   └── webapp/
│   │       ├── templates/
│   │       │   ├── reservationForm.jsp          # Formulaire de réservation
│   │       │   ├── reservationList.jsp          # Liste des réservations
│   │       │   └── reservationSuccess.jsp       # Page de succès
│   │       └── WEB-INF/
│   │           └── web.xml                      # Configuration servlet
├── init-database.sql                            # Script d'initialisation BDD
├── pom.xml                                      # Configuration Maven
├── build-war.bat                                # Script de compilation
└── deploy-tomcat.bat                            # Script de déploiement
```

## Technologies utilisées

- **Framework maison** : Gestion des controllers, routing, JSON
- **Jakarta Servlet API 6.0** : Pour Tomcat 10+
- **PostgreSQL** : Base de données
- **JSP** : Pages web dynamiques
- **Maven** : Gestion des dépendances et build

## Routes disponibles

| Route | Méthode | Description | Type |
|-------|---------|-------------|------|
| `/reservation/form` | GET | Formulaire de création de réservation | HTML |
| `/reservation/save` | POST | Enregistrer une nouvelle réservation | HTML |
| `/reservation/list` | GET | Liste de toutes les réservations | HTML |
| `/api/reservations` | GET | Liste des réservations au format JSON | JSON |

## Notes importantes

1. **ID Client** : Doit contenir exactement 4 caractères (ex: A001, B002)
   - Validation côté serveur implémentée
   
2. **Framework** : Le framework a déjà été compilé et installé avec `mvn clean install`
   - Le JAR est automatiquement inclus dans le WAR (dans `WEB-INF/lib/framework-sprint-1.jar`)
   
3. **Base de données** : PostgreSQL doit être démarré et la base initialisée
   
4. **Tomcat** : Compatible avec Tomcat 10.1+ (Jakarta EE 9+)

5. **Pas de table client** : L'ID client est un simple champ VARCHAR(4), pas de clé étrangère

## Support de la base de données par le framework

Le framework a été étendu avec la classe `DatabaseConnection` qui :
- Charge la configuration depuis `database.properties` dans le classpath
- Initialise automatiquement le driver PostgreSQL
- Fournit des méthodes pour obtenir et fermer les connexions
- Gère les erreurs de connexion de manière centralisée

### Utilisation dans un controller

```java
import itu.framework.db.DatabaseConnection;

Connection conn = DatabaseConnection.getConnection();
try {
    // Exécuter vos requêtes SQL
    PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM hotel");
    ResultSet rs = pstmt.executeQuery();
    // ...
} finally {
    DatabaseConnection.closeConnection(conn);
}
```

## Données de test

Le script `init-database.sql` insère automatiquement :
- **20 hôtels** répartis dans différentes villes de Madagascar
- **5 réservations** exemples avec des ID clients variés

## Dépannage

### Erreur de connexion à la base
Vérifiez que PostgreSQL est démarré et que les paramètres dans `database.properties` sont corrects.

### Erreur 404
Vérifiez que Tomcat est démarré et que le WAR est bien déployé dans `webapps/`.

### Framework non trouvé
Recompilez et réinstallez le framework :
```bash
cd ../framework
mvn clean install
```

## Pour aller plus loin

Pour ajouter de nouvelles fonctionnalités :
1. Créer une nouvelle méthode dans `ReservationController.java`
2. Ajouter l'annotation `@MyURL(value = "/votre-route", method = "GET")`
3. Recompiler et redéployer avec `deploy-tomcat.bat`
