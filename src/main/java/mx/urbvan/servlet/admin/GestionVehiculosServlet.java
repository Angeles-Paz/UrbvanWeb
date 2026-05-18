package mx.urbvan.servlet.admin;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * GestionVehiculosServlet — CRUD de vehículos para el administrador.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/admin/GestionVehiculosServlet.java
 */
public class GestionVehiculosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        try (Connection conn = ConexionDB.obtener()) {

            String sql = """
                SELECT v.id_vehiculo, v.placa, v.marca, v.modelo,
                       v.anio, v.color, v.capacidad, v.activo,
                       CONCAT(o.nombre,' ',o.apellido) AS operador_asignado
                FROM vehiculos v
                LEFT JOIN operadores o ON o.id_vehiculo = v.id_vehiculo AND o.activo = 1
                ORDER BY v.marca, v.modelo
                """;

            List<Object[]> vehiculos = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    vehiculos.add(new Object[]{
                        rs.getInt("id_vehiculo"),
                        rs.getString("placa"),
                        rs.getString("marca"),
                        rs.getString("modelo"),
                        rs.getInt("anio"),
                        rs.getString("color"),
                        rs.getInt("capacidad"),
                        rs.getInt("activo"),
                        rs.getString("operador_asignado")
                    });
                }
            }
            req.setAttribute("vehiculos", vehiculos);

        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar vehículos: " + e.getMessage());
        }

        req.getRequestDispatcher("/WEB-INF/vistas/admin/vehiculos.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String accion = req.getParameter("accion");

        try (Connection conn = ConexionDB.obtener()) {

            switch (accion != null ? accion : "") {

                case "crear" -> {
                    String placa     = req.getParameter("placa");
                    String marca     = req.getParameter("marca");
                    String modelo    = req.getParameter("modelo");
                    String anio      = req.getParameter("anio");
                    String color     = req.getParameter("color");
                    String capacidad = req.getParameter("capacidad");

                    if (placa == null || marca == null || modelo == null) break;

                    String sql = """
                        INSERT INTO vehiculos (placa, marca, modelo, anio, color, capacidad)
                        VALUES (?, ?, ?, ?, ?, ?)
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, placa.trim().toUpperCase());
                        ps.setString(2, marca.trim());
                        ps.setString(3, modelo.trim());
                        ps.setInt(4,    anio != null ? Integer.parseInt(anio) : 2024);
                        ps.setString(5, color);
                        ps.setInt(6,    capacidad != null ? Integer.parseInt(capacidad) : 4);
                        ps.executeUpdate();
                    }
                }

                case "editar" -> {
                    int    id       = Integer.parseInt(req.getParameter("id"));
                    String marca    = req.getParameter("marca");
                    String modelo   = req.getParameter("modelo");
                    String color    = req.getParameter("color");
                    String cap      = req.getParameter("capacidad");

                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE vehiculos SET marca=?, modelo=?, color=?, capacidad=? " +
                        "WHERE id_vehiculo=?")) {
                        ps.setString(1, marca);
                        ps.setString(2, modelo);
                        ps.setString(3, color);
                        ps.setInt(4,    cap != null ? Integer.parseInt(cap) : 4);
                        ps.setInt(5,    id);
                        ps.executeUpdate();
                    }
                }

                case "toggle_activo" -> {
                    int id    = Integer.parseInt(req.getParameter("id"));
                    int valor = Integer.parseInt(req.getParameter("activo"));
                    try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE vehiculos SET activo = ? WHERE id_vehiculo = ?")) {
                        ps.setInt(1, valor == 1 ? 0 : 1);
                        ps.setInt(2, id);
                        ps.executeUpdate();
                    }
                }
            }

        } catch (Exception e) {
            // Continuar
        }

        res.sendRedirect(req.getContextPath() + "/admin/vehiculos");
    }
}
