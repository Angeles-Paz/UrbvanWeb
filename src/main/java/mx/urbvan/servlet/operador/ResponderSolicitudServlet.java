package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;
import java.io.IOException;
import java.sql.*;

/**
 * ResponderSolicitudServlet - operador acepta o rechaza un viaje.
 * CAMBIOS vs v1: usa tabla solicitudes_operador; el rechazo llama
 * AsignadorOperador.manejarRechazo() para la asignación en cascada.
 */
@WebServlet("/operador/responder-solicitud")
public class ResponderSolicitudServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int    uid      = (int) req.getSession().getAttribute("id");
        String respuesta= req.getParameter("respuesta"); // "aceptar" | "rechazar"
        int    viajeId  = Integer.parseInt(req.getParameter("viajeId"));
        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getEstado() != Viaje.Estado.ASIGNADO) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
                return;
            }
            if ("aceptar".equals(respuesta)) {
                actualizarSolicitud(viajeId, uid, "aceptado");
                ViajeDAO.actualizarEstado(viajeId, Viaje.Estado.ACEPTADO);
                res.sendRedirect(req.getContextPath() + "/operador/viaje-activo");
            } else {
                actualizarSolicitud(viajeId, uid, "rechazado");
                // Cascada: buscar siguiente operador disponible
                boolean asignado = AsignadorOperador.manejarRechazo(
                        viajeId, uid, v.getOrigenLat(), v.getOrigenLng());
                if (!asignado) {
                    // No hay más operadores, viaje cancelado por sistema (ya lo hace AsignadorOperador)
                }
                res.sendRedirect(req.getContextPath() + "/operador/panel");
            }
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/panel");
        }
    }

    private void actualizarSolicitud(int viajeId, int operadorId, String estado) throws Exception {
        String sql = """
            UPDATE solicitudes_operador SET estado=?
            WHERE viaje_id=? AND operador_id=? AND estado='pendiente'
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, estado);
            ps.setInt(2, viajeId);
            ps.setInt(3, operadorId);
            ps.executeUpdate();
        }
    }
}
