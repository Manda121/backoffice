package models;

public class Lieu {
    private int id;
    private String code;
    private boolean isAirport;

    public Lieu() {
    }

    public Lieu(int id, String code, boolean isAirport) {
        this.id = id;
        this.code = code;
        this.isAirport = isAirport;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public boolean isAirport() { return isAirport; }
    public void setAirport(boolean airport) { isAirport = airport; }

    @Override
    public String toString() {
        return code + (isAirport ? " (Aéroport)" : "");
    }
}
