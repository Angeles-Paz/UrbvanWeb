package mx.urbvan.dao;

import mx.urbvan.util.HashUtil;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class RecuperarPasswordDAO {
    public boolean existeUsuario(String email, String telefono, String rol) throws Exception {
        boolean validarTelefono = telefono != null && !telefono.isBlank();
        String sql = validarTelefono ?
            """
            SELECT id FROM usuarios
            WHERE email = ? AND telefono = ? AND rol = ? AND activo = TRUE
            """ :
            """
            SELECT id FROM usuarios
            WHERE email = ? AND rol = ? AND activo = TRUE
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            if (validarTelefono) {
                ps.setString(2, telefono);
                ps.setString(3, rol);
            } else {
                ps.setString(2, rol);
            }
            ResultSet rs = ps.executeQuery();
            return rs.next();
        }
    }

    public boolean actualizar(String email, String nuevaContrasena) throws Exception {
        String sql = "UPDATE usuarios SET contrasena = ? WHERE email = ?";
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, HashUtil.sha256(nuevaContrasena));
            ps.setString(2, email);
            return ps.executeUpdate() > 0;
        }
    }
}
