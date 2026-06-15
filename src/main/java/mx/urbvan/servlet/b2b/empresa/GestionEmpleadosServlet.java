package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.EmpresaDAO;
import mx.urbvan.modelo.Usuario;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/** Admin Empresa - gestión de empleados. URL: /b2b/empresa/empleados */
@WebServlet("/b2b/empresa/empleados")
public class GestionEmpleadosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int empresaId = (int) req.getSession().getAttribute("empresaId");
        try {
            req.setAttribute("empleados", EmpresaDAO.listarEmpleados(empresaId));
            req.setAttribute("pasajerosSinEmpresa", buscarPasajerosSinEmpresa(empresaId));
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/empleados.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/empleados.jsp").forward(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        int empresaId = (int) req.getSession().getAttribute("empresaId");
        String accion = req.getParameter("accion");
        try {
            if ("agregar".equals(accion)) {
                EmpresaDAO.agregarEmpleado(empresaId,
                        Integer.parseInt(req.getParameter("usuarioId")));
            } else if ("baja".equals(accion)) {
                EmpresaDAO.bajaEmpleado(empresaId,
                        Integer.parseInt(req.getParameter("usuarioId")));
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/b2b/empresa/empleados");
    }

    /** Pasajeros registrados que aún no pertenecen a esta empresa */
    private List<Usuario> buscarPasajerosSinEmpresa(int empresaId) throws Exception {
        String sql = """
            SELECT id, nombre, email FROM usuarios
            WHERE rol = 'pasajero' AND activo = TRUE
              AND id NOT IN (
                  SELECT usuario_id FROM empresa_usuarios
                  WHERE empresa_id = ? AND activo = TRUE
              )
            ORDER BY nombre
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, empresaId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setNombre(rs.getString("nombre"));
                u.setEmail(rs.getString("email"));
                lista.add(u);
            }
        }
        return lista;
    }
}
