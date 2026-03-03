package models;

public class Distance {
    private int id;
    private int lieuFrom;
    private int lieuTo;
    private double km;

    // Pour l'affichage
    private String lieuFromCode;
    private String lieuToCode;

    public Distance() {
    }

    public Distance(int id, int lieuFrom, int lieuTo, double km) {
        this.id = id;
        this.lieuFrom = lieuFrom;
        this.lieuTo = lieuTo;
        this.km = km;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getLieuFrom() { return lieuFrom; }
    public void setLieuFrom(int lieuFrom) { this.lieuFrom = lieuFrom; }

    public int getLieuTo() { return lieuTo; }
    public void setLieuTo(int lieuTo) { this.lieuTo = lieuTo; }

    public double getKm() { return km; }
    public void setKm(double km) { this.km = km; }

    public String getLieuFromCode() { return lieuFromCode; }
    public void setLieuFromCode(String lieuFromCode) { this.lieuFromCode = lieuFromCode; }

    public String getLieuToCode() { return lieuToCode; }
    public void setLieuToCode(String lieuToCode) { this.lieuToCode = lieuToCode; }
}
