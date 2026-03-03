package models;

public class Parametre {
    private int id;
    private String code;
    private String valeur;
    private String description;

    public Parametre() {
    }

    public Parametre(int id, String code, String valeur, String description) {
        this.id = id;
        this.code = code;
        this.valeur = valeur;
        this.description = description;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getValeur() { return valeur; }
    public void setValeur(String valeur) { this.valeur = valeur; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    /** Retourne la valeur en entier (défaut 0). */
    public int getValeurInt() {
        try { return Integer.parseInt(valeur); } catch (NumberFormatException e) { return 0; }
    }

    /** Retourne la valeur en double (défaut 0.0). */
    public double getValeurDouble() {
        try { return Double.parseDouble(valeur); } catch (NumberFormatException e) { return 0.0; }
    }
}
