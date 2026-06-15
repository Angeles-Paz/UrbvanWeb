package mx.urbvan.servlet.auth;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;

import java.io.IOException;
import java.sql.*;

/**
 * LoginServlet - autenticación unificada para todos los roles.
 *
 * CAMBIOS RESPECTO A v1:
 *   - v1 hacía queries separados a tres tablas (usuarios, operadores, administradores).
 *   - v2 hace UN solo query a la tabla 'usuarios' unificada y lee el campo 'rol'.
 *   - Nuevo: detecta si el usuario también es empleado B2B (empresa_usuarios)
 *     y guarda 'esEmpleado' y 'empresaId' en sesión.
 *   - Nuevo: guarda 'primerLogin' en sesión para admin_empresa.
 *   - Redirección basada en el rol leído de BD (no hardcodeada por tabla).
 *
 * Atributos de sesión que se establecen aquí:
 *   "id"          → usuarios.id
 *   "nombre"      → usuarios.nombre
 *   "email"       → usuarios.email
 *   "rol"         → usuarios.rol.toUpperCase() - "PASAJERO"|"OPERADOR"|"ADMIN"|"ADMIN_EMPRESA"
 *   "esEmpleado"  → true si tiene fila activa en empresa_usuarios con rol='empleado'
 *   "empresaId"   → empresa_usuarios.empresa_id (si aplica)
 *   "primerLogin" → true si admin_empresa y primer_login=TRUE en BD
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    // ── GET: mostrar formulario ──────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        // Si ya tiene sesión activa, redirigir a su dashboard
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("rol") != null) {
            res.sendRedirect(req.getContextPath() + dashboardDe((String) session.getAttribute("rol")));
            return;
        }
        req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
    }

    // ── POST: procesar autenticación ─────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String email     = req.getParameter("email");
        String contrasena = req.getParameter("contrasena");

        if (email == null || email.isBlank() || contrasena == null || contrasena.isBlank()) {
            req.setAttribute("error", "Por favor ingresa tu correo y contraseña.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
            return;
        }

        String hashIngresado = HashUtil.sha256(contrasena);

        try (Connection conn = ConexionDB.obtener()) {

            // ── Query único: tabla usuarios unificada ────────────────────────
            // v1 tenía 3 queries separados; v2 usa uno solo.
            String sql = """
                    SELECT id, nombre, email, rol, activo, primer_login
                    FROM   usuarios
                    WHERE  email     = ?
                      AND  contrasena = ?
                    """;

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, email.trim());
                ps.setString(2, hashIngresado);
                ResultSet rs = ps.executeQuery();

                if (!rs.next()) {
                    req.setAttribute("error", "Correo o contraseña incorrectos.");
                    req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
                    return;
                }

                // Usuario encontrado - verificar que esté activo
                boolean activo = rs.getBoolean("activo");
                if (!activo) {
                    req.setAttribute("error", "Tu cuenta está deshabilitada. Contacta al administrador.");
                    req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
                    return;
                }

                int    userId     = rs.getInt("id");
                String nombre     = rs.getString("nombre");
                String emailDb    = rs.getString("email");
                String rol        = rs.getString("rol");           // "pasajero", "operador", etc.
                boolean primerLoginFlag = rs.getBoolean("primer_login");

                // ── Crear sesión ─────────────────────────────────────────────
                HttpSession session = req.getSession(true);
                session.setAttribute("id",     userId);
                session.setAttribute("nombre", nombre);
                session.setAttribute("email",  emailDb);
                session.setAttribute("rol",    rol.toUpperCase()); // FiltroSesion usa mayúsculas

                // ── Datos B2B adicionales para pasajeros con rol empleado ────
                // Un pasajero puede ser también empleado B2B en alguna empresa
                if ("pasajero".equals(rol)) {
                    cargarDatosEmpleado(conn, userId, session);
                }

                // ── Datos B2B para admin_empresa ─────────────────────────────
                if ("admin_empresa".equals(rol)) {
                    cargarDatosAdminEmpresa(conn, userId, primerLoginFlag, session);
                }

                // ── Si es primer login de admin_empresa, marcar como visto ──
                // (el aviso se muestra en su JSP; aquí solo lo ponemos en sesión)
                // La BD se actualiza cuando el admin cierra el aviso (endpoint aparte)
                session.setAttribute("primerLogin", primerLoginFlag);

                // ── Redirigir a su dashboard ──────────────────────────────────
                res.sendRedirect(req.getContextPath() + dashboardDe(rol.toUpperCase()));
            }

        } catch (Exception e) {
            req.setAttribute("error", "Error interno al iniciar sesión. Intenta más tarde.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
        }
    }

    // ── Helpers privados ─────────────────────────────────────────────────────

    /**
     * Si el pasajero también es empleado en alguna empresa activa,
     * guarda esEmpleado=true y empresaId en sesión.
     */
    private void cargarDatosEmpleado(Connection conn, int userId, HttpSession session)
            throws SQLException {

        String sql = """
                SELECT empresa_id
                FROM   empresa_usuarios
                WHERE  usuario_id = ?
                  AND  rol        = 'empleado'
                  AND  activo     = TRUE
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                session.setAttribute("esEmpleado", true);
                session.setAttribute("empresaId",  rs.getInt("empresa_id"));
            } else {
                session.setAttribute("esEmpleado", false);
            }
        }
    }

    /**
     * Para admin_empresa: carga el empresaId y la bandera de primer login.
     */
    private void cargarDatosAdminEmpresa(Connection conn, int userId,
                                          boolean primerLogin, HttpSession session)
            throws SQLException {

        String sql = """
                SELECT empresa_id
                FROM   empresa_usuarios
                WHERE  usuario_id = ?
                  AND  rol        = 'admin_empresa'
                  AND  activo     = TRUE
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                session.setAttribute("empresaId", rs.getInt("empresa_id"));
            }
        }
    }

    /** URL del dashboard por rol (en mayúsculas, como lo guarda la sesión). */
    private String dashboardDe(String rolMayusculas) {
        return switch (rolMayusculas) {
            case "PASAJERO"      -> "/pasajero/solicitar";
            case "OPERADOR"      -> "/operador/panel";
            case "ADMIN"         -> "/admin/dashboard";
            case "ADMIN_EMPRESA" -> "/b2b/empresa/dashboard";
            default              -> "/login";
        };
    }
}
