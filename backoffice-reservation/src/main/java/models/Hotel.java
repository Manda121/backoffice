package models;

public class Hotel {
    private int id;
    private String name;
    private String ville;
    private String adresse;

    public Hotel() {
    }

    public Hotel(int id, String name, String ville, String adresse) {
        this.id = id;
        this.name = name;
        this.ville = ville;
        this.adresse = adresse;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getVille() {
        return ville;
    }

    public void setVille(String ville) {
        this.ville = ville;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }
}
