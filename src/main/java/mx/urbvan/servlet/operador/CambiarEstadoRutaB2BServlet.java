package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import java.io.IOException;

/** Permite al operador B2B avanzar el estado operativo de una ruta corporativa. */
@WebServlet("/operador/b2b/cambiar-estado")
public class CambiarEstadoRutaB2BServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int operadorId = (int) req.getSession().getAttribute("id");
        String rutaIdParam = req.getParameter("rutaId");
        String accion = req.getParameter("accion");
        String paradaIdParam = req.getParameter("paradaId");
        String comentario = req.getParameter("comentario");

        try {
            int rutaId = Integer.parseInt(rutaIdParam);
            Integer paradaId = null;
            if (paradaIdParam != null && !paradaIdParam.isBlank()) {
                paradaId = Integer.parseInt(paradaIdParam);
            }
            double lat = parseDouble(req.getParameter("lat"));
            double lng = parseDouble(req.getParameter("lng"));

            RutaB2BDAO.cambiarEstadoOperativo(rutaId, operadorId, accion, paradaId, lat, lng, comentario);
            res.sendRedirect(req.getContextPath() + "/b2b/ruta/detalle?rutaId=" + rutaId + "&estado=ok");
        } catch (Exception e) {
            String rutaId = rutaIdParam != null ? rutaIdParam : "";
            res.sendRedirect(req.getContextPath() + "/b2b/ruta/detalle?rutaId=" + rutaId + "&estado=error");
        }
    }

    private double parseDouble(String valor) {
        try {
            return valor == null || valor.isBlank() ? 0 : Double.parseDouble(valor);
        } catch (Exception e) {
            return 0;
        }
    }
}
