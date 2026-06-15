package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * CambiarEstadoViajeServlet - operador avanza el estado del viaje activo.
 * CAMBIOS vs v1: usa Viaje.Estado enum con toDb()/fromDb() para comparaciones seguras.
 * Transiciones válidas: aceptado→en_camino→en_curso→completado
 */
@WebServlet("/operador/cambiar-estado")
public class CambiarEstadoViajeServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid     = (int) req.getSession().getAttribute("id");
        int viajeId = Integer.parseInt(req.getParameter("viajeId"));
        String accion = req.getParameter("accion"); // "en_camino"|"en_curso"|"completar"|"cancelar"
        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getOperadorId() != uid) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
                return;
            }
            Viaje.Estado nuevoEstado = switch (accion) {
                case "en_camino"  -> Viaje.Estado.EN_CAMINO;
                case "en_curso"   -> Viaje.Estado.EN_CURSO;
                case "completar"  -> Viaje.Estado.COMPLETADO;
                case "cancelar"   -> Viaje.Estado.CANCELADO;
                default -> v.getEstado();
            };
            if ("cancelar".equals(accion)) {
                ViajeDAO.cancelar(viajeId, "operador");
            } else {
                ViajeDAO.actualizarEstado(viajeId, nuevoEstado);
            }
            if (nuevoEstado == Viaje.Estado.COMPLETADO || nuevoEstado == Viaje.Estado.CANCELADO) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
            } else {
                res.sendRedirect(req.getContextPath() + "/operador/viaje-activo");
            }
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/viaje-activo");
        }
    }
}
