# Backoffice Réservation

Application de gestion de réservations d'hôtels utilisant le framework custom.

## Structure du Projet

```
backoffice-reservation/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   ├── controller/
│   │   │   │   └── ReservationController.java
│   │   │   └── models/
│   │   │       ├── Hotel.java
│   │   │       └── Reservation.java
│   │   ├── resources/
│   │   │   └── database.properties
│   │   └── webapp/
│   │       └── templates/
│   │           ├── reservationForm.jsp
│   │           ├── reservationSuccess.jsp
│   │           └── reservationList.jsp
├── WEB-INF/
│   └── web.xml
├── pom.xml
├── build-war.bat
└── init-database.sql
```

## Prérequis

- JDK 17 ou supérieur
- Maven 3.6+
- PostgreSQL 12+
- Apache Tomcat 10+

## Installation

### 1. Configurer PostgreSQL

Créez la base de données et insérez les données initiales :

```bash
psql -U postgres -f init-database.sql
```

### 2. Configurer la connexion à la base

Modifiez le fichier `src/main/resources/database.properties` si nécessaire :

```properties
db.url=jdbc:postgresql://localhost:5432/reservation
db.user=postgres
db.password=postgres
```

### 3. Compiler le framework et l'application

Exécutez le script de build :

```bash
build-war.bat
```

Ou manuellement :

```bash
# Compiler le framework
cd ../framework
mvn clean install

# Compiler l'application
cd ../backoffice-reservation
mvn clean package
```

### 4. Déployer sur Tomcat

1. Copiez `target/backoffice-reservation.war` dans le dossier `webapps` de Tomcat
2. Démarrez Tomcat
3. Attendez le déploiement automatique

## Utilisation

### Interface Web

- **Formulaire de réservation** : http://localhost:8080/backoffice-reservation/reservation/form
- **Liste des réservations** : http://localhost:8080/backoffice-reservation/reservation/list

### API REST

#### Liste des réservations (JSON)

```
GET http://localhost:8080/backoffice-reservation/api/reservations
```

Réponse :

```json
{
  "success": true,
  "message": "Liste des réservations récupérée avec succès",
  "data": [
    {
      "id": 1,
      "idClient": "A001",
      "idHotel": 1,
      "nbPassager": 2,
      "dateHeureArrivee": "2026-03-15T14:00:00.000+00:00",
      "hotelName": "Hôtel Colbert",
      "hotelVille": "Antananarivo"
    }
  ]
}
```

## Fonctionnalités

### Formulaire de Réservation

- ID Client : 4 caractères alphanumériques (obligatoire)
- Sélection d'hôtel depuis une liste déroulante
- Nombre de passagers (1-20)
- Date et heure d'arrivée

### Validation

- L'ID client doit contenir exactement 4 caractères
- Tous les champs sont obligatoires
- Validation côté client et serveur

### API

L'API `/api/reservations` retourne toutes les réservations en format JSON avec :
- Informations complètes de chaque réservation
- Détails de l'hôtel associé (nom, ville)
- Format de réponse standardisé

## Base de Données

### Table `hotel`

- `id` : Identifiant unique (auto-incrémenté)
- `name` : Nom de l'hôtel
- `ville` : Ville
- `adresse` : Adresse complète

### Table `reservation`

- `id` : Identifiant unique (auto-incrémenté)
- `id_client` : Identifiant du client (VARCHAR 4)
- `id_hotel` : Référence à l'hôtel
- `nb_passager` : Nombre de passagers
- `date_heure_arrivee` : Date et heure d'arrivée

## Données de Test

Le script SQL insère 20 hôtels à Madagascar et 5 réservations exemples.

## Framework

Ce projet utilise un framework MVC custom avec :

- Annotations pour le mapping des URLs (`@MyController`, `@MyURL`, `@MyParam`)
- Support JSON via `JsonResponse`
- Support des vues JSP via `ModelView`
- Connexion à la base de données via `DatabaseConnection`

## Support de la Base de Données dans le Framework

Le framework a été enrichi avec :

- **Classe `DatabaseConnection`** : Gère la connexion PostgreSQL
- **Configuration via properties** : Fichier `database.properties` dans le classpath
- **Gestion automatique du pool de connexions**

Pour utiliser la base de données dans vos controllers :

```java
Connection conn = DatabaseConnection.getConnection();
try {
    // Votre code SQL
} finally {
    DatabaseConnection.closeConnection(conn);
}
```

## Dépannage

### Erreur de connexion à la base

- Vérifiez que PostgreSQL est démarré
- Vérifiez les paramètres dans `database.properties`
- Vérifiez que la base `reservation` existe

### Erreur 404

- Vérifiez que le WAR est correctement déployé dans Tomcat
- Vérifiez les logs Tomcat dans `logs/catalina.out`

### Le framework n'est pas trouvé

- Assurez-vous d'avoir compilé le framework avec `mvn install`
- Vérifiez que le JAR du framework est dans votre repository Maven local (~/.m2)

## Auteurs

Projet créé pour Mr Naina - Sprint par groupe
