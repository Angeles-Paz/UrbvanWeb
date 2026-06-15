package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * Viaje - POJO para viajes individuales B2C.
 *
 * CAMBIOS RESPECTO A v1:
 *   - idUsuario    → pasajeroId     (alinea con columna 'pasajero_id' en BD)
 *   - idOperador   → operadorId     (alinea con columna 'operador_id' en BD)
 *   - Nuevo campo: vehiculoId       (columna 'vehiculo_id' en BD)
 *   - origenDireccion → origenNombre (columna 'origen_nombre' en BD)
 *   - destinoDireccion → destinoNombre
 *   - precioTotal  → costo          (columna 'costo' en BD)
 *   - Nuevo campo: duracionMin      (columna 'duracion_min' en BD)
 *   - Nuevo campo: metodoPago       (columna 'metodo_pago' en BD)
 *   - Nuevo campo: canceladoPor     (columna 'cancelado_por' en BD)
 *   - Enum Estado redefinido para alinear exactamente con el ENUM de MySQL
 *
 * Columnas BD: id, pasajero_id, operador_id, vehiculo_id, origen_lat, origen_lng,
 *              origen_nombre, destino_lat, destino_lng, destino_nombre, distancia_km,
 *              duracion_min, costo, estado, metodo_pago, cancelado_por,
 *              created_at, updated_at
 */
public class Viaje {

    /**
     * Ciclo de vida de un viaje B2C.
     * Cada valor tiene su equivalente exacto en el ENUM de MySQL (ver toDb()).
     */
    public enum Estado {
        SOLICITADO,   // pasajero creó la solicitud
        ASIGNADO,     // sistema asignó operador, esperando aceptación
        ACEPTADO,     // operador aceptó, va en camino al origen
        EN_CAMINO,    // operador recogió al pasajero, viaje en curso
        EN_CURSO,     // alias descriptivo, equivale a en_camino en BD
        COMPLETADO,   // llegaron al destino
        CANCELADO;    // cancelado por pasajero, operador o sistema

        /** Convierte el valor Java al string exacto del ENUM en MySQL. */
        public String toDb() {
            return switch (this) {
                case SOLICITADO -> "solicitado";
                case ASIGNADO   -> "asignado";
                case ACEPTADO   -> "aceptado";
                case EN_CAMINO  -> "en_camino";
                case EN_CURSO   -> "en_curso";
                case COMPLETADO -> "completado";
                case CANCELADO  -> "cancelado";
            };
        }

        /** Construye el enum a partir del string que devuelve MySQL. */
        public static Estado fromDb(String valor) {
            return switch (valor) {
                case "solicitado" -> SOLICITADO;
                case "asignado"   -> ASIGNADO;
                case "aceptado"   -> ACEPTADO;
                case "en_camino"  -> EN_CAMINO;
                case "en_curso"   -> EN_CURSO;
                case "completado" -> COMPLETADO;
                case "cancelado"  -> CANCELADO;
                default -> throw new IllegalArgumentException("Estado desconocido: " + valor);
            };
        }

        /** Etiqueta en español para mostrar en JSP. */
        public String etiqueta() {
            return switch (this) {
                case SOLICITADO -> "Buscando operador";
                case ASIGNADO   -> "Operador asignado";
                case ACEPTADO   -> "Operador en camino";
                case EN_CAMINO  -> "En camino al destino";
                case EN_CURSO   -> "En curso";
                case COMPLETADO -> "Completado";
                case CANCELADO  -> "Cancelado";
            };
        }
    }

    // ── Campos principales ──────────────────────────────────────────────────

    private int    id;
    private int    pasajeroId;
    private int    operadorId;    // 0 si aún no asignado (BD: NULL)
    private int    vehiculoId;    // 0 si aún no asignado (BD: NULL)

    // Origen
    private double origenLat;
    private double origenLng;
    private String origenNombre;

    // Destino
    private double destinoLat;
    private double destinoLng;
    private String destinoNombre;

    // Métricas (calculadas por Azure Maps al confirmar el viaje)
    private double distanciaKm;
    private int    duracionMin;
    private double costo;

    // Estado del ciclo de vida
    private Estado estado;
    private String metodoPago;    // "efectivo" | "tarjeta"
    private String canceladoPor;  // "pasajero" | "operador" | "sistema"

