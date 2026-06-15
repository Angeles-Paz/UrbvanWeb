package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * RutaAsiento - asignación de empleado a asiento en una ruta B2B.
 * Columnas BD: id, ruta_id, empleado_id, numero_asiento, activo, created_at
 */
public class RutaAsiento {

    private int    id;
    private int    rutaId;
    private int    empleadoId;
    private int    numeroAsiento;
    private boolean activo;
    private LocalDateTime createdAt;

    // Enriquecidos
    private String empleadoNombre;
    private String empleadoEmail;

    public RutaAsiento() {}

    public int getId()                          { return id; }
    public void setId(int id)                   { this.id = id; }
    public int getRutaId()                      { return rutaId; }
    public void setRutaId(int v)                { this.rutaId = v; }
    public int getEmpleadoId()                  { return empleadoId; }
    public void setEmpleadoId(int v)            { this.empleadoId = v; }
    public int getNumeroAsiento()               { return numeroAsiento; }
    public void setNumeroAsiento(int v)         { this.numeroAsiento = v; }
    public boolean isActivo()                   { return activo; }
    public void setActivo(boolean v)            { this.activo = v; }
    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime v)   { this.createdAt = v; }
    public String getEmpleadoNombre()           { return empleadoNombre; }
    public void setEmpleadoNombre(String v)     { this.empleadoNombre = v; }
    public String getEmpleadoEmail()            { return empleadoEmail; }
    public void setEmpleadoEmail(String v)      { this.empleadoEmail = v; }
}
