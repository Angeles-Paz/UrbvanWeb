package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;
import java.util.List;

/**
 * DashboardPasajeroServlet - pantalla de inicio del pasajero.
 *
 * Expone al JSP:
 *   - "usuario"       → Map con nombre, email, calificacion_promedio
 *   - "viajeActivo"   → Viaje (null si no hay ninguno en curso)
 *   - "historial"     → List<Viaje> últimos 5 viajes completados/cancelados
 *   - "totalViajes"   → int con el total histórico del pasajero
 *
 * CAMBIOS vs v1:
 *   - Perfil: columnas viejas (id_usuario, correo, apellido, telefono, fecha_registro)
 *     → nuevas (id, email, calificacion_promedio). Sin apellido ni teléfono en v2.
 *   - ViajeDAO: buscarViajeActivoDeUsuario() → buscarActivoPasajero()  [línea ~51 del v1]
 *   - ViajeDAO: obtenerHistorial() / listarViajesDeUsuario() → listarDePasajero()
 *
 * URL: /pasajero/dashboard
 */
@WebServlet("/pasajero/dashboard")
public class DashboardPasajeroServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        int uid = (int) session.getAttribute("id");

        try {
            // ── 1. Perfil del usuario ────────────────────────────────────────
            // v1 usaba: SELECT nombre, apellido, correo, telefono, fecha_registro
            //           FROM usuarios WHERE id_usuario = ?
            // v2 usa  : SELECT nombre, email, calificacion_promedio
            //           FROM usuarios WHERE id = ?
            cargarPerfil(req, uid);

            // ── 2. Viaje activo ──────────────────────────────────────────────
            // v1 llamaba: ViajeDAO.buscarViajeActivoDeUsuario(idUsuario)  ← método que no existe en v2
            // v2 llama  : ViajeDAO.buscarActivoPasajero(uid)
            Viaje viajeActivo = ViajeDAO.buscarActivoPasajero(uid);
            req.setAttribute("viajeActivo", viajeActivo);

            // ── 3. Historial reciente (últimos 5) ────────────────────────────
            // v1 llamaba: ViajeDAO.obtenerHistorial(idUsuario) o listarViajesDeUsuario()
            // v2 llama  : ViajeDAO.listarDePasajero(uid)
            List<Viaje> historial = ViajeDAO.listarDePasajero(uid);
            int totalViajes = historial.size();
            // Limitar a 5 para el dashboard (el historial completo va en /pasajero/historial)
            if (historial.size() > 5) {
                historial = historial.subList(0, 5);
            }
            req.setAttribute("historial",   historial);
            req.setAttribute("totalViajes", totalViajes);

            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/dashboard.jsp").forward(req, res);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar el dashboard: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/dashboard.jsp").forward(req, res);
        }
    }

    /**
     * Carga el perfil del pasajero y lo pone en el atributo "usuario" del request.
     *
     * v1 consultaba columnas: id_usuario, nombre, apellido, correo, telefono, fecha_registro
     * v2 consulta columnas  : id, nombre, email, calificacion_promedio
     * (apellido y telefono ya no existen en el schema v2)
     */
    private void cargarPerfil(HttpServletRequest req, int uid) throws Exception {
        String sql = """
                SELECT id, nombre, email, calificacion_promedio, rol
                FROM   usuarios
                WHERE  id = ?
                """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, uid);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                // Usar un Map simple para no crear una clase extra solo para esto
                java.util.Map<String, Object> perfil = new java.util.HashMap<>();
                perfil.put("id",                   rs.getInt("id"));
                perfil.put("nombre",               rs.getString("nombre"));
                perfil.put("email",                rs.getString("email"));
                perfil.put("calificacionPromedio", rs.getDouble("calificacion_promedio"));
                perfil.put("rol",                  rs.getString("rol"));
                req.setAttribute("usuario", perfil);
            }
        }
    }
}
