package mx.urbvan.util;

import mx.urbvan.dao.ConexionDB;

import java.sql.*;

/**
 * AsignadorOperador - lógica de asignación en cascada para viajes B2C.
 *
 * CAMBIOS RESPECTO A v1:
 *   - v1 no tenía tabla solicitudes_operador: rastreaba intentos de otra forma.
 *   - v2 usa la tabla 'solicitudes_operador' para:
 *       a) Registrar cada intento de asignación (estado='pendiente').
 *       b) Excluir operadores que ya rechazaron este viaje.
 *       c) Limitar el total de intentos (configurable en tabla 'configuracion').
 *   - La query de operadores candidatos ahora viene de la tabla unificada 'usuarios'
 *     (rol='operador', activo=TRUE) + JOIN vehiculos (categoria='b2c', activo=TRUE).
 *   - El orden es: primero por distancia (Haversine), luego por calificacion_promedio DESC.
 *
 * Flujo de asignación en cascada:
 *   1. PagoServlet llama asignarSiguiente(viajeId, origenLat, origenLng).
 *   2. Este método busca el operador más cercano que NO haya rechazado ya el viaje.
 *   3. Actualiza viajes.estado → 'asignado' y viajes.operador_id → operadorId encontrado.
 *   4. Inserta una fila en solicitudes_operador (estado='pendiente').
 *   5. El operador ve la solicitud en su panel (PanelOperadorServlet con polling).
 *   6a. Si acepta → ResponderSolicitudServlet actualiza solicitudes_operador → 'aceptado'
 *       y viajes.estado → 'aceptado'.
 *   6b. Si rechaza → ResponderSolicitudServlet actualiza solicitudes_operador → 'rechazado'
 *       y llama de nuevo a asignarSiguiente() (cascada).
 *   7. Si no hay más operadores → viajes.estado → 'cancelado'.
 */
public class AsignadorOperador {

    // ── API pública ──────────────────────────────────────────────────────────

    /**
     * Busca el siguiente operador disponible para el viaje y lo asigna.
     *
     * @param viajeId    ID del viaje en estado 'solicitado' o 'asignado' (rechazado)
     * @param origenLat  Latitud del punto de recogida
     * @param origenLng  Longitud del punto de recogida
     * @return true si se asignó un operador, false si no hay ninguno disponible
     */
    public static boolean asignarSiguiente(int viajeId, double origenLat, double origenLng) {

        try (Connection conn = ConexionDB.obtener()) {

            // ── 1. Leer límite máximo de intentos desde configuración ────────
            int maxIntentos = leerMaxIntentos(conn);

            // ── 2. Contar intentos previos ───────────────────────────────────
            int intentosPrevios = contarIntentos(conn, viajeId);
            if (intentosPrevios >= maxIntentos) {
                cancelarViajeSinOperadores(conn, viajeId);
                return false;
            }

            // ── 3. Buscar el operador candidato ──────────────────────────────
            // Si el pasajero eligió una unidad específica en el flujo tipo Uber,
            // se respeta esa unidad y se toma su operador asignado.
            Integer vehiculoSolicitadoId = obtenerVehiculoSolicitado(conn, viajeId);
            Integer operadorId;
            Integer vehiculoId;

            if (vehiculoSolicitadoId != null) {
                operadorId = obtenerOperadorDeVehiculoDisponible(conn, viajeId, vehiculoSolicitadoId);
                vehiculoId = vehiculoSolicitadoId;
            } else {
                operadorId = buscarCandidato(conn, viajeId, origenLat, origenLng);
                vehiculoId = (operadorId != null) ? obtenerVehiculo(conn, operadorId) : null;
            }

            if (operadorId == null || vehiculoId == null) {
                cancelarViajeSinOperadores(conn, viajeId);
                return false;
            }

            // ── 4. Asignar: actualizar viaje + registrar solicitud ───────────
            asignarOperador(conn, viajeId, operadorId, vehiculoId);
            registrarSolicitud(conn, viajeId, operadorId);

            return true;

        } catch (Exception e) {
            System.err.println("[AsignadorOperador] Error en asignarSiguiente: " + e.getMessage());
            return false;
        }
    }

