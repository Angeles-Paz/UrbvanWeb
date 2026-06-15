package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.EmpresaDAO;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.dao.NotificacionDAO;
import java.io.IOException;

/**
 * DashboardEmpresaServlet - panel corporativo del admin_empresa.
 *
 * CORRECCIÓN: además de las rutas de la empresa, ahora también carga
 * "rutasPropiasAdmin" - las rutas donde el propio admin_empresa tiene
 * un asiento asignado, para que pueda verlas aunque no sea empleado.
 */
@WebServlet("/b2b/empresa/dashboard")
public class DashboardEmpresaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {

        int uid       = (int) req.getSession().getAttribute("id");
        Object empObj = req.getSession().getAttribute("empresaId");

        if (empObj == null) {
            req.setAttribute("error", "Sesion sin empresa asociada. Cierra sesion y vuelve a entrar.");
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/dashboard.jsp").forward(req, res);
            return;
        }
        int empresaId = (int) empObj;

        try {
            req.setAttribute("empresa",           EmpresaDAO.buscarPorId(empresaId));
            req.setAttribute("rutas",             RutaB2BDAO.listarDeEmpresa(empresaId));
            req.setAttribute("empleados",         EmpresaDAO.listarEmpleados(empresaId));
            req.setAttribute("notificaciones",    NotificacionDAO.listarNoLeidas(uid));
            req.setAttribute("numNotif",          NotificacionDAO.contarNoLeidas(uid));
            // Rutas donde el propio admin_empresa tiene asiento asignado
            req.setAttribute("rutasPropias",      RutaB2BDAO.listarDeEmpleado(uid));

            if (Boolean.TRUE.equals(req.getSession().getAttribute("primerLogin"))) {
                req.setAttribute("mostrarAvisoPrimerLogin", true);
            }

            req.getRequestDispatcher(
                    "/WEB-INF/vistas/b2b/empresa/dashboard.jsp").forward(req, res);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar dashboard: " + e.getMessage());
            req.getRequestDispatcher(
                    "/WEB-INF/vistas/b2b/empresa/dashboard.jsp").forward(req, res);
        }
    }
}
