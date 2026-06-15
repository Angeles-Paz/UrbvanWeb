package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.dao.NotificacionDAO;
import java.io.IOException;

/** Operador - ver sus rutas B2B asignadas. URL: /operador/rutas-b2b */
@WebServlet("/operador/rutas-b2b")
public class RutasB2BOperadorServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            req.setAttribute("rutas",         RutaB2BDAO.listarDeOperador(uid));
            req.setAttribute("notificaciones",NotificacionDAO.listarNoLeidas(uid));
            req.setAttribute("numNotif",      NotificacionDAO.contarNoLeidas(uid));
            req.getRequestDispatcher("/WEB-INF/vistas/operador/rutas-b2b.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar rutas B2B.");
            req.getRequestDispatcher("/WEB-INF/vistas/operador/rutas-b2b.jsp").forward(req, res);
        }
    }
}
