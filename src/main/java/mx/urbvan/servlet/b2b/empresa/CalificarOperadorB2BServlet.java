package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import java.io.IOException;

/** Admin Empresa y Empleado - calificar operador tras ruta B2B. URL: /b2b/empresa/calificar-operador */
@WebServlet("/b2b/empresa/calificar-operador")
public class CalificarOperadorB2BServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try {
            int rutaId = Integer.parseInt(req.getParameter("rutaId"));
            req.setAttribute("ruta", RutaB2BDAO.buscarPorId(rutaId));
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/calificar-operador.jsp")
               .forward(req, res);
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        int uid = (int) req.getSession().getAttribute("id");
        String rol = (String) req.getSession().getAttribute("rol");
        try {
            int rutaId     = Integer.parseInt(req.getParameter("rutaId"));
            int puntuacion = Integer.parseInt(req.getParameter("puntuacion"));
            String comentario = req.getParameter("comentario");
            RutaB2B ruta   = RutaB2BDAO.buscarPorId(rutaId);
            if (ruta != null && ruta.puedeCalificarse()) {
                String tipoAutor = "ADMIN_EMPRESA".equals(rol) ? "admin_empresa" : "empleado";
                RutaB2BDAO.calificarOperador(rutaId, uid, tipoAutor,
                                              ruta.getOperadorId(), puntuacion, comentario);
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error al guardar calificación.");
        }
        res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard?calificado=ok");
    }
}
