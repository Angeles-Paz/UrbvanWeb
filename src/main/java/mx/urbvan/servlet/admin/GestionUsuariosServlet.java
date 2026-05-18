package mx.urbvan.servlet.admin;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * GestionUsuariosServlet — CRUD de pasajeros para el administrador.
 *
 * GET  → lista usuarios con filtro opcional por nombre/correo
 * POST → acción según parámetro "accion": crear, editar, toggle_activo, eliminar
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/admin/GestionUsuariosServlet.java
 */
public class GestionUsuariosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String busqueda = req.getParameter("q");

        try (Connection conn = ConexionDB.obtener()) {

            String sql = """
                SELECT u.id_usuario, u.nombre, u.apellido, u.correo,
                       u.telefono, u.activo, u.fecha_registro,
                       COUNT(v.id_viaje) AS total_viajes
                FROM usuarios u
                LEFT JOIN viajes v ON v.id_usuario = u.id_usuario
                """;

            if (busqueda != null && !busqueda.isBlank()) {
                sql += " WHERE u.nombre LIKE ? OR u.apellido LIKE ? OR u.correo LIKE ?";
            }

            sql += " GROUP BY u.id_usuario ORDER BY u.fecha_registro DESC";

            List<Object[]> usuarios = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (busqueda != null && !busqueda.isBlank()) {
                    String like = "%" + busqueda + "%";
                    ps.setString(1, like);
                    ps.setString(2, like);
                    ps.setString(3, like);
                }
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    usuarios.add(new Object[]{
                        rs.getInt("id_usuario"),
                        rs.getString("nombre"),
                        rs.getString("apellido"),
                        rs.getString("correo"),
                        rs.getString("telefono"),
                        rs.getInt("activo"),
                        rs.getTimestamp("fecha_registro"),
                        rs.getInt("total_viajes")
                    });
                }
            }
            req.setAttribute("usuarios", usuarios);
            req.setAttribute("busqueda", busqueda);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar usuarios: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/admin/usuarios.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        try (Connection conn = ConexionDB.obtener()) {

            switch (accion != null ? accion : "") {

                case "crear" -> {
                    String nombre     = req.getParameter("nombre");
                    String apellido   = req.getParameter("apellido");
                    String correo     = req.getParameter("correo");
                    String telefono   = req.getParameter("telefono");
                    String contrasena = req.getParameter("contrasena");

                    if (nombre == null || correo == null || contrasena == null) break;

                    String sql = """
                        INSERT INTO usuarios (nombre, apellido, correo, contrasena_hash, telefono)
                        VALUES (?, ?, ?, ?, ?)
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, nombre.trim());
                        ps.setString(2, apellido != null ? apellido.trim() : "");
                        ps.setString(3, correo.trim().toLowerCase());
                        ps.setString(4, HashUtil.sha256(contrasena));
                        ps.setString(5, telefono);
                        ps.executeUpdate();
                    }
                }

                case "toggle_activo" -> {
                    int id    = Integer.parseInt(req.getParameter("id"));
                    int valor = Integer.parseInt(req.getParameter("activo"));
                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE usuarios SET activo = ? WHERE id_usuario = ?")) {
                        ps.setInt(1, valor == 1 ? 0 : 1);
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                }

                case "eliminar" -> {
                    int id = Integer.parseInt(req.getParameter("id"));
                    // Solo desactivar, no eliminar físicamente
                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE usuarios SET activo = 0 WHERE id_usuario = ?")) {
                        ps.setInt(1, id);
                        ps.executeUpdate();
                    }
                }
            }

        } catch (Exception e) {
            // Continuar y mostrar la lista aunque haya error
        }

        res.sendRedirect(req.getContextPath() + "/admin/usuarios");
    }
}
