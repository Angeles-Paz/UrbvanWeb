package mx.urbvan.servlet.operador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;

/**
 * PanelOperadorServlet — carga el dashboard del operador.
 *
 * Expone al JSP:
 *  - datos del operador y vehículo asignado
 *  - estado de disponibilidad actual
 *  - viaje activo si existe
 *  - solicitud pendiente si existe
 *  - contadores de servicios
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/operador/PanelOperadorServlet.java
 */
public class PanelOperadorServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int idOperador = (int) req.getSession().getAttribute("id");

        try (Connection conn = ConexionDB.obtener()) {

            // --- Datos del operador y vehículo ---
            String sqlOp = """
                SELECT o.nombre, o.apellido, o.correo, o.telefono,
                       o.disponible, o.calificacion_prom,
                       v.marca, v.modelo, v.placa, v.color, v.capacidad
                FROM operadores o
                LEFT JOIN vehiculos v ON v.id_vehiculo = o.id_vehiculo
                WHERE o.id_operador = ?
                """;
            try (PreparedStatement ps = conn.prepareStatement(sqlOp)) {
                ps.setInt(1, idOperador);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("op_nombre",    rs.getString("nombre"));
                    req.setAttribute("op_apellido",  rs.getString("apellido"));
                    req.setAttribute("op_correo",    rs.getString("correo"));
                    req.setAttribute("op_telefono",  rs.getString("telefono"));
                    req.setAttribute("op_disponible",rs.getInt("disponible"));
                    req.setAttribute("op_calificacion", rs.getDouble("calificacion_prom"));
                    req.setAttribute("veh_marca",    rs.getString("marca"));
                    req.setAttribute("veh_modelo",   rs.getString("modelo"));
                    req.setAttribute("veh_placa",    rs.getString("placa"));
                    req.setAttribute("veh_color",    rs.getString("color"));
                    req.setAttribute("veh_capacidad",rs.getInt("capacidad"));
                }
            }

            // --- Viaje activo ---
            Viaje viajeActivo = new ViajeDAO().buscarActivoPorOperador(idOperador);
            req.setAttribute("viaje_activo", viajeActivo);

            // --- Solicitud pendiente ---
            if (viajeActivo == null) {
                String sqlSol = """
                    SELECT sa.id_solicitud, sa.id_viaje, sa.fecha_envio,
                           v.origen_direccion, v.destino_direccion,
                           v.precio_total, v.distancia_km, v.eta_viaje_min,
                           CONCAT(u.nombre,' ',u.apellido) AS pasajero,
                           u.telefono AS tel_pasajero
                    FROM solicitudes_asignacion sa
                    JOIN viajes   v ON v.id_viaje   = sa.id_viaje
                    JOIN usuarios u ON u.id_usuario = v.id_usuario
                    WHERE sa.id_operador = ? AND sa.estado = 'PENDIENTE'
                    ORDER BY sa.fecha_envio DESC LIMIT 1
                    """;
                try (PreparedStatement ps = conn.prepareStatement(sqlSol)) {
                    ps.setInt(1, idOperador);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        req.setAttribute("sol_id",       rs.getInt("id_solicitud"));
                        req.setAttribute("sol_viaje_id", rs.getInt("id_viaje"));
                        req.setAttribute("sol_origen",   rs.getString("origen_direccion"));
                        req.setAttribute("sol_destino",  rs.getString("destino_direccion"));
                        req.setAttribute("sol_precio",   rs.getDouble("precio_total"));
                        req.setAttribute("sol_distancia",rs.getDouble("distancia_km"));
                        req.setAttribute("sol_eta",      rs.getInt("eta_viaje_min"));
                        req.setAttribute("sol_pasajero", rs.getString("pasajero"));
                        req.setAttribute("sol_tel",      rs.getString("tel_pasajero"));
                        req.setAttribute("sol_fecha",    rs.getTimestamp("fecha_envio"));
                    }
                }
            }

            // --- Contadores ---
            String sqlCount = """
                SELECT
                    COUNT(*) AS total,
                    SUM(CASE WHEN estado='COMPLETADO' THEN 1 ELSE 0 END) AS completados,
                    SUM(CASE WHEN estado='CANCELADO'  THEN 1 ELSE 0 END) AS cancelados
                FROM viajes WHERE id_operador = ?
                """;
            try (PreparedStatement ps = conn.prepareStatement(sqlCount)) {
                ps.setInt(1, idOperador);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    req.setAttribute("c_total",      rs.getInt("total"));
                    req.setAttribute("c_completados",rs.getInt("completados"));
                    req.setAttribute("c_cancelados", rs.getInt("cancelados"));
                }
            }

        } catch (Exception e) {
            req.setAttribute("error_panel", "Error al cargar datos: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/operador/panel.jsp")
           .forward(req, res);
    }

    // POST — cambiar disponibilidad (toggle)
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int idOperador = (int) req.getSession().getAttribute("id");
        String accion  = req.getParameter("accion");

        if ("disponibilidad".equals(accion)) {
            String valor = req.getParameter("disponible");
            try (Connection conn = ConexionDB.obtener();
                 PreparedStatement ps = conn.prepareStatement(
                     "UPDATE operadores SET disponible = ? WHERE id_operador = ?")) {
                ps.setInt(1, "1".equals(valor) ? 1 : 0);
                ps.setInt(2, idOperador);
                ps.executeUpdate();
            } catch (Exception e) { /* ignorar */ }
        }

        res.sendRedirect(req.getContextPath() + "/operador/panel");
    }
}
