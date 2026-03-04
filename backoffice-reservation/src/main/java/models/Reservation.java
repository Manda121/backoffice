package models;

import java.sql.Timestamp;

public class Reservation {
    private int id;
    private String idClient;
    private int idHotel;
    private int nbPassager;
    private Timestamp dateHeureArrivee;
    
    // Lieu de destination (sprint 2)
    private int idLieuDestination;
    private String lieuCode;

    // Pour afficher les détails de l'hôtel
    private String hotelName;
    private String hotelVille;

    public Reservation() {
    }

    public Reservation(int id, String idClient, int idHotel, int nbPassager, Timestamp dateHeureArrivee) {
        this.id = id;
        this.idClient = idClient;
        this.idHotel = idHotel;
        this.nbPassager = nbPassager;
        this.dateHeureArrivee = dateHeureArrivee;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getIdClient() {
        return idClient;
    }

    public void setIdClient(String idClient) {
        this.idClient = idClient;
    }

    public int getIdHotel() {
        return idHotel;
    }

    public void setIdHotel(int idHotel) {
        this.idHotel = idHotel;
    }

    public int getNbPassager() {
        return nbPassager;
    }

    public void setNbPassager(int nbPassager) {
        this.nbPassager = nbPassager;
    }

    public Timestamp getDateHeureArrivee() {
        return dateHeureArrivee;
    }

    public void setDateHeureArrivee(Timestamp dateHeureArrivee) {
        this.dateHeureArrivee = dateHeureArrivee;
    }

    public String getHotelName() {
        return hotelName;
    }

    public void setHotelName(String hotelName) {
        this.hotelName = hotelName;
    }

    public String getHotelVille() {
        return hotelVille;
    }

    public void setHotelVille(String hotelVille) {
        this.hotelVille = hotelVille;
    }

    public int getIdLieuDestination() { return idLieuDestination; }
    public void setIdLieuDestination(int idLieuDestination) { this.idLieuDestination = idLieuDestination; }

    public String getLieuCode() { return lieuCode; }
    public void setLieuCode(String lieuCode) { this.lieuCode = lieuCode; }

    // Raison de non-assignation (non persisté en base)
    private String unassignedReason;
    public String getUnassignedReason() { return unassignedReason; }
    public void setUnassignedReason(String reason) { this.unassignedReason = reason; }
}
