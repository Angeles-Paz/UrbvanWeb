package mx.urbvan.modelo;

import java.time.LocalDateTime;

/**
 * Empresa - POJO para empresas cliente del módulo B2B.
 * Columnas BD: id, nombre, score, gasto_total, activa, created_at
 */
public class Empresa {

    private int    id;
    private String nombre;
    private double score;        // 0-100
    private double gastoTotal;
    private boolean activa;
    private LocalDateTime createdAt;

    // Campos enriquecidos (vistas / JOINs)
    private int    empleadosActivos;
    private int    rutasCompletadas;
    private int    rutasEnCurso;
    private double gastoVerificado;

    public Empresa() {}

    // Helpers
    public String getEtiquetaScore() {
        if (score >= 80) return "Excelente";
        if (score >= 60) return "Bueno";
        if (score >= 40) return "Regular";
        if (score >= 20) return "Malo";
        return "Problemático";
    }
    public String getClaseScore() {
        if (score >= 80) return "badge-verde";
        if (score >= 60) return "badge-naranja";
        return "badge-rojo";
    }

    // Getters y setters
    public int getId()                              { return id; }
    public void setId(int id)                       { this.id = id; }
    public String getNombre()                       { return nombre; }
    public void setNombre(String nombre)            { this.nombre = nombre; }
    public double getScore()                        { return score; }
    public void setScore(double score)              { this.score = score; }
    public double getGastoTotal()                   { return gastoTotal; }
    public void setGastoTotal(double v)             { this.gastoTotal = v; }
    public boolean isActiva()                       { return activa; }
    public void setActiva(boolean activa)           { this.activa = activa; }
    public LocalDateTime getCreatedAt()             { return createdAt; }
    public void setCreatedAt(LocalDateTime v)       { this.createdAt = v; }
    public int getEmpleadosActivos()                { return empleadosActivos; }
    public void setEmpleadosActivos(int v)          { this.empleadosActivos = v; }
    public int getRutasCompletadas()                { return rutasCompletadas; }
    public void setRutasCompletadas(int v)          { this.rutasCompletadas = v; }
    public int getRutasEnCurso()                    { return rutasEnCurso; }
    public void setRutasEnCurso(int v)              { this.rutasEnCurso = v; }
    public double getGastoVerificado()              { return gastoVerificado; }
    public void setGastoVerificado(double v)        { this.gastoVerificado = v; }
}
