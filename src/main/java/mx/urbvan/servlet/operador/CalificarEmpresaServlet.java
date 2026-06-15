package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import java.io.IOException;

/** Operador - calificar empresa B2B post-ruta. URL: /operador/calificar-empresa */
@WebServlet("/operador/calificar-empresa")
public class CalificarEmpresaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try {
            int rutaId = Integer.parseInt(req.getParameter("rutaId"));
            req.setAttribute("ruta", RutaB2BDAO.buscarPorId(rutaId));
            req.getRequestDispatcher("/WEB-INF/vistas/operador/calificar-empresa.jsp")
               .forward(req, res);
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/rutas-b2b");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        int uid = (int) req.getSession().getAttribute("id");
        try {
            int rutaId     = Integer.parseInt(req.getParameter("rutaId"));
            int puntuacion = Integer.parseInt(req.getParameter("puntuacion"));
            String comentario = req.getParameter("comentario");
            RutaB2B ruta   = RutaB2BDAO.buscarPorId(rutaId);
            if (ruta != null && ruta.puedeCalificarse()) {
                RutaB2BDAO.calificarEmpresa(rutaId, uid, ruta.getEmpresaId(),
                                             puntuacion, comentario);
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error al calificar.");
        }
        res.sendRedirect(req.getContextPath() + "/operador/rutas-b2b?calificado=ok");
    }
}
