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
 * GestionOperadoresServlet — CRUD de operadores para el administrador.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/admin/GestionOperadoresServlet.java
 */
public class GestionOperadoresServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        String busqueda = req.getParameter("q");

        try (Connection conn = ConexionDB.obtener()) {

            // Lista de operadores
            String sql = """
                SELECT o.id_operador, o.nombre, o.apellido, o.correo,
                       o.telefono, o.disponible, o.activo, o.calificacion_prom,
                       o.fecha_registro,
                       CONCAT(v.marca,' ',v.modelo,' (',v.placa,')') AS vehiculo,
                       o.id_vehiculo,
                       COUNT(vj.id_viaje) AS total_viajes
                FROM operadores o
                LEFT JOIN vehiculos v  ON v.id_vehiculo  = o.id_vehiculo
                LEFT JOIN viajes    vj ON vj.id_operador = o.id_operador
                    AND vj.estado = 'COMPLETADO'
                """;

            if (busqueda != null && !busqueda.isBlank()) {
                sql += " WHERE o.nombre LIKE ? OR o.apellido LIKE ? OR o.correo LIKE ?";
            }

            sql += " GROUP BY o.id_operador ORDER BY o.fecha_registro DESC";

            List<Object[]> operadores = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                if (busqueda != null && !busqueda.isBlank()) {
                    String like = "%" + busqueda + "%";
                    ps.setString(1, like);
                    ps.setString(2, like);
                    ps.setString(3, like);
                }
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    operadores.add(new Object[]{
                        rs.getInt("id_operador"),
                        rs.getString("nombre"),
                        rs.getString("apellido"),
                        rs.getString("correo"),
                        rs.getString("telefono"),
                        rs.getInt("disponible"),
                        rs.getInt("activo"),
                        rs.getDouble("calificacion_prom"),
                        rs.getTimestamp("fecha_registro"),
                        rs.getString("vehiculo"),
                        rs.getInt("id_vehiculo"),
                        rs.getInt("total_viajes")
                    });
                }
            }
            req.setAttribute("operadores", operadores);
            req.setAttribute("busqueda",   busqueda);

            // Lista de vehículos disponibles para el formulario de crear
            String sqlVeh = """
                SELECT id_vehiculo, CONCAT(marca,' ',modelo,' — ',placa) AS label
                FROM vehiculos WHERE activo = 1
                ORDER BY marca, modelo
                """;
            List<Object[]> vehiculos = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sqlVeh)) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    vehiculos.add(new Object[]{
                        rs.getInt("id_vehiculo"),
                        rs.getString("label")
                    });
                }
            }
            req.setAttribute("vehiculos", vehiculos);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar operadores: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/admin/operadores.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        try (Connection conn = ConexionDB.obtener()) {

            switch (accion != null ? accion : "") {

                case "crear" -> {
                    String nombre      = req.getParameter("nombre");
                    String apellido    = req.getParameter("apellido");
                    String correo      = req.getParameter("correo");
                    String telefono    = req.getParameter("telefono");
                    String contrasena  = req.getParameter("contrasena");
                    String idVehStr    = req.getParameter("id_vehiculo");

                    if (nombre == null || correo == null || contrasena == null) break;

                    String sql = """
                        INSERT INTO operadores
                            (nombre, apellido, correo, contrasena_hash, telefono, id_vehiculo)
                        VALUES (?, ?, ?, ?, ?, ?)
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sql,
                            Statement.RETURN_GENERATED_KEYS)) {
                        ps.setString(1, nombre.trim());
                        ps.setString(2, apellido != null ? apellido.trim() : "");
                        ps.setString(3, correo.trim().toLowerCase());
                        ps.setString(4, HashUtil.sha256(contrasena));
                        ps.setString(5, telefono);
                        if (idVehStr != null && !idVehStr.isBlank()) {
                            ps.setInt(6, Integer.parseInt(idVehStr));
                        } else {
                            ps.setNull(6, Types.INTEGER);
                        }
                        ps.executeUpdate();

                        // Insertar posición inicial en CDMX (Zócalo)
                        ResultSet keys = ps.getGeneratedKeys();
                        if (keys.next()) {
                            int newId = keys.getInt(1);
                            try (PreparedStatement psPos = conn.prepareStatement(
                                "INSERT INTO posicion_operador (id_operador, latitud, longitud) " +
                                "VALUES (?, 19.4326, -99.1332)")) {
                                psPos.setInt(1, newId);
                                psPos.executeUpdate();
                            }
                        }
                    }
                }

                case "toggle_activo" -> {
                    int id    = Integer.parseInt(req.getParameter("id"));
                    int valor = Integer.parseInt(req.getParameter("activo"));
                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE operadores SET activo = ? WHERE id_operador = ?")) {
                        ps.setInt(1, valor == 1 ? 0 : 1);
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                }

                case "asignar_vehiculo" -> {
                    int id    = Integer.parseInt(req.getParameter("id"));
                    String vh = req.getParameter("id_vehiculo");
                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE operadores SET id_vehiculo = ? WHERE id_operador = ?")) {
                        if (vh != null && !vh.isBlank()) {
                            ps.setInt(1, Integer.parseInt(vh));
                        } else {
                            ps.setNull(1, Types.INTEGER);
                        }
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                }
            }

        } catch (Exception e) {
            // Continuar
        }

        res.sendRedirect(req.getContextPath() + "/admin/operadores");
    }
}
