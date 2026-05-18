package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DashboardPasajeroServlet
 *
 * Carga y expone al JSP:
 *  - datos del perfil del usuario
 *  - viaje activo (si existe)
 *  - últimos 5 viajes completados
 *  - contadores para las tarjetas de resumen
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/DashboardPasajeroServlet.java
 */
public class DashboardPasajeroServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int idUsuario = (int) req.getSession().getAttribute("id");

        try (Connection conn = ConexionDB.obtener()) {

            // --- Perfil del usuario ---
            String sqlPerfil = "SELECT nombre, apellido, correo, telefono, fecha_registro " +
                               "FROM usuarios WHERE id_usuario = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlPerfil)) {
                ps.setInt(1, idUsuario);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("u_nombre",   rs.getString("nombre"));
                    req.setAttribute("u_apellido", rs.getString("apellido"));
                    req.setAttribute("u_correo",   rs.getString("correo"));
                    req.setAttribute("u_telefono", rs.getString("telefono"));
                    req.setAttribute("u_registro", rs.getTimestamp("fecha_registro"));
                }
            }

            // --- Viaje activo ---
            Viaje viajeActivo = new ViajeDAO().buscarActivoPorUsuario(idUsuario);
            req.setAttribute("viaje_activo", viajeActivo);

            // --- Contadores ---
            String sqlContadores = """
                SELECT
                    COUNT(*) AS total,
                    SUM(CASE WHEN estado = 'COMPLETADO' THEN 1 ELSE 0 END) AS completados,
                    SUM(CASE WHEN estado = 'CANCELADO'  THEN 1 ELSE 0 END) AS cancelados,
                    COALESCE(SUM(CASE WHEN estado = 'COMPLETADO' THEN precio_total ELSE 0 END), 0) AS gastado
                FROM viajes WHERE id_usuario = ?
                """;
            try (PreparedStatement ps = conn.prepareStatement(sqlContadores)) {
                ps.setInt(1, idUsuario);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("c_total",      rs.getInt("total"));
                    req.setAttribute("c_completados",rs.getInt("completados"));
                    req.setAttribute("c_cancelados", rs.getInt("cancelados"));
                    req.setAttribute("c_gastado",    rs.getDouble("gastado"));
                }
            }

            // --- Últimos 5 viajes completados o cancelados ---
            String sqlHistorial = """
                SELECT v.id_viaje, v.origen_direccion, v.destino_direccion,
                       v.precio_total, v.estado, v.fecha_solicitud, v.fecha_fin,
                       CONCAT(o.nombre,' ',o.apellido) AS operador,
                       COALESCE(c.puntuacion, 0) AS puntuacion
                FROM viajes v
                LEFT JOIN operadores   o ON o.id_operador = v.id_operador
                LEFT JOIN calificaciones c ON c.id_viaje  = v.id_viaje
                WHERE v.id_usuario = ?
                  AND v.estado IN ('COMPLETADO','CANCELADO')
                ORDER BY v.fecha_solicitud DESC
                LIMIT 5
                """;
            List<Object[]> historial = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sqlHistorial)) {
                ps.setInt(1, idUsuario);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    historial.add(new Object[]{
                        rs.getInt("id_viaje"),
                        rs.getString("origen_direccion"),
                        rs.getString("destino_direccion"),
                        rs.getDouble("precio_total"),
                        rs.getString("estado"),
                        rs.getTimestamp("fecha_solicitud"),
                        rs.getTimestamp("fecha_fin"),
                        rs.getString("operador"),
                        rs.getInt("puntuacion")
                    });
                }
            }
            req.setAttribute("historial", historial);

        } catch (Exception e) {
            req.setAttribute("error_dashboard", "No se pudieron cargar algunos datos: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/pasajero/dashboard.jsp")
           .forward(req, res);
    }
}
