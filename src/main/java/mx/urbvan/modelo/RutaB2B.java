package mx.urbvan.modelo;

import java.time.LocalDateTime;
import java.util.List;

/**
 * RutaB2B - POJO para rutas corporativas.
 * Columnas BD: id, empresa_id, vehiculo_id, operador_id, fecha_inicio,
 *              fecha_fin_est, km_totales, costo_total, estado, asignacion_completa,
 *              cancelada_tarde, penalizacion_puntos, created_at, updated_at
 */
public class RutaB2B {

    public enum Estado {
        PENDIENTE, ACTIVA, COMPLETADA, CANCELADA;

        public String toDb() {
            return name().toLowerCase();
        }
        public static Estado fromDb(String v) {
            if (v == null) return PENDIENTE;
            return switch (v.toLowerCase()) {
                case "pendiente"  -> PENDIENTE;
                case "activa"     -> ACTIVA;
                case "completada" -> COMPLETADA;
                case "cancelada"  -> CANCELADA;
                default -> PENDIENTE;
            };
        }
        public String etiqueta() {
            return switch (this) {
                case PENDIENTE  -> "Pendiente";
                case ACTIVA     -> "Activa";
                case COMPLETADA -> "Completada";
                case CANCELADA  -> "Cancelada";
            };
        }
        public String clase() {
            return switch (this) {
                case PENDIENTE  -> "badge-gris";
                case ACTIVA     -> "badge-verde";
                case COMPLETADA -> "badge-morado";
                case CANCELADA  -> "badge-rojo";
            };
        }
    }

    private int    id;
    private int    empresaId;
    private int    vehiculoId;
    private int    operadorId;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFinEst;
    private double kmTotales;
    private double costoTotal;
    private Estado estado;
    private boolean asignacionCompleta;
    private boolean canceladaTarde;
    private double  penalizacionPuntos;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Enriquecidos (JOINs / vistas)
    private String empresaNombre;
    private double empresaScore;
    private String vehiculoModelo;
    private String vehiculoPlaca;
    private int    vehiculoCapacidad;
    private String operadorNombre;
    private double operadorScore;
    private Double operadorLat;
    private Double operadorLng;
    private int    asientosOcupados;

    // Paradas e historial de asientos (cargados opcionalmente)
    private List<RutaParada>  paradas;
    private List<RutaAsiento> asientos;

    public RutaB2B() {}

    // Helpers
    public String getEstadoTexto()  { return estado != null ? estado.etiqueta() : ""; }
    public String getEstadoClase()  { return estado != null ? estado.clase()    : ""; }
    public String getEstadoNombre() { return estado != null ? estado.name()     : ""; }

    public boolean puedeCalificarse() {
        return estado == Estado.COMPLETADA;
    }
    public boolean puedeCancelarse() {
        return estado == Estado.PENDIENTE || estado == Estado.ACTIVA;
    }

    // Getters y setters
    public int getId()                              { return id; }
    public void setId(int id)                       { this.id = id; }
    public int getEmpresaId()                       { return empresaId; }
    public void setEmpresaId(int v)                 { this.empresaId = v; }
    public int getVehiculoId()                      { return vehiculoId; }
    public void setVehiculoId(int v)                { this.vehiculoId = v; }
    public int getOperadorId()                      { return operadorId; }
    public void setOperadorId(int v)                { this.operadorId = v; }
    public LocalDateTime getFechaInicio()           { return fechaInicio; }
    public void setFechaInicio(LocalDateTime v)     { this.fechaInicio = v; }
    public LocalDateTime getFechaFinEst()           { return fechaFinEst; }
    public void setFechaFinEst(LocalDateTime v)     { this.fechaFinEst = v; }
    public double getKmTotales()                    { return kmTotales; }
    public void setKmTotales(double v)              { this.kmTotales = v; }
    public double getCostoTotal()                   { return costoTotal; }
    public void setCostoTotal(double v)             { this.costoTotal = v; }
    public Estado getEstado()                       { return estado; }
    public void setEstado(Estado estado)            { this.estado = estado; }
    public boolean isAsignacionCompleta()           { return asignacionCompleta; }
    public void setAsignacionCompleta(boolean v)    { this.asignacionCompleta = v; }
    public boolean isCanceladaTarde()               { return canceladaTarde; }
    public void setCanceladaTarde(boolean v)        { this.canceladaTarde = v; }
    public double getPenalizacionPuntos()           { return penalizacionPuntos; }
    public void setPenalizacionPuntos(double v)     { this.penalizacionPuntos = v; }
    public LocalDateTime getCreatedAt()             { return createdAt; }
    public void setCreatedAt(LocalDateTime v)       { this.createdAt = v; }
    public LocalDateTime getUpdatedAt()             { return updatedAt; }
    public void setUpdatedAt(LocalDateTime v)       { this.updatedAt = v; }
    public String getEmpresaNombre()                { return empresaNombre; }
    public void setEmpresaNombre(String v)          { this.empresaNombre = v; }
    public double getEmpresaScore()                 { return empresaScore; }
    public void setEmpresaScore(double v)           { this.empresaScore = v; }
    public String getVehiculoModelo()               { return vehiculoModelo; }
    public void setVehiculoModelo(String v)         { this.vehiculoModelo = v; }
    public String getVehiculoPlaca()                { return vehiculoPlaca; }
    public void setVehiculoPlaca(String v)          { this.vehiculoPlaca = v; }
    public int getVehiculoCapacidad()               { return vehiculoCapacidad; }
    public void setVehiculoCapacidad(int v)         { this.vehiculoCapacidad = v; }
    public String getOperadorNombre()               { return operadorNombre; }
    public void setOperadorNombre(String v)         { this.operadorNombre = v; }
    public double getOperadorScore()                { return operadorScore; }
    public void setOperadorScore(double v)          { this.operadorScore = v; }
    public Double getOperadorLat()                  { return operadorLat; }
    public void setOperadorLat(Double v)            { this.operadorLat = v; }
    public Double getOperadorLng()                  { return operadorLng; }
    public void setOperadorLng(Double v)            { this.operadorLng = v; }
    public int getAsientosOcupados()                { return asientosOcupados; }
    public void setAsientosOcupados(int v)          { this.asientosOcupados = v; }
    public List<RutaParada> getParadas()            { return paradas; }
    public void setParadas(List<RutaParada> v)      { this.paradas = v; }
    public List<RutaAsiento> getAsientos()          { return asientos; }
    public void setAsientos(List<RutaAsiento> v)    { this.asientos = v; }
}
