package mx.urbvan.dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Types;

public class BitacoraDAO {
    public static void registrar(Integer idActor, String nombreActor, String rol,
                                 String accion, String descripcion, String direccionIp) {
        String sql = """
            INSERT INTO bitacora_acciones
            (id_actor, nombre_actor, rol, accion, descripcion, direccion_ip)
            VALUES (?, ?, ?, ?, ?, ?)
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (idActor != null) ps.setInt(1, idActor); else ps.setNull(1, Types.INTEGER);
            ps.setString(2, nombreActor);
            ps.setString(3, rol);
            ps.setString(4, accion);
            ps.setString(5, descripcion);
            ps.setString(6, direccionIp);
            ps.executeUpdate();
        } catch (Exception e) {
            System.out.println("No se pudo registrar la acción en bitácora: " + e.getMessage());
        }
    }
}
