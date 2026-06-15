package mx.urbvan.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class PerfilDAO {
    public Object[] buscarPerfilPorId(int idUsuario) throws Exception {
        String sql = """
            SELECT id, nombre, apellido, email, telefono, created_at
            FROM usuarios
            WHERE id = ?
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Object[] perfil = new Object[6];
                perfil[0] = rs.getInt("id");
                perfil[1] = rs.getString("nombre");
                perfil[2] = rs.getString("apellido");
                perfil[3] = rs.getString("email");
                perfil[4] = rs.getString("telefono");
                perfil[5] = rs.getTimestamp("created_at");
                return perfil;
            }
            return null;
        }
    }

    public boolean actualizarPerfil(int idUsuario, String nombre, String apellido, String telefono) throws Exception {
        String sql = """
            UPDATE usuarios
            SET nombre = ?, apellido = ?, telefono = ?
            WHERE id = ?
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setString(2, apellido);
            ps.setString(3, telefono);
            ps.setInt(4, idUsuario);
            return ps.executeUpdate() > 0;
        }
    }
}
