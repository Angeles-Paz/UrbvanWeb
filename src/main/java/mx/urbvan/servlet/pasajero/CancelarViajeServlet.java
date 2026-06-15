package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * CancelarViajeServlet - cancela el viaje activo del pasajero.
 * CAMBIOS vs v1: usa ViajeDAO.cancelar() con nueva columna cancelado_por.
 */
@WebServlet("/pasajero/cancelar-viaje")
public class CancelarViajeServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            Viaje v = ViajeDAO.buscarActivoPasajero(uid);
            if (v == null) {
                res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
                return;
            }
            // Solo puede cancelar si el viaje aún no está en curso
            if (v.getEstado() == Viaje.Estado.EN_CAMINO || v.getEstado() == Viaje.Estado.EN_CURSO) {
                req.setAttribute("error", "No puedes cancelar un viaje que ya está en curso.");
                req.setAttribute("viaje", v);
                req.getRequestDispatcher("/WEB-INF/vistas/pasajero/estado.jsp").forward(req, res);
                return;
            }
            ViajeDAO.cancelar(v.getId(), "pasajero");
            res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
        } catch (Exception e) {
            req.setAttribute("error", "Error al cancelar el viaje.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/estado.jsp").forward(req, res);
        }
    }
}
