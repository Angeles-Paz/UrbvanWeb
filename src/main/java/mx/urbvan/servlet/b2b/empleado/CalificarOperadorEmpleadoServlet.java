package mx.urbvan.servlet.b2b.empleado;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import java.io.IOException;

/** Empleado B2B - calificar operador. URL: /b2b/empleado/calificar-operador */
@WebServlet("/b2b/empleado/calificar-operador")
public class CalificarOperadorEmpleadoServlet extends HttpServlet {

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
                RutaB2BDAO.calificarOperador(rutaId, uid, "empleado",
                                              ruta.getOperadorId(), puntuacion, comentario);
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error al calificar.");
        }
        res.sendRedirect(req.getContextPath() + "/b2b/empleado/rutas?calificado=ok");
    }
}
