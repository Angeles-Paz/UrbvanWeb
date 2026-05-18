package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;

/**
 * CancelarViajeServlet — cancela un viaje activo del pasajero.
 *
 * Solo permite cancelar si el viaje está en estado:
 *   EN_ASIGNACION o ACEPTADO
 *
 * Si ya inició (VIAJE_INICIADO) no se puede cancelar.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/CancelarViajeServlet.java
 */
public class CancelarViajeServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String idStr  = req.getParameter("id_viaje");
        int idUsuario = (int) req.getSession().getAttribute("id");

        if (idStr == null || idStr.isBlank()) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
            return;
        }

        try {
            int   idViaje = Integer.parseInt(idStr);
            Viaje viaje   = new ViajeDAO().buscarPorId(idViaje);

            // Validar que el viaje pertenece al usuario en sesión
            if (viaje == null || viaje.getIdUsuario() != idUsuario) {
                res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
                return;
            }

            // Validar que el viaje se puede cancelar
            Viaje.Estado estado = viaje.getEstado();
            boolean cancelable  = estado == Viaje.Estado.EN_ASIGNACION
                               || estado == Viaje.Estado.ACEPTADO
                               || estado == Viaje.Estado.SOLICITADO;

            if (!cancelable) {
                // Viaje ya iniciado — no se puede cancelar, redirigir al seguimiento
                res.sendRedirect(req.getContextPath() +
                    "/pasajero/estado-viaje?id=" + idViaje + "&error=noCancelable");
                return;
            }

            try (Connection conn = ConexionDB.obtener()) {

                // --- 1. Cancelar el viaje ---
                String sqlViaje = "UPDATE viajes SET estado = 'CANCELADO' WHERE id_viaje = ?";
                try (PreparedStatement ps = conn.prepareStatement(sqlViaje)) {
                    ps.setInt(1, idViaje);
                    ps.executeUpdate();
                }

                // --- 2. Marcar solicitudes pendientes como canceladas ---
                String sqlSol = """
                    UPDATE solicitudes_asignacion
                    SET estado = 'EXPIRADA', fecha_respuesta = NOW()
                    WHERE id_viaje = ? AND estado = 'PENDIENTE'
                    """;
                try (PreparedStatement ps = conn.prepareStatement(sqlSol)) {
                    ps.setInt(1, idViaje);
                    ps.executeUpdate();
                }

                // --- 3. Liberar al operador si estaba asignado ---
                if (viaje.getIdOperador() > 0) {
                    String sqlOp = "UPDATE operadores SET disponible = 1 WHERE id_operador = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlOp)) {
                        ps.setInt(1, viaje.getIdOperador());
                        ps.executeUpdate();
                    }
                }

                // --- 4. Cancelar el pago si existía ---
                String sqlPago = """
                    UPDATE pagos SET estado_pago = 'CANCELADO'
                    WHERE id_viaje = ? AND estado_pago = 'APROBADO'
                    """;
                try (PreparedStatement ps = conn.prepareStatement(sqlPago)) {
                    ps.setInt(1, idViaje);
                    ps.executeUpdate();
                }
            }

            // Redirigir al dashboard con mensaje de cancelación
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard?viaje=cancelado");

        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() +
                "/pasajero/dashboard?error=cancelacion");
        }
    }
}
