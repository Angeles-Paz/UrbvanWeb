package mx.urbvan.util;

import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.sql.*;

/**
 * AsignadorOperador — centraliza la lógica de búsqueda y asignación
 * de operadores disponibles a viajes en estado EN_ASIGNACION.
 *
 * Se usa desde:
 *  - PagoServlet (intento inicial)
 *  - EstadoViajeServlet (reintentos por polling)
 *
 * Ubicación: src/main/java/mx/urbvan/util/AsignadorOperador.java
 */
public class AsignadorOperador {

    public static final int MAX_INTENTOS = 5;

    /**
     * Intenta asignar un operador disponible al viaje dado.
     * Respeta el historial de operadores que ya rechazaron este viaje.
     *
     * @return true si se asignó un operador, false si no hay disponibles.
     */
    public static boolean intentarAsignar(int idViaje) throws Exception {

        try (Connection conn = ConexionDB.obtener()) {

            Viaje viaje = new ViajeDAO().buscarPorId(idViaje);
            if (viaje == null) return false;
            if (viaje.getEstado() != Viaje.Estado.EN_ASIGNACION) return false;

            // Contar intentos previos
            int intentosPrevios = contarIntentos(conn, idViaje);
            if (intentosPrevios >= MAX_INTENTOS) return false;

            // Verificar si ya hay solicitud PENDIENTE activa
            if (tieneSolicitudPendiente(conn, idViaje)) return false;

            // Buscar operador disponible que NO haya rechazado este viaje
            int idOperador = buscarOperadorCercano(conn,
                viaje.getOrigenLat(), viaje.getOrigenLng(), idViaje);

            if (idOperador < 0) return false;

            // Crear solicitud de asignación
            String sqlSol = """
                INSERT INTO solicitudes_asignacion
                    (id_viaje, id_operador, numero_intento, estado)
                VALUES (?, ?, ?, 'PENDIENTE')
                """;
            try (PreparedStatement ps = conn.prepareStatement(sqlSol)) {
                ps.setInt(1, idViaje);
                ps.setInt(2, idOperador);
                ps.setInt(3, intentosPrevios + 1);
                ps.executeUpdate();
            }

            return true;
        }
    }

    /**
     * Verifica si una solicitud PENDIENTE expiró (más de 30 segundos sin respuesta).
     * Si expiró, la marca como EXPIRADA y permite crear una nueva.
     */
    public static void expirarSolicitudesPendientes(int idViaje) throws Exception {
        String sql = """
            UPDATE solicitudes_asignacion
            SET estado = 'EXPIRADA', fecha_respuesta = NOW()
            WHERE id_viaje = ?
              AND estado = 'PENDIENTE'
              AND TIMESTAMPDIFF(SECOND, fecha_envio, NOW()) > 30
            """;
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idViaje);
            ps.executeUpdate();
        }
    }

    // ── Privados ──────────────────────────────────────────────────

    private static boolean tieneSolicitudPendiente(Connection conn, int idViaje)
            throws SQLException {
        String sql = "SELECT 1 FROM solicitudes_asignacion WHERE id_viaje = ? AND estado = 'PENDIENTE'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idViaje);
            return ps.executeQuery().next();
        }
    }

    private static int contarIntentos(Connection conn, int idViaje) throws SQLException {
        String sql = "SELECT COUNT(*) FROM solicitudes_asignacion WHERE id_viaje = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, idViaje);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    private static int buscarOperadorCercano(Connection conn, double lat, double lng,
                                              int idViaje) throws SQLException {
        // Excluir operadores que ya rechazaron o expiraron en este viaje
        String sql = """
            SELECT o.id_operador,
                   ABS(p.latitud - ?) + ABS(p.longitud - ?) AS distancia
            FROM operadores o
            JOIN posicion_operador p ON p.id_operador = o.id_operador
            WHERE o.disponible = 1
              AND o.activo = 1
              AND o.id_operador NOT IN (
                SELECT id_operador FROM solicitudes_asignacion
                WHERE id_viaje = ? AND estado IN ('RECHAZADA','EXPIRADA')
              )
            ORDER BY distancia ASC
            LIMIT 1
            """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, lat);
            ps.setDouble(2, lng);
            ps.setInt(3,    idViaje);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("id_operador") : -1;
        }
    }
}
