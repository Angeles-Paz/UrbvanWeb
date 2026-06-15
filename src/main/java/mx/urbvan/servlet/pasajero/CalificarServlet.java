package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * CalificarServlet - registra calificación del pasajero al operador tras el viaje.
 * CAMBIOS vs v1: tabla calificaciones → calificaciones_viaje; llama SP de recalculo.
 * La puntuación es 0-100 (antes podía ser 1-5 estrellas).
 */
@WebServlet("/pasajero/calificar")
public class CalificarServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        String idParam = req.getParameter("viajeId");
        if (idParam == null) {
            res.sendRedirect(req.getContextPath() + "/pasajero/historial");
            return;
        }
        try {
            Viaje v = ViajeDAO.buscarPorId(Integer.parseInt(idParam));
            if (v == null || v.getEstado() != Viaje.Estado.COMPLETADO
                    || v.getCalificacionDada() >= 0) {
                res.sendRedirect(req.getContextPath() + "/pasajero/historial");
                return;
            }
            req.setAttribute("viaje", v);
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/calificar.jsp").forward(req, res);
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/pasajero/historial");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            int    viajeId   = Integer.parseInt(req.getParameter("viajeId"));
            int    puntuacion= Integer.parseInt(req.getParameter("puntuacion"));
            String comentario= req.getParameter("comentario");

            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getPasajeroId() != uid) {
                res.sendRedirect(req.getContextPath() + "/pasajero/historial");
                return;
            }
            // Inserta en calificaciones_viaje y recalcula score del operador via SP
            ViajeDAO.insertarCalificacion(viajeId, uid, v.getOperadorId(),
                                          puntuacion, comentario);
            res.sendRedirect(req.getContextPath() + "/pasajero/historial?calificado=ok");
        } catch (Exception e) {
            req.setAttribute("error", "Error al guardar la calificación.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/calificar.jsp").forward(req, res);
        }
    }
}
