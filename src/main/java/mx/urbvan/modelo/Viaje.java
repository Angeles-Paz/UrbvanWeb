package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * Viaje — POJO que representa un registro de la tabla `viajes`.
 * Ubicación: src/main/java/mx/urbvan/modelo/Viaje.java
 */
public class Viaje {

    public enum Estado {
        SOLICITADO, EN_ASIGNACION, ACEPTADO,
        OPERADOR_EN_CAMINO, VIAJE_INICIADO,
        COMPLETADO, CANCELADO
    }

    private int    idViaje;
    private int    idUsuario;
    private int    idOperador;

    private double origenLat;
    private double origenLng;
    private String origenDireccion;

    private double destinoLat;
    private double destinoLng;
    private String destinoDireccion;

    private double distanciaKm;
    private double precioTotal;
    private Estado estado;

    private int etaOperadorMin;
    private int etaViajeMin;

    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaAceptacion;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;

    // ── Getters y Setters ──────────────────────────────────────────

    public int getIdViaje()                    { return idViaje; }
    public void setIdViaje(int v)              { this.idViaje = v; }

    public int getIdUsuario()                  { return idUsuario; }
    public void setIdUsuario(int v)            { this.idUsuario = v; }

    public int getIdOperador()                 { return idOperador; }
    public void setIdOperador(int v)           { this.idOperador = v; }

    public double getOrigenLat()               { return origenLat; }
    public void setOrigenLat(double v)         { this.origenLat = v; }

    public double getOrigenLng()               { return origenLng; }
    public void setOrigenLng(double v)         { this.origenLng = v; }

    public String getOrigenDireccion()         { return origenDireccion; }
    public void setOrigenDireccion(String v)   { this.origenDireccion = v; }

    public double getDestinoLat()              { return destinoLat; }
    public void setDestinoLat(double v)        { this.destinoLat = v; }

    public double getDestinoLng()              { return destinoLng; }
    public void setDestinoLng(double v)        { this.destinoLng = v; }

    public String getDestinoDireccion()        { return destinoDireccion; }
    public void setDestinoDireccion(String v)  { this.destinoDireccion = v; }

    public double getDistanciaKm()             { return distanciaKm; }
    public void setDistanciaKm(double v)       { this.distanciaKm = v; }

    public double getPrecioTotal()             { return precioTotal; }
    public void setPrecioTotal(double v)       { this.precioTotal = v; }

    public Estado getEstado()                  { return estado; }
    public void setEstado(Estado v)            { this.estado = v; }

    public int getEtaOperadorMin()             { return etaOperadorMin; }
    public void setEtaOperadorMin(int v)       { this.etaOperadorMin = v; }

    public int getEtaViajeMin()                { return etaViajeMin; }
    public void setEtaViajeMin(int v)          { this.etaViajeMin = v; }

    public LocalDateTime getFechaSolicitud()            { return fechaSolicitud; }
    public void setFechaSolicitud(LocalDateTime v)      { this.fechaSolicitud = v; }

    public LocalDateTime getFechaAceptacion()           { return fechaAceptacion; }
    public void setFechaAceptacion(LocalDateTime v)     { this.fechaAceptacion = v; }

    public LocalDateTime getFechaInicio()               { return fechaInicio; }
    public void setFechaInicio(LocalDateTime v)         { this.fechaInicio = v; }

    public LocalDateTime getFechaFin()                  { return fechaFin; }
    public void setFechaFin(LocalDateTime v)            { this.fechaFin = v; }
}
