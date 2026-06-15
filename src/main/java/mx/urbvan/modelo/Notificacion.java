package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * Notificacion - notificación en plataforma para cualquier rol.
 * Columnas BD: id, usuario_id, tipo, mensaje, ruta_id, viaje_id, leida, created_at
 */
public class Notificacion {

    private int    id;
    private int    usuarioId;
    private String tipo;
    private String mensaje;
    private Integer rutaId;
    private Integer viajeId;
    private boolean leida;
    private LocalDateTime createdAt;

    public Notificacion() {}

    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }
    public int getUsuarioId()                   { return usuarioId; }
    public void setUsuarioId(int v)             { this.usuarioId = v; }
    public String getTipo()                     { return tipo; }
    public void setTipo(String v)               { this.tipo = v; }
    public String getMensaje()                  { return mensaje; }
    public void setMensaje(String v)            { this.mensaje = v; }
    public Integer getRutaId()                  { return rutaId; }
    public void setRutaId(Integer v)            { this.rutaId = v; }
    public Integer getViajeId()                 { return viajeId; }
    public void setViajeId(Integer v)           { this.viajeId = v; }
    public boolean isLeida()                    { return leida; }
    public void setLeida(boolean v)             { this.leida = v; }
    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime v)   { this.createdAt = v; }
}
