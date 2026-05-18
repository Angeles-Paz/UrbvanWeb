package mx.urbvan.servlet.operador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;

/**
 * CambiarEstadoViajeServlet — controla el progreso del viaje desde el operador.
 *
 * Acciones válidas:
 *   en_camino   → OPERADOR_EN_CAMINO  (salió hacia el pasajero)
 *   iniciar     → VIAJE_INICIADO      (recogió al pasajero)
 *   completar   → COMPLETADO          (llegaron al destino)
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/operador/CambiarEstadoViajeServlet.java
 */
public class CambiarEstadoViajeServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        int    idOperador = (int) req.getSession().getAttribute("id");
        String idViajeStr = req.getParameter("id_viaje");
        String accion     = req.getParameter("accion");

        if (idViajeStr == null || accion == null) {
            res.sendRedirect(req.getContextPath() + "/operador/panel");
            return;
        }

        try {
            int   idViaje = Integer.parseInt(idViajeStr);
            Viaje viaje   = new ViajeDAO().buscarPorId(idViaje);

            // Validar que el viaje pertenece a este operador
            if (viaje == null || viaje.getIdOperador() != idOperador) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
                return;
            }

            switch (accion) {

                case "en_camino" -> {
                    // Operador confirma que salió hacia el pasajero
                    new ViajeDAO().actualizarEstado(idViaje, Viaje.Estado.OPERADOR_EN_CAMINO);
                    res.sendRedirect(req.getContextPath() +
                        "/operador/viaje-activo?id=" + idViaje);
                }

                case "iniciar" -> {
                    // Operador confirmó que llegó al origen y recogió al pasajero
                    new ViajeDAO().actualizarEstado(idViaje, Viaje.Estado.VIAJE_INICIADO);
                    res.sendRedirect(req.getContextPath() +
                        "/operador/viaje-activo?id=" + idViaje);
                }

                case "completar" -> {
                    // Llegaron al destino
                    new ViajeDAO().actualizarEstado(idViaje, Viaje.Estado.COMPLETADO);

                    try (Connection conn = ConexionDB.obtener()) {
                        // Liberar al operador
                        String sqlOp = "UPDATE operadores SET disponible = 1 WHERE id_operador = ?";
                        try (PreparedStatement ps = conn.prepareStatement(sqlOp)) {
                            ps.setInt(1, idOperador);
                            ps.executeUpdate();
                        }

                        // Recalcular calificación promedio del operador
                        String sqlCal = """
                            UPDATE operadores SET calificacion_prom = (
                                SELECT COALESCE(AVG(puntuacion), 5.00)
                                FROM calificaciones WHERE id_operador = ?
                            ) WHERE id_operador = ?
                            """;
                        try (PreparedStatement ps = conn.prepareStatement(sqlCal)) {
                            ps.setInt(1, idOperador);
                            ps.setInt(2, idOperador);
                            ps.executeUpdate();
                        }
                    }

                    res.sendRedirect(req.getContextPath() +
                        "/operador/panel?viaje=completado");
                }

                default -> res.sendRedirect(req.getContextPath() + "/operador/panel");
            }

        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() +
                "/operador/panel?error=" + e.getMessage());
        }
    }
}
