package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * EstadoViajeServlet - muestra el estado del viaje activo al pasajero.
 * CAMBIOS vs v1: usa ViajeDAO.buscarActivoPasajero() con nuevas columnas.
 * El polling.js llama a este endpoint cada 4 s para refrescar el estado.
 */
@WebServlet("/pasajero/estado-viaje")
public class EstadoViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            Viaje v = ViajeDAO.buscarActivoPasajero(uid);
            if (v == null) {
                res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
                return;
            }
            req.setAttribute("viaje", v);
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/estado.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al obtener estado del viaje.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/estado.jsp").forward(req, res);
        }
    }
}