    // Timestamps
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Campos enriquecidos (vienen de JOINs, no de columnas directas)
    private String pasajeroNombre;
    private String operadorNombre;
    private double operadorScore;
    private String vehiculoModelo;
    private String vehiculoPlaca;
    private int    calificacionDada; // -1 si no se ha calificado aún

    // ── Constructor vacío ───────────────────────────────────────────────────
    public Viaje() {
        this.calificacionDada = -1;
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    public boolean estaActivo() {
        return estado == Estado.SOLICITADO
            || estado == Estado.ASIGNADO
            || estado == Estado.ACEPTADO
            || estado == Estado.EN_CAMINO
            || estado == Estado.EN_CURSO;
    }

    public boolean puedeCalificarse() {
        return estado == Estado.COMPLETADO && calificacionDada < 0;
    }

    // ── Getters y Setters ───────────────────────────────────────────────────

    public int getId()                           { return id; }
    public void setId(int id)                    { this.id = id; }

    public int getPasajeroId()                   { return pasajeroId; }
    public void setPasajeroId(int v)             { this.pasajeroId = v; }

    public int getOperadorId()                   { return operadorId; }
    public void setOperadorId(int v)             { this.operadorId = v; }

    public int getVehiculoId()                   { return vehiculoId; }
    public void setVehiculoId(int v)             { this.vehiculoId = v; }

    public double getOrigenLat()                 { return origenLat; }
    public void setOrigenLat(double v)           { this.origenLat = v; }

    public double getOrigenLng()                 { return origenLng; }
    public void setOrigenLng(double v)           { this.origenLng = v; }

    public String getOrigenNombre()              { return origenNombre; }
    public void setOrigenNombre(String v)        { this.origenNombre = v; }

    public double getDestinoLat()                { return destinoLat; }
    public void setDestinoLat(double v)          { this.destinoLat = v; }

    public double getDestinoLng()                { return destinoLng; }
    public void setDestinoLng(double v)          { this.destinoLng = v; }

    public String getDestinoNombre()             { return destinoNombre; }
    public void setDestinoNombre(String v)       { this.destinoNombre = v; }

    public double getDistanciaKm()               { return distanciaKm; }
    public void setDistanciaKm(double v)         { this.distanciaKm = v; }

    public int getDuracionMin()                  { return duracionMin; }
    public void setDuracionMin(int v)            { this.duracionMin = v; }

    public double getCosto()                     { return costo; }
    public void setCosto(double v)               { this.costo = v; }

    public Estado getEstado()                    { return estado; }
    public void setEstado(Estado v)              { this.estado = v; }

    public String getEstadoTexto()               { return estado != null ? estado.etiqueta() : ""; }
    public String getEstadoNombre()              { return estado != null ? estado.name() : ""; }
    public String getEstadoClase() {
        if (estado == null) return "badge-gris";
        return switch (estado) {
            case SOLICITADO, ASIGNADO, ACEPTADO, EN_CAMINO, EN_CURSO -> "badge-naranja";
            case COMPLETADO -> "badge-verde";
            case CANCELADO -> "badge-rojo";
        };
    }

    public String getMetodoPago()                { return metodoPago; }
    public void setMetodoPago(String v)          { this.metodoPago = v; }

    public String getCanceladoPor()              { return canceladoPor; }
    public void setCanceladoPor(String v)        { this.canceladoPor = v; }

    public LocalDateTime getCreatedAt()          { return createdAt; }
    public void setCreatedAt(LocalDateTime v)    { this.createdAt = v; }

    public LocalDateTime getUpdatedAt()          { return updatedAt; }
    public void setUpdatedAt(LocalDateTime v)    { this.updatedAt = v; }

    // Campos enriquecidos
    public String getPasajeroNombre()             { return pasajeroNombre; }
    public void setPasajeroNombre(String v)       { this.pasajeroNombre = v; }

    public String getOperadorNombre()             { return operadorNombre; }
    public void setOperadorNombre(String v)       { this.operadorNombre = v; }

    public double getOperadorScore()              { return operadorScore; }
    public void setOperadorScore(double v)        { this.operadorScore = v; }

    public String getVehiculoModelo()             { return vehiculoModelo; }
    public void setVehiculoModelo(String v)       { this.vehiculoModelo = v; }

    public String getVehiculoPlaca()              { return vehiculoPlaca; }
    public void setVehiculoPlaca(String v)        { this.vehiculoPlaca = v; }

    public int getCalificacionDada()              { return calificacionDada; }
    public void setCalificacionDada(int v)        { this.calificacionDada = v; }
}
