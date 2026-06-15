package mx.urbvan.servlet.b2b;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import java.io.IOException;

/**
 * DetalleRutaServlet - detalle completo de una ruta B2B.
 * URL: /b2b/ruta/detalle?rutaId=X
 *
 * Accesible por ADMIN_EMPRESA, OPERADOR y PASAJERO+esEmpleado.
 * FiltroSesion gestiona el control de acceso a la zona /b2b/ruta/.
 */
@WebServlet("/b2b/ruta/detalle")
public class DetalleRutaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, ServletException {

        String rutaIdParam = req.getParameter("rutaId");
        if (rutaIdParam == null || rutaIdParam.isBlank()) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        try {
            int     rutaId = Integer.parseInt(rutaIdParam);
            RutaB2B ruta   = RutaB2BDAO.buscarPorId(rutaId);

            if (ruta == null) {
                req.setAttribute("error", "Ruta no encontrada.");
                req.getRequestDispatcher(
                        "/WEB-INF/vistas/b2b/ruta/detalle.jsp").forward(req, res);
                return;
            }

            // URL de retorno según el rol del usuario
            String rol     = (String) req.getSession().getAttribute("rol");
            String urlBack = switch (rol) {
                case "ADMIN_EMPRESA" -> "/b2b/empresa/dashboard";
                case "OPERADOR"      -> "/operador/rutas-b2b";
                default              -> "/b2b/empleado/rutas";   // PASAJERO+esEmpleado
            };

            req.setAttribute("ruta",    ruta);
            req.setAttribute("eventos", RutaB2BDAO.listarEventos(rutaId));
            req.setAttribute("rolActual", rol);
            req.setAttribute("urlBack", req.getContextPath() + urlBack);
            req.getRequestDispatcher(
                    "/WEB-INF/vistas/b2b/ruta/detalle.jsp").forward(req, res);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar la ruta: " + e.getMessage());
            req.getRequestDispatcher(
                    "/WEB-INF/vistas/b2b/ruta/detalle.jsp").forward(req, res);
        }
    }
}
