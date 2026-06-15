package mx.urbvan.servlet;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.NotificacionDAO;
import java.io.IOException;

/** Marcar notificaciones como leídas - todos los roles. URL: /notificaciones */
@WebServlet("/notificaciones")
public class NotificacionesServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid   = (int) req.getSession().getAttribute("id");
        String id = req.getParameter("id");
        try {
            if ("all".equals(id)) {
                NotificacionDAO.marcarTodasLeidas(uid);
            } else {
                NotificacionDAO.marcarLeida(Integer.parseInt(id), uid);
            }
        } catch (Exception ignored) {}
        // Redirigir de vuelta a donde vino
        String ref = req.getHeader("Referer");
        res.sendRedirect(ref != null ? ref : req.getContextPath() + "/login");
    }
}
