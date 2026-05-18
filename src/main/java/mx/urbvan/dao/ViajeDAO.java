package mx.urbvan.dao;

import mx.urbvan.modelo.Viaje;
import java.sql.*;
import java.time.LocalDateTime;

/**
 * ViajeDAO — todas las operaciones SQL sobre la tabla `viajes`.
 * Ubicación: src/main/java/mx/urbvan/dao/ViajeDAO.java
 */
public class ViajeDAO {

    /**
     * Inserta un nuevo viaje en estado SOLICITADO y devuelve su ID generado.
     */
    public int insertar(Viaje v) throws Exception {
        String sql = """
            INSERT INTO viajes
              (id_usuario, origen_lat, origen_lng, origen_direccion,
               destino_lat, destino_lng, destino_direccion,
               distancia_km, precio_total, estado, eta_viaje_min)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'SOLICITADO', ?)
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,    v.getIdUsuario());
            ps.setDouble(2, v.getOrigenLat());
            ps.setDouble(3, v.getOrigenLng());
            ps.setString(4, v.getOrigenDireccion());
            ps.setDouble(5, v.getDestinoLat());
            ps.setDouble(6, v.getDestinoLng());
            ps.setString(7, v.getDestinoDireccion());
            ps.setDouble(8, v.getDistanciaKm());
            ps.setDouble(9, v.getPrecioTotal());
            ps.setInt(10,   v.getEtaViajeMin());
            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) return rs.getInt(1);
            throw new SQLException("No se generó ID para el viaje.");
        }
    }

    /**
     * Busca un viaje por su ID.
     */
    public Viaje buscarPorId(int idViaje) throws Exception {
        String sql = "SELECT * FROM viajes WHERE id_viaje = ?";
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idViaje);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
            return null;
        }
    }

    /**
     * Devuelve el viaje activo de un pasajero (no completado ni cancelado).
     */
    public Viaje buscarActivoPorUsuario(int idUsuario) throws Exception {
        String sql = """
            SELECT * FROM viajes
            WHERE id_usuario = ?
              AND estado NOT IN ('COMPLETADO','CANCELADO')
            ORDER BY fecha_solicitud DESC LIMIT 1
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idUsuario);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
            return null;
        }
    }

    /**
     * Actualiza el estado de un viaje y opcionalmente una fecha asociada.
     */
    public void actualizarEstado(int idViaje, Viaje.Estado nuevoEstado) throws Exception {
        String columnaFecha = switch (nuevoEstado) {
            case ACEPTADO          -> ", fecha_aceptacion = NOW()";
            case VIAJE_INICIADO    -> ", fecha_inicio = NOW()";
            case COMPLETADO        -> ", fecha_fin = NOW()";
            default                -> "";
        };
        String sql = "UPDATE viajes SET estado = ?" + columnaFecha + " WHERE id_viaje = ?";
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, nuevoEstado.name());
            ps.setInt(2, idViaje);
            ps.executeUpdate();
        }
    }

    /**
     * Asigna un operador al viaje y cambia estado a ACEPTADO.
     */
    public void asignarOperador(int idViaje, int idOperador, int etaOperadorMin) throws Exception {
        String sql = """
            UPDATE viajes
            SET id_operador = ?, estado = 'ACEPTADO',
                eta_operador_min = ?, fecha_aceptacion = NOW()
            WHERE id_viaje = ?
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idOperador);
            ps.setInt(2, etaOperadorMin);
            ps.setInt(3, idViaje);
            ps.executeUpdate();
        }
    }

    /**
     * Devuelve el viaje activo asignado a un operador.
     */
    public Viaje buscarActivoPorOperador(int idOperador) throws Exception {
        String sql = """
            SELECT * FROM viajes
            WHERE id_operador = ?
              AND estado NOT IN ('COMPLETADO','CANCELADO')
            ORDER BY fecha_solicitud DESC LIMIT 1
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idOperador);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapear(rs);
            return null;
        }
    }

    // ── Mapeo ResultSet → Viaje ────────────────────────────────────

    private Viaje mapear(ResultSet rs) throws SQLException {
        Viaje v = new Viaje();
        v.setIdViaje(rs.getInt("id_viaje"));
        v.setIdUsuario(rs.getInt("id_usuario"));
        v.setIdOperador(rs.getInt("id_operador"));
        v.setOrigenLat(rs.getDouble("origen_lat"));
        v.setOrigenLng(rs.getDouble("origen_lng"));
        v.setOrigenDireccion(rs.getString("origen_direccion"));
        v.setDestinoLat(rs.getDouble("destino_lat"));
        v.setDestinoLng(rs.getDouble("destino_lng"));
        v.setDestinoDireccion(rs.getString("destino_direccion"));
        v.setDistanciaKm(rs.getDouble("distancia_km"));
        v.setPrecioTotal(rs.getDouble("precio_total"));
        v.setEstado(Viaje.Estado.valueOf(rs.getString("estado")));
        v.setEtaOperadorMin(rs.getInt("eta_operador_min"));
        v.setEtaViajeMin(rs.getInt("eta_viaje_min"));

        Timestamp ts;
        ts = rs.getTimestamp("fecha_solicitud");
        if (ts != null) v.setFechaSolicitud(ts.toLocalDateTime());
        ts = rs.getTimestamp("fecha_aceptacion");
        if (ts != null) v.setFechaAceptacion(ts.toLocalDateTime());
        ts = rs.getTimestamp("fecha_inicio");
        if (ts != null) v.setFechaInicio(ts.toLocalDateTime());
        ts = rs.getTimestamp("fecha_fin");
        if (ts != null) v.setFechaFin(ts.toLocalDateTime());

        return v;
    }

    /**
     * Obtiene la última posición conocida del operador para el polling.
     * Devuelve [lat, lng] o null si no tiene posición registrada.
     */
    public double[] obtenerPosicionOperador(int idOperador) throws Exception {
        String sql = "SELECT latitud, longitud FROM posicion_operador WHERE id_operador = ?";
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idOperador);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return new double[]{ rs.getDouble("latitud"), rs.getDouble("longitud") };
            }
            return null;
        }
    }
}
