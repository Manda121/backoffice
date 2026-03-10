package models;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * DTO représentant une entrée de planification :
 * un véhicule, ses réservations pour un départ, ainsi que les heures de départ/arrivée.
 */
public class PlanningEntry {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("HH'h'mm");

    private Voiture voiture;
    private List<Reservation> reservations;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;           // arrivée à l'hôtel
    private LocalDateTime returnToAirportTime;   // retour à l'aéroport
    private double km;                           // distance totale aller-retour
    private List<String[]> itinerarySteps;       // [{code, kmFromPrev}, ...]

    public PlanningEntry() {
    }

    public PlanningEntry(Voiture voiture, List<Reservation> reservations,
                         LocalDateTime departureTime, LocalDateTime arrivalTime,
                         LocalDateTime returnToAirportTime, double km,
                         List<String[]> itinerarySteps) {
        this.voiture = voiture;
        this.reservations = reservations;
        this.departureTime = departureTime;
        this.arrivalTime = arrivalTime;
        this.returnToAirportTime = returnToAirportTime;
        this.km = km;
        this.itinerarySteps = itinerarySteps;
    }

    public Voiture getVoiture() { return voiture; }
    public void setVoiture(Voiture voiture) { this.voiture = voiture; }

    public List<Reservation> getReservations() { return reservations; }
    public void setReservations(List<Reservation> reservations) { this.reservations = reservations; }

    public LocalDateTime getDepartureTime() { return departureTime; }
    public void setDepartureTime(LocalDateTime departureTime) { this.departureTime = departureTime; }

    public LocalDateTime getArrivalTime() { return arrivalTime; }
    public void setArrivalTime(LocalDateTime arrivalTime) { this.arrivalTime = arrivalTime; }

    /** Heure de départ formatée (ex: 10h30) */
    public String getDepartureFormatted() {
        return departureTime != null ? departureTime.format(FMT) : "-";
    }

    /** Heure d'arrivée à l'hôtel formatée (ex: 14h30) */
    public String getArrivalFormatted() {
        return arrivalTime != null ? arrivalTime.format(FMT) : "-";
    }

    /** Heure de retour à l'aéroport formatée */
    public String getReturnToAirportFormatted() {
        return returnToAirportTime != null ? returnToAirportTime.format(FMT) : "-";
    }

    public LocalDateTime getReturnToAirportTime() { return returnToAirportTime; }
    public void setReturnToAirportTime(LocalDateTime t) { this.returnToAirportTime = t; }

    public double getKm() { return km; }
    public void setKm(double km) { this.km = km; }

    /** Distance totale du trajet complet (aéroport → hôtels → aéroport) */
    public double getTotalKm() { return km; }

    /** Étapes de l'itinéraire : chaque élément est {code, kmFromPrev} */
    public List<String[]> getItinerarySteps() {
        return itinerarySteps != null ? itinerarySteps : new java.util.ArrayList<>();
    }
    public void setItinerarySteps(List<String[]> steps) { this.itinerarySteps = steps; }

    /** Nombre total de passagers dans ce groupe */
    public int getTotalPassagers() {
        if (reservations == null) return 0;
        return reservations.stream().mapToInt(Reservation::getNbPassager).sum();
    }

    /** IDs des réservations sous forme de chaîne (ex: R1, R2, R3) */
    public String getReservationIds() {
        if (reservations == null) return "";
        StringBuilder sb = new StringBuilder();
        for (Reservation r : reservations) {
            if (sb.length() > 0) sb.append(", ");
            sb.append("R").append(r.getId());
        }
        return sb.toString();
    }
}
