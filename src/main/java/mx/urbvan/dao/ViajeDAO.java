package mx.urbvan.dao;

import mx.urbvan.modelo.Viaje;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * ViajeDAO - acceso a datos de viajes B2C.
 * CAMBIOS vs v1: columnas renombradas (id_usuario→pasajero_id, origen_direccion→origen_nombre,
 * precio_total→costo, etc.), estado usa Viaje.Estado enum con toDb()/fromDb().
 */
public class ViajeDAO {

    // ── Insertar nuevo viaje ─────────────────────────────────────────────────
    public static int insertar(Viaje v) throws Exception {
        String sql = """
            INSERT INTO viajes
                (pasajero_id, vehiculo_id, origen_lat, origen_lng, origen_nombre,
                 destino_lat, destino_lng, destino_nombre,
                 distancia_km, duracion_min, costo, estado, metodo_pago)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,'solicitado',?)
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, v.getPasajeroId());
            if (v.getVehiculoId() > 0) ps.setInt(2, v.getVehiculoId()); else ps.setNull(2, Types.INTEGER);
            ps.setDouble(3, v.getOrigenLat());
            ps.setDouble(4, v.getOrigenLng());
            ps.setString(5, v.getOrigenNombre());
            ps.setDouble(6, v.getDestinoLat());
            ps.setDouble(7, v.getDestinoLng());
            ps.setString(8, v.getDestinoNombre());
            ps.setDouble(9, v.getDistanciaKm());
            ps.setInt(10, v.getDuracionMin());
            ps.setDouble(11, v.getCosto());
            ps.setString(12, v.getMetodoPago() != null ? v.getMetodoPago() : "efectivo");
            ps.executeUpdate();
            ResultSet gk = ps.getGeneratedKeys();
            return gk.next() ? gk.getInt(1) : -1;
        }
    }

    // ── Buscar por id ────────────────────────────────────────────────────────
    public static Viaje buscarPorId(int id) throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   cal.puntuacion AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id  = p.id
            LEFT JOIN usuarios  o  ON v.operador_id  = o.id
            LEFT JOIN vehiculos vh ON v.vehiculo_id  = vh.id
            LEFT JOIN calificaciones_viaje cal ON cal.viaje_id = v.id
            WHERE v.id = ?
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    // ── Viaje activo del pasajero ────────────────────────────────────────────
    public static Viaje buscarActivoPasajero(int pasajeroId) throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   NULL AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id = p.id
            LEFT JOIN usuarios  o  ON v.operador_id  = o.id
            LEFT JOIN vehiculos vh ON v.vehiculo_id  = vh.id
            WHERE v.pasajero_id = ?
              AND v.estado NOT IN ('completado','cancelado')
            ORDER BY v.created_at DESC LIMIT 1
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, pasajeroId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    // ── Viaje activo del operador ─────────────────────────────────────────────
    public static Viaje buscarActivoOperador(int operadorId) throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   NULL AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id = p.id
            JOIN  usuarios  o  ON v.operador_id  = o.id
            LEFT JOIN vehiculos vh ON v.vehiculo_id  = vh.id
            WHERE v.operador_id = ?
              AND v.estado IN ('aceptado','en_camino','en_curso')
            ORDER BY v.updated_at DESC LIMIT 1
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, operadorId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    // ── Historial del pasajero ────────────────────────────────────────────────
    public static List<Viaje> listarDePasajero(int pasajeroId) throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   cal.puntuacion AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id = p.id
            LEFT JOIN usuarios  o   ON v.operador_id = o.id
            LEFT JOIN vehiculos vh  ON v.vehiculo_id  = vh.id
            LEFT JOIN calificaciones_viaje cal ON cal.viaje_id = v.id
            WHERE v.pasajero_id = ?
            ORDER BY v.created_at DESC
            """;
        return ejecutarLista(sql, pasajeroId);
    }

