package mx.urbvan.servlet.admin;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.modelo.Vehiculo;
import java.io.*;
import java.sql.*;
import java.util.*;

/**
 * GestionVehiculosServlet - CRUD de vehículos para el admin.
 * CAMBIOS vs v1: nuevo campo 'categoria' (b2c|b2b) en INSERT y SELECT.
 */
@WebServlet("/admin/vehiculos")
public class GestionVehiculosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        try (Connection c = ConexionDB.obtener()) {
            req.setAttribute("vehiculos", listarVehiculos(c));
            req.setAttribute("operadoresDisponibles", listarOperadoresSinVehiculo(c));
            req.getRequestDispatcher("/WEB-INF/vistas/admin/vehiculos.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar vehículos.");
            req.getRequestDispatcher("/WEB-INF/vistas/admin/vehiculos.jsp").forward(req, res);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");
        try (Connection c = ConexionDB.obtener()) {
            switch (accion != null ? accion : "") {
                case "crear"        -> crearVehiculo(c, req);
                case "asignar"      -> asignarOperador(c, req);
                case "toggleActivo" -> toggleActivo(c, Integer.parseInt(req.getParameter("id")));
            }
        } catch (Exception e) {
            req.setAttribute("error", "Error: " + e.getMessage());
        }
        res.sendRedirect(req.getContextPath() + "/admin/vehiculos");
    }

    private List<Vehiculo> listarVehiculos(Connection c) throws SQLException {
        String sql = """
            SELECT v.id, v.modelo, v.capacidad, v.placa, v.color,
                   v.operador_id, v.categoria, v.activo,
                   u.nombre AS operador_nombre
            FROM   vehiculos v
            LEFT JOIN usuarios u ON v.operador_id = u.id
            ORDER BY v.categoria, v.modelo
            """;
        List<Vehiculo> lista = new ArrayList<>();
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Vehiculo vh = new Vehiculo();
                vh.setId(rs.getInt("id"));
                vh.setModelo(rs.getString("modelo"));
                vh.setCapacidad(rs.getInt("capacidad"));
                vh.setPlaca(rs.getString("placa"));
                vh.setColor(rs.getString("color"));
                int opId = rs.getInt("operador_id");
                vh.setOperadorId(rs.wasNull() ? null : opId);
                vh.setCategoria(rs.getString("categoria"));
                vh.setActivo(rs.getBoolean("activo"));
                vh.setOperadorNombre(rs.getString("operador_nombre"));
                lista.add(vh);
            }
        }
        return lista;
    }
    private void crearVehiculo(Connection c, HttpServletRequest req) throws SQLException {
        String sql = """
            INSERT INTO vehiculos (modelo, capacidad, placa, color, categoria, activo)
            VALUES (?,?,?,?,?,TRUE)
            """;
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, req.getParameter("modelo"));
            ps.setInt(2, Integer.parseInt(req.getParameter("capacidad")));
            ps.setString(3, req.getParameter("placa"));
            ps.setString(4, req.getParameter("color"));
            ps.setString(5, req.getParameter("categoria")); // 'b2c' | 'b2b'
            ps.executeUpdate();
        }
    }
    private void asignarOperador(Connection c, HttpServletRequest req) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE vehiculos SET operador_id=? WHERE id=?")) {
            ps.setInt(1, Integer.parseInt(req.getParameter("operadorId")));
            ps.setInt(2, Integer.parseInt(req.getParameter("vehiculoId")));
            ps.executeUpdate();
        }
    }
    private void toggleActivo(Connection c, int id) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(
                "UPDATE vehiculos SET activo = NOT activo WHERE id=?")) {
            ps.setInt(1, id); ps.executeUpdate();
        }
    }
    private List<Map<String,Object>> listarOperadoresSinVehiculo(Connection c) throws SQLException {
        String sql = """
            SELECT u.id, u.nombre FROM usuarios u
            WHERE u.rol = 'operador' AND u.activo = TRUE
              AND u.id NOT IN (SELECT operador_id FROM vehiculos WHERE operador_id IS NOT NULL AND activo=TRUE)
            ORDER BY u.nombre
            """;
        List<Map<String,Object>> lista = new ArrayList<>();
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id", rs.getInt("id"));
                m.put("nombre", rs.getString("nombre"));
                lista.add(m);
            }
        }
        return lista;
    }
}
