package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.EmpresaDAO;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.Usuario;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

/**
 * AsignarAsientosServlet - asignar empleados a asientos en una ruta B2B.
 *
 * CORRECCIÓN: filtra la lista de empleados para excluir al admin_empresa.
 * El admin_empresa NO aparece como opción en el dropdown del mapa de asientos.
 * Si el admin_empresa necesita verse en una ruta, puede agregarse a sí mismo
 * como pasajero desde el panel de empleados (cambiando su rol a empleado también,
 * aunque eso no aplica en este diseño - el admin gestiona, no viaja).
 */
@WebServlet("/b2b/empresa/asignar-asientos")
public class AsignarAsientosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {

        int empresaId = (int) req.getSession().getAttribute("empresaId");
        String rutaIdParam = req.getParameter("rutaId");

        if (rutaIdParam == null || rutaIdParam.isBlank()) {
            res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
            return;
        }

        try {
            int rutaId = Integer.parseInt(rutaIdParam);

            // ── Solo empleados (rol='empleado'), excluir admin_empresa ────────
            List<Usuario> todos = EmpresaDAO.listarEmpleados(empresaId);
            List<Usuario> soloEmpleados = todos.stream()
                    .filter(u -> "empleado".equals(u.getRol()))
                    .collect(Collectors.toList());

            req.setAttribute("ruta",      RutaB2BDAO.buscarPorId(rutaId));
            req.setAttribute("empleados", soloEmpleados);

            req.getRequestDispatcher(
                    "/WEB-INF/vistas/b2b/empresa/asignar-asientos.jsp").forward(req, res);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar la asignacion: " + e.getMessage());
            res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {

        req.setCharacterEncoding("UTF-8");
        String accion  = req.getParameter("accion");
        String rutaIdParam = req.getParameter("rutaId");

        if (rutaIdParam == null) {
            res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
            return;
        }

        int rutaId = Integer.parseInt(rutaIdParam);

        try {
            if ("asignar".equals(accion)) {
                int empleadoId    = Integer.parseInt(req.getParameter("empleadoId"));
                int numeroAsiento = Integer.parseInt(req.getParameter("numeroAsiento"));
                RutaB2BDAO.asignarAsiento(rutaId, empleadoId, numeroAsiento);
            } else if ("remover".equals(accion)) {
                int empleadoId = Integer.parseInt(req.getParameter("empleadoId"));
                RutaB2BDAO.removerAsiento(rutaId, empleadoId);
            }
        } catch (Exception e) {
            // El trigger de BD lanzará error si el asiento ya está ocupado
            req.setAttribute("error", "No se pudo asignar: " + e.getMessage());
        }

        res.sendRedirect(req.getContextPath() +
                         "/b2b/empresa/asignar-asientos?rutaId=" + rutaId);
    }
}