    // ── Historial del operador ────────────────────────────────────────────────
    public static List<Viaje> listarDeOperador(int operadorId) throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   cal.puntuacion AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id = p.id
            JOIN  usuarios  o  ON v.operador_id  = o.id
            LEFT JOIN vehiculos vh ON v.vehiculo_id = vh.id
            LEFT JOIN calificaciones_viaje cal ON cal.viaje_id = v.id
            WHERE v.operador_id = ?
            ORDER BY v.created_at DESC
            """;
        return ejecutarLista(sql, operadorId);
    }

    // ── Todos los viajes (admin) ──────────────────────────────────────────────
    public static List<Viaje> listarTodos() throws Exception {
        String sql = """
            SELECT v.*, p.nombre AS pasajero_nombre,
                   o.nombre AS operador_nombre, o.calificacion_promedio AS operador_score,
                   vh.modelo AS vehiculo_modelo, vh.placa AS vehiculo_placa,
                   cal.puntuacion AS calificacion_dada
            FROM  viajes v
            JOIN  usuarios p  ON v.pasajero_id = p.id
            LEFT JOIN usuarios  o   ON v.operador_id = o.id
            LEFT JOIN vehiculos vh  ON v.vehiculo_id  = vh.id
            LEFT JOIN calificaciones_viaje cal ON cal.viaje_id = v.id
            ORDER BY v.created_at DESC LIMIT 200
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<Viaje> lista = new ArrayList<>();
            while (rs.next()) lista.add(mapear(rs));
            return lista;
        }
    }

    // ── Actualizar estado ─────────────────────────────────────────────────────
    public static void actualizarEstado(int id, Viaje.Estado estado) throws Exception {
        String sql = "UPDATE viajes SET estado=?, updated_at=NOW() WHERE id=?";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, estado.toDb());
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    // ── Eliminar viaje pendiente antes de confirmar pago ─────────────────────
    public static boolean eliminarSiPendiente(int id, int pasajeroId) throws Exception {
        String sql = "DELETE FROM viajes WHERE id=? AND pasajero_id=? AND estado='solicitado'";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.setInt(2, pasajeroId);
            return ps.executeUpdate() > 0;
        }
    }

    // ── Cancelar viaje ───────────────────────────────────────────────────────
    public static void cancelar(int id, String canceladoPor) throws Exception {
        String sql = """
            UPDATE viajes SET estado='cancelado', cancelado_por=?, updated_at=NOW()
            WHERE id=?
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, canceladoPor);
            ps.setInt(2, id);
            ps.executeUpdate();
        }
    }

    // ── Insertar calificación ────────────────────────────────────────────────
    public static void insertarCalificacion(int viajeId, int autorId,
                                             int operadorId, int puntuacion,
                                             String comentario) throws Exception {
        String sql = """
            INSERT INTO calificaciones_viaje
                (viaje_id, autor_id, operador_id, puntuacion, comentario)
            VALUES (?,?,?,?,?)
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ps.setInt(2, autorId);
            ps.setInt(3, operadorId);
            ps.setInt(4, puntuacion);
            ps.setString(5, comentario);
            ps.executeUpdate();
        }
        // Recalcular score del operador via SP
        try (Connection c = ConexionDB.obtener();
             CallableStatement cs = c.prepareCall("{CALL sp_recalcular_score_operador(?)}")) {
            cs.setInt(1, operadorId);
            cs.execute();
        }
    }

    // ── Counts para dashboard admin ──────────────────────────────────────────
    public static int contarPorEstado(String estado) throws Exception {
        String sql = "SELECT COUNT(*) FROM viajes WHERE estado=?";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, estado);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    // ── Helpers privados ──────────────────────────────────────────────────────
    private static List<Viaje> ejecutarLista(String sql, int param) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, param);
            ResultSet rs = ps.executeQuery();
            List<Viaje> lista = new ArrayList<>();
            while (rs.next()) lista.add(mapear(rs));
            return lista;
        }
    }

    private static Viaje mapear(ResultSet rs) throws SQLException {
        Viaje v = new Viaje();
        v.setId(rs.getInt("id"));
        v.setPasajeroId(rs.getInt("pasajero_id"));
        v.setOperadorId(rs.getInt("operador_id"));
        v.setVehiculoId(rs.getInt("vehiculo_id"));
        v.setOrigenLat(rs.getDouble("origen_lat"));
        v.setOrigenLng(rs.getDouble("origen_lng"));
        v.setOrigenNombre(rs.getString("origen_nombre"));
        v.setDestinoLat(rs.getDouble("destino_lat"));
        v.setDestinoLng(rs.getDouble("destino_lng"));
        v.setDestinoNombre(rs.getString("destino_nombre"));
        v.setDistanciaKm(rs.getDouble("distancia_km"));
        v.setDuracionMin(rs.getInt("duracion_min"));
        v.setCosto(rs.getDouble("costo"));
        v.setEstado(Viaje.Estado.fromDb(rs.getString("estado")));
        v.setMetodoPago(rs.getString("metodo_pago"));
        v.setCanceladoPor(rs.getString("cancelado_por"));
        // Enriquecidos (de JOINs)
        v.setPasajeroNombre(rs.getString("pasajero_nombre"));
        v.setOperadorNombre(rs.getString("operador_nombre"));
        v.setOperadorScore(rs.getDouble("operador_score"));
        v.setVehiculoModelo(rs.getString("vehiculo_modelo"));
        v.setVehiculoPlaca(rs.getString("vehiculo_placa"));
        int cal = rs.getInt("calificacion_dada");
        v.setCalificacionDada(rs.wasNull() ? -1 : cal);
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) v.setCreatedAt(ts.toLocalDateTime());
        return v;
    }
}
