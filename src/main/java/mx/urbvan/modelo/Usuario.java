package mx.urbvan.modelo;

/**
 * Usuario - POJO unificado para todos los roles del sistema.
 *
 * Roles posibles (valor exacto del ENUM en BD):
 *   "pasajero"      → acceso B2C, puede ser también empleado B2B
 *   "operador"      → recibe viajes B2C y rutas B2B
 *   "admin"         → panel de administración Urbvan
 *   "admin_empresa" → portal B2B corporativo
 *
 * CAMBIOS RESPECTO A v1:
 *   - v1 tenía clases separadas (Usuario para pasajero, Operador.java aparte)
 *   - v2 unifica todo aquí; el campo 'rol' distingue el tipo de usuario
 *   - Nuevos campos: calificacionPromedio, primerLogin, lat, lng (antes en tabla operadores)
 *   - Columnas BD: id, nombre, email, contrasena, rol, activo, lat, lng,
 *                  calificacion_promedio, primer_login
 */
public class Usuario {

    private int     id;
    private String  nombre;
    private String  email;
    private String  contrasena;            // SHA-256 hex - solo se usa al autenticar
    private String  rol;                   // valor directo del ENUM en BD (minúsculas)
    private boolean activo;

    // Posición en tiempo real (actualizada por ActualizarPosicionServlet - solo operadores)
    private Double  lat;
    private Double  lng;

    // Score compartido B2C + B2B (recalculado por sp_recalcular_score_operador)
    private double  calificacionPromedio;

    // Solo admin_empresa: TRUE si no ha visto el aviso de cambio de contraseña
    private boolean primerLogin;

    // ── Constructor vacío (requerido por DAOs) ──────────────────────────────
    public Usuario() {}

    // ── Helpers de rol (evitan comparaciones de String sueltas en Servlets) ─

    public boolean esPasajero()     { return "pasajero".equals(rol); }
    public boolean esOperador()     { return "operador".equals(rol); }
    public boolean esAdmin()        { return "admin".equals(rol); }
    public boolean esAdminEmpresa() { return "admin_empresa".equals(rol); }

    /**
     * Devuelve el rol en mayúsculas para guardarlo en sesión HTTP.
     * Ejemplo: "pasajero" → "PASAJERO"
     * FiltroSesion usa estos valores en mayúsculas para las comparaciones.
     */
    public String getRolSesion() {
        return rol != null ? rol.toUpperCase() : "";
    }

    // ── Getters y Setters ───────────────────────────────────────────────────

    public int getId()                        { return id; }
    public void setId(int id)                 { this.id = id; }

    public String getNombre()                 { return nombre; }
    public void setNombre(String nombre)      { this.nombre = nombre; }

    public String getEmail()                  { return email; }
    public void setEmail(String email)        { this.email = email; }

    public String getContrasena()             { return contrasena; }
    public void setContrasena(String c)       { this.contrasena = c; }

    public String getRol()                    { return rol; }
    public void setRol(String rol)            { this.rol = rol; }

    public boolean isActivo()                 { return activo; }
    public void setActivo(boolean activo)     { this.activo = activo; }

    public Double getLat()                    { return lat; }
    public void setLat(Double lat)            { this.lat = lat; }

    public Double getLng()                    { return lng; }
    public void setLng(Double lng)            { this.lng = lng; }

    public double getCalificacionPromedio()              { return calificacionPromedio; }
    public void setCalificacionPromedio(double c)        { this.calificacionPromedio = c; }

    public boolean isPrimerLogin()                       { return primerLogin; }
    public void setPrimerLogin(boolean primerLogin)      { this.primerLogin = primerLogin; }

    @Override
    public String toString() {
        return "Usuario{id=" + id + ", nombre='" + nombre + "', rol='" + rol + "', activo=" + activo + "}";
    }
}
