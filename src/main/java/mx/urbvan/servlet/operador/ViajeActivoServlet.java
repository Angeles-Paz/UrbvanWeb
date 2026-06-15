package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * ViajeActivoServlet - vista del viaje en curso para el operador.
 * CAMBIOS vs v1: corrige el bug donde PanelOperadorServlet servía esta vista;
 * ahora es un Servlet dedicado. Usa nuevos nombres de columna.
 */
@WebServlet("/operador/viaje-activo")
public class ViajeActivoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            Viaje v = ViajeDAO.buscarActivoOperador(uid);
            if (v == null) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
                return;
            }
            req.setAttribute("viaje", v);
            req.getRequestDispatcher("/WEB-INF/vistas/operador/viaje-activo.jsp").forward(req, res);
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/panel");
        }
    }
}
