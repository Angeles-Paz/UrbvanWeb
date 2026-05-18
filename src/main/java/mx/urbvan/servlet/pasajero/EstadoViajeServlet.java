package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * EstadoViajeServlet — versión corregida con reintentos de asignación.
 *
 * GET  → muestra seguimiento.jsp
 * POST → responde JSON con estado actual + reintenta asignación si está en EN_ASIGNACION
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/EstadoViajeServlet.java
 */
public class EstadoViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            int idUsuario = (int) req.getSession().getAttribute("id");
            try {
                Viaje activo = new ViajeDAO().buscarActivoPorUsuario(idUsuario);
                if (activo == null) {
                    res.sendRedirect(req.getContextPath() + "/pasajero/solicitar"); return;
                }
                idStr = String.valueOf(activo.getIdViaje());
            } catch (Exception e) {
                res.sendRedirect(req.getContextPath() + "/pasajero/solicitar"); return;
            }
        }

        req.setAttribute("id_viaje", idStr);
        req.getRequestDispatcher("/WEB-INF/vistas/pasajero/seguimiento.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();
        String idStr = req.getParameter("id_viaje");

        if (idStr == null || idStr.isBlank()) {
            out.print("{\"error\":\"ID de viaje no proporcionado\"}"); return;
        }

        try {
            int idViaje = Integer.parseInt(idStr);
            Viaje viaje = new ViajeDAO().buscarPorId(idViaje);

            if (viaje == null) {
                out.print("{\"error\":\"Viaje no encontrado\"}"); return;
            }

            // ── Lógica de reintentos de asignación ──────────────────
            if (viaje.getEstado() == Viaje.Estado.EN_ASIGNACION) {
                // Expirar solicitudes pendientes que superaron los 30 seg
                AsignadorOperador.expirarSolicitudesPendientes(idViaje);
                // Intentar nueva asignación si no hay pendiente activa
                AsignadorOperador.intentarAsignar(idViaje);
                // Releer el viaje por si se actualizó
                viaje = new ViajeDAO().buscarPorId(idViaje);
            }

            // Obtener posición del operador
            double opLat = 0, opLng = 0;
            if (viaje.getIdOperador() > 0) {
                double[] pos = new ViajeDAO().obtenerPosicionOperador(viaje.getIdOperador());
                if (pos != null) { opLat = pos[0]; opLng = pos[1]; }
            }

            String json = "{"
                + "\"estado\":\""     + viaje.getEstado().name()  + "\","
                + "\"id_operador\":"  + viaje.getIdOperador()      + ","
                + "\"op_lat\":"       + opLat                      + ","
                + "\"op_lng\":"       + opLng                      + ","
                + "\"eta_operador\":" + viaje.getEtaOperadorMin()  + ","
                + "\"eta_viaje\":"    + viaje.getEtaViajeMin()     + ","
                + "\"origen_lat\":"   + viaje.getOrigenLat()       + ","
                + "\"origen_lng\":"   + viaje.getOrigenLng()       + ","
                + "\"destino_lat\":"  + viaje.getDestinoLat()      + ","
                + "\"destino_lng\":"  + viaje.getDestinoLng()      + ","
                + "\"precio_total\":" + viaje.getPrecioTotal()
                + "}";

            out.print(json);

        } catch (Exception e) {
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}
