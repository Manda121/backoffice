package models;

public class Voiture {
    private int id;
    private String marque;
    private int nbPlace;
    private String type;
    private char carburant; // 'd' = diesel, 'e' = essence, 'h' = hybride
    private String matricule;

    public Voiture() {
    }

    public Voiture(int id, String marque, int nbPlace, String type, char carburant) {
        this.id = id;
        this.marque = marque;
        this.nbPlace = nbPlace;
        this.type = type;
        this.carburant = carburant;
    }

    public Voiture(int id, String marque, int nbPlace, String type, char carburant, String matricule) {
        this.id = id;
        this.marque = marque;
        this.nbPlace = nbPlace;
        this.type = type;
        this.carburant = carburant;
        this.matricule = matricule;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getMarque() {
        return marque;
    }

    public void setMarque(String marque) {
        this.marque = marque;
    }

    public int getNbPlace() {
        return nbPlace;
    }

    public void setNbPlace(int nbPlace) {
        this.nbPlace = nbPlace;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public char getCarburant() {
        return carburant;
    }

    public void setCarburant(char carburant) {
        this.carburant = carburant;
    }

    public String getMatricule() {
        return matricule;
    }

    public void setMatricule(String matricule) {
        this.matricule = matricule;
    }

    /**
     * Retourne le libellé du carburant
     */
    public String getCarburantLabel() {
        switch (carburant) {
            case 'd': return "Diesel";
            case 'e': return "Essence";
            case 'h': return "Hybride";
            default: return "Inconnu";
        }
    }
}
