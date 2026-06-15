package mx.urbvan.dao;

import mx.urbvan.modelo.Notificacion;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class NotificacionDAO {

    public static List<Notificacion> listarNoLeidas(int usuarioId) throws Exception {
        String sql = """
            SELECT * FROM notificaciones
            WHERE usuario_id = ? AND leida = FALSE
            ORDER BY created_at DESC LIMIT 20
            """;
        List<Notificacion> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    public static int contarNoLeidas(int usuarioId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) FROM notificaciones WHERE usuario_id=? AND leida=FALSE")) {
            ps.setInt(1, usuarioId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public static void marcarLeida(int id, int usuarioId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                "UPDATE notificaciones SET leida=TRUE WHERE id=? AND usuario_id=?")) {
            ps.setInt(1, id);
            ps.setInt(2, usuarioId);
            ps.executeUpdate();
        }
    }

    public static void marcarTodasLeidas(int usuarioId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                "UPDATE notificaciones SET leida=TRUE WHERE usuario_id=?")) {
            ps.setInt(1, usuarioId);
            ps.executeUpdate();
        }
    }

    private static Notificacion mapear(ResultSet rs) throws SQLException {
        Notificacion n = new Notificacion();
        n.setId(rs.getInt("id"));
        n.setUsuarioId(rs.getInt("usuario_id"));
        n.setTipo(rs.getString("tipo"));
        n.setMensaje(rs.getString("mensaje"));
        int rid = rs.getInt("ruta_id");
        n.setRutaId(rs.wasNull() ? null : rid);
        int vid = rs.getInt("viaje_id");
        n.setViajeId(rs.wasNull() ? null : vid);
        n.setLeida(rs.getBoolean("leida"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) n.setCreatedAt(ts.toLocalDateTime());
        return n;
    }
}
