package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import java.io.IOException;

/**
 * HistorialServlet - lista los viajes completados/cancelados del pasajero.
 * CAMBIOS vs v1: usa ViajeDAO.listarDePasajero() con nuevos nombres de columna.
 */
@WebServlet("/pasajero/historial")
public class HistorialServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            req.setAttribute("viajes", ViajeDAO.listarDePasajero(uid));
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/historial.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar el historial.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/historial.jsp").forward(req, res);
        }
    }
}
