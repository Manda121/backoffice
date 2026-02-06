package models;

import java.util.List;
import itu.framework.annotations.JsonIgnore;

public class Departement {
    private Integer id;
    private String nom;

    // Pour éviter la boucle infinie : Departement -> List<Employe> -> Departement
    @JsonIgnore
    private List<models.Employe> employes;

    public Departement() {
    }

    public Departement(Integer id, String nom) {
        this.id = id;
        this.nom = nom;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public List<models.Employe> getEmployes() {
        return employes;
    }

    public void setEmployes(List<models.Employe> employes) {
        this.employes = employes;
    }

    public void save() {
        System.out.println(this.toString());
    }

    @Override
    public String toString() {
        return "Departement{id=" + id + ", nom='" + nom + "'}";
    }
}
