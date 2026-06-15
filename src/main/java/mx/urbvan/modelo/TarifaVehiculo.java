package mx.urbvan.modelo;

/**
 * TarifaVehiculo - tarifa B2B por modelo de vehículo.
 * Columnas BD: id, modelo, capacidad, costo_por_km, costo_por_hora
 */
public class TarifaVehiculo {

    private int    id;
    private String modelo;
    private int    capacidad;
    private double costoPorKm;
    private double costoPorHora;

    public TarifaVehiculo() {}

    /**
     * Calcula el costo total de una ruta B2B.
     * @param km        distancia total en kilómetros
     * @param horas     duración total en horas
     */
    public double calcularCosto(double km, double horas) {
        return (km * costoPorKm) + (horas * costoPorHora);
    }

    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }
    public String getModelo()                   { return modelo; }
    public void setModelo(String v)             { this.modelo = v; }
    public int getCapacidad()                   { return capacidad; }
    public void setCapacidad(int v)             { this.capacidad = v; }
    public double getCostoPorKm()               { return costoPorKm; }
    public void setCostoPorKm(double v)         { this.costoPorKm = v; }
    public double getCostoPorHora()             { return costoPorHora; }
    public void setCostoPorHora(double v)       { this.costoPorHora = v; }
}
