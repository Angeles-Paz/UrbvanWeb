package mx.urbvan.servlet.admin;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DashboardAdminServlet — carga métricas globales del sistema.
 *
 * Expone al JSP:
 *  - contadores generales (viajes, usuarios, operadores)
 *  - viajes activos en tiempo real
 *  - operadores con su estado actual
 *  - últimos 10 viajes del sistema
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/admin/DashboardAdminServlet.java
 */
public class DashboardAdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        try (Connection conn = ConexionDB.obtener()) {

            // --- Métricas generales ---
            String sqlMetricas = """
                SELECT
                    (SELECT COUNT(*) FROM viajes) AS total_viajes,
                    (SELECT COUNT(*) FROM viajes WHERE estado='COMPLETADO') AS completados,
                    (SELECT COUNT(*) FROM viajes WHERE estado NOT IN ('COMPLETADO','CANCELADO')) AS activos,
                    (SELECT COUNT(*) FROM usuarios WHERE activo=1) AS total_usuarios,
                    (SELECT COUNT(*) FROM operadores WHERE activo=1) AS total_operadores,
                    (SELECT COUNT(*) FROM operadores WHERE disponible=1) AS operadores_disponibles,
                    (SELECT COALESCE(SUM(precio_total),0) FROM viajes WHERE estado='COMPLETADO') AS ingresos
                """;
            try (PreparedStatement ps = conn.prepareStatement(sqlMetricas)) {
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("m_total_viajes",         rs.getInt("total_viajes"));
                    req.setAttribute("m_completados",          rs.getInt("completados"));
                    req.setAttribute("m_activos",              rs.getInt("activos"));
                    req.setAttribute("m_total_usuarios",       rs.getInt("total_usuarios"));
                    req.setAttribute("m_total_operadores",     rs.getInt("total_operadores"));
                    req.setAttribute("m_op_disponibles",       rs.getInt("operadores_disponibles"));
                    req.setAttribute("m_ingresos",             rs.getDouble("ingresos"));
                }
            }

            // --- Viajes activos ---
            String sqlActivos = """
                SELECT v.id_viaje, v.estado, v.precio_total,
                       v.origen_direccion, v.destino_direccion,
                       v.fecha_solicitud,
                       CONCAT(u.nombre,' ',u.apellido) AS pasajero,
                       CONCAT(o.nombre,' ',o.apellido) AS operador
                FROM viajes v
                JOIN usuarios u ON u.id_usuario = v.id_usuario
                LEFT JOIN operadores o ON o.id_operador = v.id_operador
                WHERE v.estado NOT IN ('COMPLETADO','CANCELADO')
                ORDER BY v.fecha_solicitud DESC
                """;
            List<Object[]> viajesActivos = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sqlActivos)) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    viajesActivos.add(new Object[]{
                        rs.getInt("id_viaje"),
                        rs.getString("estado"),
                        rs.getDouble("precio_total"),
                        rs.getString("origen_direccion"),
                        rs.getString("destino_direccion"),
                        rs.getTimestamp("fecha_solicitud"),
                        rs.getString("pasajero"),
                        rs.getString("operador")
                    });
                }
            }
            req.setAttribute("viajes_activos", viajesActivos);

            // --- Estado de operadores ---
            String sqlOps = """
                SELECT o.id_operador, CONCAT(o.nombre,' ',o.apellido) AS nombre,
                       o.disponible, o.calificacion_prom,
                       CONCAT(v.marca,' ',v.modelo,' (',v.placa,')') AS vehiculo,
                       (SELECT COUNT(*) FROM viajes WHERE id_operador=o.id_operador
                        AND estado='COMPLETADO') AS completados
                FROM operadores o
                LEFT JOIN vehiculos v ON v.id_vehiculo = o.id_vehiculo
                WHERE o.activo = 1
                ORDER BY o.disponible DESC, o.nombre ASC
                """;
            List<Object[]> operadores = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sqlOps)) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    operadores.add(new Object[]{
                        rs.getInt("id_operador"),
                        rs.getString("nombre"),
                        rs.getInt("disponible"),
                        rs.getDouble("calificacion_prom"),
                        rs.getString("vehiculo"),
                        rs.getInt("completados")
                    });
                }
            }
            req.setAttribute("operadores", operadores);

            // --- Últimos 10 viajes ---
            String sqlHistorial = """
                SELECT v.id_viaje, v.estado, v.precio_total,
                       v.fecha_solicitud, v.fecha_fin,
                       v.origen_direccion, v.destino_direccion,
                       CONCAT(u.nombre,' ',u.apellido) AS pasajero,
                       CONCAT(o.nombre,' ',o.apellido) AS operador
                FROM viajes v
                JOIN usuarios u ON u.id_usuario = v.id_usuario
                LEFT JOIN operadores o ON o.id_operador = v.id_operador
                ORDER BY v.fecha_solicitud DESC
                LIMIT 10
                """;
            List<Object[]> historial = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sqlHistorial)) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    historial.add(new Object[]{
                        rs.getInt("id_viaje"),
                        rs.getString("estado"),
                        rs.getDouble("precio_total"),
                        rs.getTimestamp("fecha_solicitud"),
                        rs.getTimestamp("fecha_fin"),
                        rs.getString("origen_direccion"),
                        rs.getString("destino_direccion"),
                        rs.getString("pasajero"),
                        rs.getString("operador")
                    });
                }
            }
            req.setAttribute("historial", historial);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar datos: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/admin/dashboard.jsp").forward(req, res);
    }
}
