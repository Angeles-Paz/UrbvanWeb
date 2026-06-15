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
 * GestionUsuariosServlet - CRUD de pasajeros para el admin.
 * CAMBIOS vs v1: filtra usuarios WHERE rol='pasajero' en tabla unificada;
 * columnas email (antes correo), contrasena (antes contrasena_hash).
 */
@WebServlet("/admin/usuarios")
public class GestionUsuariosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try (Connection c = ConexionDB.obtener()) {
            req.setAttribute("usuarios", listarPasajeros(c));
            req.getRequestDispatcher("/WEB-INF/vistas/admin/usuarios.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar usuarios.");
            req.getRequestDispatcher("/WEB-INF/vistas/admin/usuarios.jsp").forward(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        try (Connection c = ConexionDB.obtener()) {
            switch (accion != null ? accion : "") {
                case "toggleActivo" -> toggleActivo(c, Integer.parseInt(req.getParameter("id")));
                case "resetPassword" -> resetPassword(c,
                        Integer.parseInt(req.getParameter("id")),
                        req.getParameter("nuevaPassword"));
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error al procesar la operación.");
        }
        res.sendRedirect(req.getContextPath() + "/admin/usuarios");
    }

    private List<Usuario> listarPasajeros(Connection c) throws SQLException {
        // v1 consultaba tabla separada; v2 filtra por rol en tabla unificada
        String sql = """
            SELECT id, nombre, email, rol, activo, calificacion_promedio, created_at
            FROM   usuarios
            WHERE  rol = 'pasajero'
            ORDER BY nombre
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setNombre(rs.getString("nombre"));
                u.setEmail(rs.getString("email"));
                u.setRol(rs.getString("rol"));
                u.setActivo(rs.getBoolean("activo"));
                u.setCalificacionPromedio(rs.getDouble("calificacion_promedio"));
                lista.add(u);
            }
        }
        return lista;
    }
    private void toggleActivo(Connection c, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE usuarios SET activo = NOT activo WHERE id=? AND rol='pasajero'")) {
            ps.setInt(1, id); ps.executeUpdate();
        }
    }
    private void resetPassword(Connection c, int id, String nuevaPassword) throws Exception {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE usuarios SET contrasena=? WHERE id=? AND rol='pasajero'")) {
            ps.setString(1, HashUtil.sha256(nuevaPassword));
            ps.setInt(2, id); ps.executeUpdate();
        }
    }
}
