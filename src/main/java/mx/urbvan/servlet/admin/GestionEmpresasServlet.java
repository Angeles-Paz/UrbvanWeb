package mx.urbvan.servlet.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.EmpresaDAO;
import java.io.IOException;

/** Admin Urbvan - gestión de empresas B2B. URL: /admin/empresas */
@WebServlet("/admin/empresas")
public class GestionEmpresasServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try {
            req.setAttribute("empresas", EmpresaDAO.listarTodas());
            req.getRequestDispatcher("/WEB-INF/vistas/admin/empresas.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar empresas: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/admin/empresas.jsp").forward(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        try {
            switch (accion != null ? accion : "") {
                case "crear" -> EmpresaDAO.crearConAdmin(
                        req.getParameter("nombreEmpresa"),
                        req.getParameter("adminNombre"),
                        req.getParameter("adminEmail"),
                        req.getParameter("passwordTemporal"));
                case "inhabilitar" ->
                        EmpresaDAO.inhabilitar(Integer.parseInt(req.getParameter("id")));
                case "habilitar" ->
                        EmpresaDAO.habilitar(Integer.parseInt(req.getParameter("id")));
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/admin/empresas");
    }
}
