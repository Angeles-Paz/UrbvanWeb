package mx.urbvan.servlet.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.modelo.Usuario;
import mx.urbvan.util.HashUtil;
import java.io.*;
import java.sql.*;
import java.util.*;

/**
 * GestionOperadoresServlet - CRUD de operadores para el admin.
 * CAMBIOS vs v1: ya no existe tabla 'operadores' separada. Filtra usuarios WHERE rol='operador'.
 * El alta de operador ahora hace INSERT en usuarios con rol='operador'.
 */
@WebServlet("/admin/operadores")
public class GestionOperadoresServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try (Connection c = ConexionDB.obtener()) {
            req.setAttribute("operadores", listarOperadores(c));
            req.getRequestDispatcher("/WEB-INF/vistas/admin/operadores.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar operadores.");
            req.getRequestDispatcher("/WEB-INF/vistas/admin/operadores.jsp").forward(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        try (Connection c = ConexionDB.obtener()) {
            switch (accion != null ? accion : "") {
                case "crear"       -> crearOperador(c, req);
                case "toggleActivo"-> toggleActivo(c, Integer.parseInt(req.getParameter("id")));
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/admin/operadores");
    }

    private List<Usuario> listarOperadores(Connection c) throws SQLException {
        // v1 SELECT * FROM operadores; v2 filtra en tabla unificada
        String sql = """
            SELECT u.id, u.nombre, u.email, u.activo, u.calificacion_promedio,
                   v.modelo AS vehiculo_modelo, v.placa AS vehiculo_placa, v.categoria
            FROM   usuarios u
            LEFT JOIN vehiculos v ON v.operador_id = u.id AND v.activo = TRUE
            WHERE  u.rol = 'operador'
            ORDER BY u.nombre
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setNombre(rs.getString("nombre"));
                u.setEmail(rs.getString("email"));
                u.setActivo(rs.getBoolean("activo"));
                u.setCalificacionPromedio(rs.getDouble("calificacion_promedio"));
                u.setRol("operador");
                lista.add(u);
            }
        }
        return lista;
    }
    private void crearOperador(Connection c, HttpServletRequest req) throws Exception {
        String sql = """
            INSERT INTO usuarios (nombre, email, contrasena, rol, activo)
            VALUES (?,?,?,'operador',TRUE)
            """;
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, req.getParameter("nombre"));
            ps.setString(2, req.getParameter("email"));
            ps.setString(3, HashUtil.sha256(req.getParameter("contrasena")));
            ps.executeUpdate();
        }
    }
    private void toggleActivo(Connection c, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE usuarios SET activo = NOT activo WHERE id=? AND rol='operador'")) {
            ps.setInt(1, id); ps.executeUpdate();
        }
    }
}
