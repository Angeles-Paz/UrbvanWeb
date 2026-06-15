package mx.urbvan.modelo;

import java.time.LocalDateTime;

/** Evento operativo de una ruta B2B: inicio, llegada a parada, salida y finalización. */
public class RutaB2BEvento {

    public enum Tipo {
        INICIO_RUTA,
        LLEGADA_PARADA,
        SALIDA_PARADA,
        FIN_RUTA;

        public String toDb() { return name().toLowerCase(); }

        public static Tipo fromDb(String valor) {
            if (valor == null) return INICIO_RUTA;
            return switch (valor.toLowerCase()) {
                case "inicio_ruta"    -> INICIO_RUTA;
                case "llegada_parada" -> LLEGADA_PARADA;
                case "salida_parada"  -> SALIDA_PARADA;
                case "fin_ruta"       -> FIN_RUTA;
                default -> INICIO_RUTA;
            };
        }

        public String etiqueta() {
            return switch (this) {
                case INICIO_RUTA    -> "Viaje iniciado";
                case LLEGADA_PARADA -> "Llegada a parada";
                case SALIDA_PARADA  -> "En camino al siguiente punto";
                case FIN_RUTA       -> "Ruta finalizada";
            };
        }
    }

    private int id;
    private int rutaId;
    private int operadorId;
    private Integer paradaId;
    private Integer ordenParada;
    private Tipo tipo;
    private double latitud;
    private double longitud;
    private String comentario;
    private LocalDateTime creadoEn;
    private String paradaNombre;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getRutaId() { return rutaId; }
    public void setRutaId(int rutaId) { this.rutaId = rutaId; }
    public int getOperadorId() { return operadorId; }
    public void setOperadorId(int operadorId) { this.operadorId = operadorId; }
    public Integer getParadaId() { return paradaId; }
    public void setParadaId(Integer paradaId) { this.paradaId = paradaId; }
    public Integer getOrdenParada() { return ordenParada; }
    public void setOrdenParada(Integer ordenParada) { this.ordenParada = ordenParada; }
    public Tipo getTipo() { return tipo; }
    public void setTipo(Tipo tipo) { this.tipo = tipo; }
    public double getLatitud() { return latitud; }
    public void setLatitud(double latitud) { this.latitud = latitud; }
    public double getLongitud() { return longitud; }
    public void setLongitud(double longitud) { this.longitud = longitud; }
    public String getComentario() { return comentario; }
    public void setComentario(String comentario) { this.comentario = comentario; }
    public LocalDateTime getCreadoEn() { return creadoEn; }
    public void setCreadoEn(LocalDateTime creadoEn) { this.creadoEn = creadoEn; }
    public String getParadaNombre() { return paradaNombre; }
    public void setParadaNombre(String paradaNombre) { this.paradaNombre = paradaNombre; }

    public String getTipoTexto() { return tipo != null ? tipo.etiqueta() : ""; }
    public String getTipoNombre() { return tipo != null ? tipo.name() : ""; }
}
