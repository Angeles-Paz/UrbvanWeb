package mx.urbvan.servlet.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import java.io.IOException;
import java.sql.*;

/**
 * DashboardAdminServlet - estadísticas generales para el panel admin.
 * CAMBIOS vs v1: counts de usuarios y operadores ahora vienen de tabla unificada
 * 'usuarios' filtrando por rol, no de tablas separadas.
 */
@WebServlet("/admin/dashboard")
public class DashboardAdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try (Connection c = ConexionDB.obtener()) {
            // Conteos desde tabla unificada (v1 consultaba tablas separadas)
            req.setAttribute("totalPasajeros", contarRol(c, "pasajero"));
            req.setAttribute("totalOperadores", contarRol(c, "operador"));
            req.setAttribute("totalVehiculos",  contarVehiculos(c));
            req.setAttribute("totalEmpresas",   contarEmpresas(c));
            // Viajes por estado
            req.setAttribute("viajesActivos",    ViajeDAO.contarPorEstado("en_camino"));
            req.setAttribute("viajesCompletados",ViajeDAO.contarPorEstado("completado"));
            req.setAttribute("viajesCancelados", ViajeDAO.contarPorEstado("cancelado"));
            // Últimos viajes
            req.setAttribute("ultimosViajes", ViajeDAO.listarTodos());
            req.getRequestDispatcher("/WEB-INF/vistas/admin/dashboard.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar estadísticas.");
            req.getRequestDispatcher("/WEB-INF/vistas/admin/dashboard.jsp").forward(req, res);
        }
    }

    private int contarRol(Connection c, String rol) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) FROM usuarios WHERE rol=? AND activo=TRUE")) {
            ps.setString(1, rol);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }
    private int contarVehiculos(Connection c) throws SQLException {
        try (Statement st = c.createStatement()) {
            ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM vehiculos WHERE activo=TRUE");
            return rs.next() ? rs.getInt(1) : 0;
        }
    }
    private int contarEmpresas(Connection c) throws SQLException {
        try (Statement st = c.createStatement()) {
            ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM empresas WHERE activa=TRUE");
            return rs.next() ? rs.getInt(1) : 0;
        }
    }
}
