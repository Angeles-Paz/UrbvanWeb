package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;
import java.io.IOException;

/**
 * PagoServlet - confirma el pago simulado y dispara la asignación de operador.
 * CAMBIOS vs v1: llama AsignadorOperador.asignarSiguiente() (usa solicitudes_operador).
 */
@WebServlet("/pasajero/pago")
public class PagoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        Integer viajeId = (Integer) req.getSession().getAttribute("viajeIdPendiente");
        if (viajeId == null) {
            res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
            return;
        }
        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            req.setAttribute("viaje", v);
        } catch (Exception e) {
            req.setAttribute("error", "No se pudo cargar el viaje.");
        }
        req.getRequestDispatcher("/WEB-INF/vistas/pasajero/pago.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        Integer viajeId = (Integer) req.getSession().getAttribute("viajeIdPendiente");
        if (viajeId == null) {
            res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
            return;
        }
        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null) {
                res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
                return;
            }
            // Disparar primera asignación de operador en cascada
            AsignadorOperador.asignarSiguiente(viajeId, v.getOrigenLat(), v.getOrigenLng());
            req.getSession().removeAttribute("viajeIdPendiente");
            req.getSession().setAttribute("viajeActivoId", viajeId);
            res.sendRedirect(req.getContextPath() + "/pasajero/estado-viaje");
        } catch (Exception e) {
            req.setAttribute("error", "Error al confirmar el pago.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/pago.jsp").forward(req, res);
        }
    }
}
