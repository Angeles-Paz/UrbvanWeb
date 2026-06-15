package mx.urbvan.dao;

import mx.urbvan.modelo.Vehiculo;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class VehiculoDAO {

    public static List<Vehiculo> listarB2CDisponibles() throws Exception {
        String sql = """
            SELECT v.id, v.modelo, v.capacidad, v.placa, v.color, v.operador_id,
                   v.categoria, v.activo, u.nombre AS operador_nombre
            FROM vehiculos v
            JOIN usuarios u ON u.id = v.operador_id
            WHERE v.categoria = 'b2c'
              AND v.activo = TRUE
              AND u.rol = 'operador'
              AND u.activo = TRUE
              AND u.id NOT IN (
                    SELECT operador_id FROM viajes
                    WHERE estado IN ('asignado','aceptado','en_camino','en_curso')
                      AND operador_id IS NOT NULL
              )
            ORDER BY v.capacidad ASC, v.modelo ASC, v.placa ASC
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<Vehiculo> lista = new ArrayList<>();
            while (rs.next()) lista.add(mapear(rs));
            return lista;
        }
    }

    public static Vehiculo buscarPorId(int id) throws Exception {
        String sql = """
            SELECT v.id, v.modelo, v.capacidad, v.placa, v.color, v.operador_id,
                   v.categoria, v.activo, u.nombre AS operador_nombre
            FROM vehiculos v
            LEFT JOIN usuarios u ON u.id = v.operador_id
            WHERE v.id = ?
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    private static Vehiculo mapear(ResultSet rs) throws SQLException {
        Vehiculo v = new Vehiculo();
        v.setId(rs.getInt("id"));
        v.setModelo(rs.getString("modelo"));
        v.setCapacidad(rs.getInt("capacidad"));
        v.setPlaca(rs.getString("placa"));
        v.setColor(rs.getString("color"));
        v.setOperadorId(rs.getInt("operador_id"));
        v.setCategoria(rs.getString("categoria"));
        v.setActivo(rs.getBoolean("activo"));
        v.setOperadorNombre(rs.getString("operador_nombre"));
        return v;
    }
}