    /**
     * Marca una solicitud como rechazada e intenta asignar el siguiente operador.
     * Llamado por ResponderSolicitudServlet cuando el operador rechaza.
     *
     * @param viajeId    ID del viaje
     * @param operadorId ID del operador que rechazó
     * @param origenLat  Latitud del origen (para recalcular distancias)
     * @param origenLng  Longitud del origen
     * @return true si se encontró otro operador, false si se agotaron
     */
    public static boolean manejarRechazo(int viajeId, int operadorId,
                                          double origenLat, double origenLng) {
        try (Connection conn = ConexionDB.obtener()) {
            marcarRechazado(conn, viajeId, operadorId);
        } catch (Exception e) {
            System.err.println("[AsignadorOperador] Error al marcar rechazo: " + e.getMessage());
        }
        return asignarSiguiente(viajeId, origenLat, origenLng);
    }

    // ── Métodos privados ─────────────────────────────────────────────────────

    /**
     * Busca el operador disponible más cercano que no haya rechazado el viaje.
     *
     * Criterios de elegibilidad:
     *   - rol = 'operador' AND activo = TRUE
     *   - Tiene vehículo B2C activo asignado
     *   - No tiene viaje activo actualmente (no está en estado asignado/aceptado/en_camino)
     *   - No está en solicitudes_operador para este viajeId (no fue rechazado ni está pendiente)
     *
     * Orden: distancia Haversine ASC, luego calificacion_promedio DESC.
     */
    private static Integer buscarCandidato(Connection conn, int viajeId,
                                            double lat, double lng) throws SQLException {

        // La fórmula Haversine aproximada en MySQL es suficientemente precisa
        // para las distancias urbanas de CDMX (margen < 0.5% en <50 km)
        String sql = """
                SELECT u.id
                FROM   usuarios  u
                JOIN   vehiculos v ON v.operador_id = u.id
                                  AND v.categoria   = 'b2c'
                                  AND v.activo      = TRUE
                WHERE  u.rol    = 'operador'
                  AND  u.activo = TRUE
                  AND  u.lat IS NOT NULL
                  AND  u.lng IS NOT NULL
                  -- Sin viaje activo en este momento
                  AND  u.id NOT IN (
                           SELECT operador_id FROM viajes
                           WHERE  estado IN ('asignado','aceptado','en_camino','en_curso')
                             AND  operador_id IS NOT NULL
                       )
                  -- No fue rechazado ni tiene solicitud pendiente para este viaje
                  AND  u.id NOT IN (
                           SELECT operador_id FROM solicitudes_operador
                           WHERE  viaje_id = ?
                       )
                  -- Solo en radio configurado
                  AND  (6371 * ACOS(
                           COS(RADIANS(?)) * COS(RADIANS(u.lat))
                           * COS(RADIANS(u.lng) - RADIANS(?))
                           + SIN(RADIANS(?)) * SIN(RADIANS(u.lat))
                       )) <= (
                           SELECT CAST(valor AS DECIMAL(5,2))
                           FROM   configuracion
                           WHERE  clave = 'b2c_radio_busqueda_km'
                       )
                ORDER BY
                    -- Primero: el más cercano
                    (6371 * ACOS(
                        COS(RADIANS(?)) * COS(RADIANS(u.lat))
                        * COS(RADIANS(u.lng) - RADIANS(?))
                        + SIN(RADIANS(?)) * SIN(RADIANS(u.lat))
                    )) ASC,
                    -- Desempate: mejor calificación
                    u.calificacion_promedio DESC
                LIMIT 1
                """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ps.setDouble(2, lat);
            ps.setDouble(3, lng);
            ps.setDouble(4, lat);
            ps.setDouble(5, lat);
            ps.setDouble(6, lng);
            ps.setDouble(7, lat);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("id") : null;
        }
    }


    /** Devuelve el vehículo elegido por el pasajero al crear el viaje, si existe. */
    private static Integer obtenerVehiculoSolicitado(Connection conn, int viajeId) throws SQLException {
        String sql = "SELECT vehiculo_id FROM viajes WHERE id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                int id = rs.getInt("vehiculo_id");
                return rs.wasNull() || id <= 0 ? null : id;
            }
            return null;
        }
    }

    /** Valida que la unidad B2C elegida siga activa, tenga operador y no esté ocupada. */
    private static Integer obtenerOperadorDeVehiculoDisponible(Connection conn, int viajeId, int vehiculoId) throws SQLException {
        String sql = """
                SELECT u.id
                FROM vehiculos v
                JOIN usuarios u ON u.id = v.operador_id
                WHERE v.id = ?
                  AND v.categoria = 'b2c'
                  AND v.activo = TRUE
                  AND u.rol = 'operador'
                  AND u.activo = TRUE
                  AND u.id NOT IN (
                        SELECT operador_id FROM viajes
                        WHERE estado IN ('asignado','aceptado','en_camino','en_curso')
                          AND operador_id IS NOT NULL
                          AND id <> ?
                  )
                  AND u.id NOT IN (
                        SELECT operador_id FROM solicitudes_operador
                        WHERE viaje_id = ?
                  )
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vehiculoId);
            ps.setInt(2, viajeId);
            ps.setInt(3, viajeId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("id") : null;
        }
    }

    /** Obtiene el id del vehículo B2C activo asignado al operador. */
    private static Integer obtenerVehiculo(Connection conn, int operadorId) throws SQLException {
        String sql = """
                SELECT id FROM vehiculos
                WHERE  operador_id = ?
                  AND  categoria   = 'b2c'
                  AND  activo      = TRUE
                LIMIT 1
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, operadorId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("id") : null;
        }
    }

    /** Actualiza el viaje con el operador y vehículo asignado. */
    private static void asignarOperador(Connection conn, int viajeId,
                                         int operadorId, int vehiculoId) throws SQLException {
        String sql = """
                UPDATE viajes
                SET    operador_id = ?,
                       vehiculo_id = ?,
                       estado      = 'asignado',
                       updated_at  = NOW()
                WHERE  id = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, operadorId);
            ps.setInt(2, vehiculoId);
            ps.setInt(3, viajeId);
            ps.executeUpdate();
        }
    }

    /** Inserta una fila en solicitudes_operador con estado 'pendiente'. */
    private static void registrarSolicitud(Connection conn, int viajeId,
                                            int operadorId) throws SQLException {
        String sql = """
                INSERT INTO solicitudes_operador (viaje_id, operador_id, estado)
                VALUES (?, ?, 'pendiente')
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ps.setInt(2, operadorId);
            ps.executeUpdate();
        }
    }

    /** Marca la solicitud del operador como rechazada. */
    private static void marcarRechazado(Connection conn, int viajeId,
                                         int operadorId) throws SQLException {
        String sql = """
                UPDATE solicitudes_operador
                SET    estado = 'rechazado'
                WHERE  viaje_id    = ?
                  AND  operador_id = ?
                  AND  estado      = 'pendiente'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ps.setInt(2, operadorId);
            ps.executeUpdate();
        }
    }

    /** Cancela el viaje cuando se agotaron todos los operadores disponibles. */
    private static void cancelarViajeSinOperadores(Connection conn, int viajeId) throws SQLException {
        String sql = """
                UPDATE viajes
                SET    estado       = 'cancelado',
                       cancelado_por = 'sistema',
                       updated_at   = NOW()
                WHERE  id = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ps.executeUpdate();
        }
    }

    /** Cuenta los intentos de asignación ya realizados para este viaje. */
    private static int contarIntentos(Connection conn, int viajeId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM solicitudes_operador WHERE viaje_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, viajeId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    /** Lee el máximo de intentos permitidos desde la tabla configuracion. */
    private static int leerMaxIntentos(Connection conn) throws SQLException {
        String sql = "SELECT valor FROM configuracion WHERE clave = 'b2c_max_operadores'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            return rs.next() ? Integer.parseInt(rs.getString("valor")) : 5;
        }
    }

    // Constructor privado: clase de utilidad, no se instancia
    private AsignadorOperador() {}
}
