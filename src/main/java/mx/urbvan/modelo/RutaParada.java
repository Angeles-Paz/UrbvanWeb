package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * RutaParada - punto de una ruta B2B (origen, parada, destino).
 * Columnas BD: id, ruta_id, orden, tipo, latitud, longitud,
 *              nombre_lugar, tiempo_estancia, hora_estimada
 */
public class RutaParada {

    public enum Tipo {
        ORIGEN, PARADA, DESTINO;
        public String toDb() { return name().toLowerCase(); }
        public static Tipo fromDb(String v) {
            if (v == null) return PARADA;
            return switch (v.toLowerCase()) {
                case "origen"  -> ORIGEN;
                case "destino" -> DESTINO;
                default        -> PARADA;
            };
        }
    }

    private int    id;
    private int    rutaId;
    private int    orden;
    private Tipo   tipo;
    private double latitud;
    private double longitud;
    private String nombreLugar;
    private int    tiempoEstancia;   // minutos
    private LocalDateTime horaEstimada;

    public RutaParada() {}

    public boolean esOrigen()  { return tipo == Tipo.ORIGEN; }
    public boolean esDestino() { return tipo == Tipo.DESTINO; }
    public String getTipoNombre() { return tipo != null ? tipo.name().toLowerCase() : "parada"; }
    public String getTipoTexto() {
        if (tipo == null) return "Parada";
        return switch (tipo) {
            case ORIGEN -> "Origen";
            case PARADA -> "Parada";
            case DESTINO -> "Destino";
        };
    }

    // Getters y setters
    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }
    public int getRutaId()                      { return rutaId; }
    public void setRutaId(int v)                { this.rutaId = v; }
    public int getOrden()                       { return orden; }
    public void setOrden(int v)                 { this.orden = v; }
    public Tipo getTipo()                       { return tipo; }
    public void setTipo(Tipo tipo)              { this.tipo = tipo; }
    public double getLatitud()                  { return latitud; }
    public void setLatitud(double v)            { this.latitud = v; }
    public double getLongitud()                 { return longitud; }
    public void setLongitud(double v)           { this.longitud = v; }
    public String getNombreLugar()              { return nombreLugar; }
    public void setNombreLugar(String v)        { this.nombreLugar = v; }
    public int getTiempoEstancia()              { return tiempoEstancia; }
    public void setTiempoEstancia(int v)        { this.tiempoEstancia = v; }
    public LocalDateTime getHoraEstimada()      { return horaEstimada; }
    public void setHoraEstimada(LocalDateTime v){ this.horaEstimada = v; }
}
