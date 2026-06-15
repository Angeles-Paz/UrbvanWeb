package mx.urbvan.servlet.b2b.empleado;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.dao.NotificacionDAO;
import java.io.IOException;

/** Empleado B2B - ver sus rutas asignadas. URL: /b2b/empleado/rutas */
@WebServlet("/b2b/empleado/rutas")
public class RutasEmpleadoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            req.setAttribute("rutas",         RutaB2BDAO.listarDeEmpleado(uid));
            req.setAttribute("notificaciones",NotificacionDAO.listarNoLeidas(uid));
            req.setAttribute("numNotif",      NotificacionDAO.contarNoLeidas(uid));
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empleado/rutas.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar rutas: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empleado/rutas.jsp").forward(req, res);
        }
    }
}
