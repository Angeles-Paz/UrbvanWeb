package mx.urbvan.dao;

import mx.urbvan.modelo.RutaB2B;
import mx.urbvan.modelo.RutaParada;
import mx.urbvan.modelo.RutaAsiento;
import mx.urbvan.modelo.TarifaVehiculo;
import mx.urbvan.modelo.Usuario;
import mx.urbvan.modelo.RutaB2BEvento;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class RutaB2BDAO {

    // ── Crear ruta con paradas en una transacción ─────────────────────────────
    public static int crear(RutaB2B ruta, List<RutaParada> paradas) throws Exception {
        try (Connection c = ConexionDB.obtener()) {
            c.setAutoCommit(false);
            try {
                String sqlRuta = """
                    INSERT INTO rutas_b2b
                        (empresa_id, vehiculo_id, operador_id, fecha_inicio,
                         fecha_fin_est, km_totales, costo_total, estado)
                    VALUES (?,?,?,?,?,?,?,'pendiente')
                    """;
                int rutaId;
                try (PreparedStatement ps = c.prepareStatement(
                        sqlRuta, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, ruta.getEmpresaId());
                    ps.setInt(2, ruta.getVehiculoId());
                    ps.setInt(3, ruta.getOperadorId());
                    ps.setTimestamp(4, Timestamp.valueOf(ruta.getFechaInicio()));
                    ps.setTimestamp(5, ruta.getFechaFinEst() != null
                            ? Timestamp.valueOf(ruta.getFechaFinEst()) : null);
                    ps.setDouble(6, ruta.getKmTotales());
                    ps.setDouble(7, ruta.getCostoTotal());
                    ps.executeUpdate();
                    ResultSet gk = ps.getGeneratedKeys();
                    gk.next();
                    rutaId = gk.getInt(1);
                }
                String sqlParada = """
                    INSERT INTO ruta_paradas
                        (ruta_id, orden, tipo, latitud, longitud,
                         nombre_lugar, tiempo_estancia, hora_estimada)
                    VALUES (?,?,?,?,?,?,?,?)
                    """;
                try (PreparedStatement ps = c.prepareStatement(sqlParada)) {
                    for (RutaParada p : paradas) {
                        ps.setInt(1, rutaId);
                        ps.setInt(2, p.getOrden());
                        ps.setString(3, p.getTipo().toDb());
                        ps.setDouble(4, p.getLatitud());
                        ps.setDouble(5, p.getLongitud());
                        ps.setString(6, p.getNombreLugar());
                        ps.setInt(7, p.getTiempoEstancia());
                        ps.setTimestamp(8, p.getHoraEstimada() != null
                                ? Timestamp.valueOf(p.getHoraEstimada()) : null);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                c.commit();
                return rutaId;
            } catch (Exception e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    // ── Buscar por id (con paradas y asientos) ────────────────────────────────
    public static RutaB2B buscarPorId(int id) throws Exception {
        String sql = buildSelectBase() + " WHERE r.id = ?";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return null;
            RutaB2B ruta = mapear(rs);
            ruta.setParadas(listarParadas(c, id));
            ruta.setAsientos(listarAsientos(c, id));
            return ruta;
        }
    }

    // ── Listar rutas de una empresa ───────────────────────────────────────────
    public static List<RutaB2B> listarDeEmpresa(int empresaId) throws Exception {
        return listarConFiltro("r.empresa_id = ?", empresaId);
    }

    // ── Listar rutas de un operador ───────────────────────────────────────────
    public static List<RutaB2B> listarDeOperador(int operadorId) throws Exception {
        return listarConFiltro("r.operador_id = ?", operadorId);
    }

    // ── Listar todas (Admin Urbvan) ───────────────────────────────────────────
    public static List<RutaB2B> listarTodas() throws Exception {
        String sql = buildSelectBase() + " ORDER BY r.fecha_inicio DESC";
        List<RutaB2B> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    // ── Listar rutas asignadas a un empleado (o admin_empresa) ───────────────
    public static List<RutaB2B> listarDeEmpleado(int usuarioId) throws Exception {
        String sql = """
            SELECT r.id, r.empresa_id, r.vehiculo_id, r.operador_id,
                   r.fecha_inicio, r.fecha_fin_est, r.km_totales, r.costo_total,
                   r.estado, r.asignacion_completa, r.cancelada_tarde,
                   r.penalizacion_puntos, r.created_at, r.updated_at,
                   e.nombre  AS empresa_nombre, e.score   AS empresa_score,
                   v.modelo  AS vehiculo_modelo, v.placa  AS vehiculo_placa,
                   v.capacidad AS vehiculo_capacidad,
                   op.nombre AS operador_nombre,
                   op.calificacion_promedio AS operador_score,
                   op.lat AS operador_lat, op.lng AS operador_lng,
                   0 AS asientos_ocupados
            FROM   ruta_asientos ra
            JOIN   rutas_b2b     r  ON ra.ruta_id    = r.id
            JOIN   empresas      e  ON r.empresa_id  = e.id
            JOIN   vehiculos     v  ON r.vehiculo_id = v.id
            JOIN   usuarios      op ON r.operador_id = op.id
            WHERE  ra.empleado_id = ? AND ra.activo = TRUE
            ORDER BY r.fecha_inicio DESC
            """;
        List<RutaB2B> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    // ── Cancelar ruta (via SP) ────────────────────────────────────────────────
    public static void cancelar(int rutaId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             CallableStatement cs = c.prepareCall("{CALL sp_cancelar_ruta_b2b(?)}")) {
            cs.setInt(1, rutaId);
            cs.execute();
        }
    }

    // ── Asignar asiento ───────────────────────────────────────────────────────
    public static void asignarAsiento(int rutaId, int empleadoId,
                                       int numeroAsiento) throws Exception {
        String sql = """
            INSERT INTO ruta_asientos (ruta_id, empleado_id, numero_asiento, activo)
            VALUES (?, ?, ?, TRUE)
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, rutaId);
            ps.setInt(2, empleadoId);
            ps.setInt(3, numeroAsiento);
            ps.executeUpdate();
        }
        actualizarAsignacionCompleta(rutaId);
    }

    // ── Remover asiento (soft-delete) ─────────────────────────────────────────
    public static void removerAsiento(int rutaId, int empleadoId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement("""
                     UPDATE ruta_asientos SET activo = FALSE
                     WHERE ruta_id = ? AND empleado_id = ? AND activo = TRUE
                     """)) {
            ps.setInt(1, rutaId);
            ps.setInt(2, empleadoId);
            ps.executeUpdate();
        }
    }

    // ── Calificar operador (via SP) ───────────────────────────────────────────
    public static void calificarOperador(int rutaId, int autorId,
                                          String tipoAutor, int operadorId,
                                          int puntuacion, String comentario) throws Exception {
        try (Connection c = ConexionDB.obtener();
             CallableStatement cs = c.prepareCall(
                     "{CALL sp_calificar_operador_b2b(?,?,?,?,?,?)}")) {
            cs.setInt(1, rutaId);
            cs.setInt(2, autorId);
            cs.setString(3, tipoAutor);
            cs.setInt(4, operadorId);
            cs.setInt(5, puntuacion);
            cs.setString(6, comentario);
            cs.execute();
        }
    }

    // ── Calificar empresa (via SP) ────────────────────────────────────────────
    public static void calificarEmpresa(int rutaId, int operadorId,
                                         int empresaId, int puntuacion,
                                         String comentario) throws Exception {
        try (Connection c = ConexionDB.obtener();
             CallableStatement cs = c.prepareCall(
                     "{CALL sp_calificar_empresa_b2b(?,?,?,?,?)}")) {
            cs.setInt(1, rutaId);
            cs.setInt(2, operadorId);
            cs.setInt(3, empresaId);
            cs.setInt(4, puntuacion);
            cs.setString(5, comentario);
            cs.execute();
        }
    }

    // ── Obtener tarifa por modelo ─────────────────────────────────────────────
    public static TarifaVehiculo obtenerTarifa(String modelo) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT * FROM tarifas_vehiculo WHERE modelo = ?")) {
            ps.setString(1, modelo);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return null;
            TarifaVehiculo t = new TarifaVehiculo();
            t.setId(rs.getInt("id"));
            t.setModelo(rs.getString("modelo"));
            t.setCapacidad(rs.getInt("capacidad"));
            t.setCostoPorKm(rs.getDouble("costo_por_km"));
            t.setCostoPorHora(rs.getDouble("costo_por_hora"));
            return t;
        }
    }

    // ── Operadores disponibles para una ventana de tiempo ─────────────────────
    public static List<Usuario> operadoresDisponibles(
            String modelo, java.time.LocalDateTime inicio,
            java.time.LocalDateTime fin) throws Exception {
        String sql = """
            SELECT u.id, u.nombre, u.calificacion_promedio, u.lat, u.lng,
                   v.id AS vehiculo_id
            FROM   usuarios  u
            JOIN   vehiculos v ON v.operador_id = u.id
            WHERE  u.rol     = 'operador'
              AND  u.activo  = TRUE
              AND  v.activo  = TRUE
              AND  v.modelo  = ?
              AND  u.id NOT IN (
                       SELECT operador_id FROM rutas_b2b
                       WHERE  estado IN ('pendiente','activa')
                         AND  fecha_inicio  < ?
                         AND  fecha_fin_est > ?
                   )
            ORDER BY u.calificacion_promedio DESC
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, modelo);
            ps.setTimestamp(2, Timestamp.valueOf(fin));
            ps.setTimestamp(3, Timestamp.valueOf(inicio));
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setNombre(rs.getString("nombre"));
                u.setCalificacionPromedio(rs.getDouble("calificacion_promedio"));
                u.setLat(rs.getDouble("lat"));
                u.setLng(rs.getDouble("lng"));
                lista.add(u);
            }
        }
        return lista;
    }

    // ── Layout de asientos de un modelo ──────────────────────────────────────
    public static List<int[]> layoutAsientos(String modelo) throws Exception {
        String sql = """
            SELECT numero_asiento, fila, columna, es_pasillo
            FROM   modelo_asientos_layout
            WHERE  modelo = ?
            ORDER BY numero_asiento
            """;
        List<int[]> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, modelo);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                lista.add(new int[]{
                    rs.getInt("numero_asiento"),
                    rs.getInt("columna"),
                    rs.getBoolean("es_pasillo") ? 1 : 0
                });
            }
        }
        return lista;
    }


    // ── Eventos operativos y tracking B2B ─────────────────────────────────────

    public static void cambiarEstadoOperativo(int rutaId, int operadorId, String accion,
                                               Integer paradaId, double lat, double lng,
                                               String comentario) throws Exception {
        RutaB2B ruta = buscarPorId(rutaId);
        if (ruta == null || ruta.getOperadorId() != operadorId) {
            throw new SecurityException("Ruta no asignada al operador autenticado.");
        }
        RutaB2BEvento.Tipo tipo;
        String nuevoEstado = null;
        switch (accion) {
            case "iniciar" -> { tipo = RutaB2BEvento.Tipo.INICIO_RUTA; nuevoEstado = "activa"; }
            case "llegar_parada" -> tipo = RutaB2BEvento.Tipo.LLEGADA_PARADA;
            case "salir_parada" -> tipo = RutaB2BEvento.Tipo.SALIDA_PARADA;
            case "terminar" -> { tipo = RutaB2BEvento.Tipo.FIN_RUTA; nuevoEstado = "completada"; }
            default -> throw new IllegalArgumentException("Acción B2B no válida: " + accion);
        }

        try (Connection c = ConexionDB.obtener()) {
            c.setAutoCommit(false);
            try {
                if (nuevoEstado != null) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE rutas_b2b SET estado=?, updated_at=NOW() WHERE id=? AND operador_id=?")) {
                        ps.setString(1, nuevoEstado);
                        ps.setInt(2, rutaId);
                        ps.setInt(3, operadorId);
                        ps.executeUpdate();
                    }
                }

                Integer ordenParada = null;
                if (paradaId != null && paradaId > 0) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "SELECT orden FROM ruta_paradas WHERE id=? AND ruta_id=?")) {
                        ps.setInt(1, paradaId);
                        ps.setInt(2, rutaId);
                        ResultSet rs = ps.executeQuery();
                        if (rs.next()) ordenParada = rs.getInt("orden");
                    }
                }

                try (PreparedStatement ps = c.prepareStatement("""
                        INSERT INTO ruta_b2b_eventos
                            (ruta_id, operador_id, parada_id, orden_parada, tipo, latitud, longitud, comentario)
                        VALUES (?,?,?,?,?,?,?,?)
                        """)) {
                    ps.setInt(1, rutaId);
                    ps.setInt(2, operadorId);
                    if (paradaId != null && paradaId > 0) ps.setInt(3, paradaId); else ps.setNull(3, Types.INTEGER);
                    if (ordenParada != null) ps.setInt(4, ordenParada); else ps.setNull(4, Types.INTEGER);
                    ps.setString(5, tipo.toDb());
                    if (lat != 0) ps.setDouble(6, lat); else ps.setNull(6, Types.DECIMAL);
                    if (lng != 0) ps.setDouble(7, lng); else ps.setNull(7, Types.DECIMAL);
                    ps.setString(8, comentario);
                    ps.executeUpdate();
                }

                if (lat != 0 && lng != 0) {
                    try (PreparedStatement ps = c.prepareStatement(
                            "UPDATE usuarios SET lat=?, lng=?, updated_at=NOW() WHERE id=?")) {
                        ps.setDouble(1, lat);
                        ps.setDouble(2, lng);
                        ps.setInt(3, operadorId);
                        ps.executeUpdate();
                    }
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    public static List<RutaB2BEvento> listarEventos(int rutaId) throws Exception {
        String sql = """
            SELECT ev.*, p.nombre_lugar AS parada_nombre
            FROM ruta_b2b_eventos ev
            LEFT JOIN ruta_paradas p ON ev.parada_id = p.id
            WHERE ev.ruta_id = ?
            ORDER BY ev.creado_en ASC, ev.id ASC
            """;
        List<RutaB2BEvento> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, rutaId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapearEvento(rs));
        }
        return lista;
    }

    public static RutaB2BEvento ultimoEvento(int rutaId) throws Exception {
        String sql = """
            SELECT ev.*, p.nombre_lugar AS parada_nombre
            FROM ruta_b2b_eventos ev
            LEFT JOIN ruta_paradas p ON ev.parada_id = p.id
            WHERE ev.ruta_id = ?
            ORDER BY ev.creado_en DESC, ev.id DESC
            LIMIT 1
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, rutaId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapearEvento(rs) : null;
        }
    }

    private static RutaB2BEvento mapearEvento(ResultSet rs) throws SQLException {
        RutaB2BEvento ev = new RutaB2BEvento();
        ev.setId(rs.getInt("id"));
        ev.setRutaId(rs.getInt("ruta_id"));
        ev.setOperadorId(rs.getInt("operador_id"));
        int parada = rs.getInt("parada_id");
        ev.setParadaId(rs.wasNull() ? null : parada);
        int orden = rs.getInt("orden_parada");
        ev.setOrdenParada(rs.wasNull() ? null : orden);
        ev.setTipo(RutaB2BEvento.Tipo.fromDb(rs.getString("tipo")));
        ev.setLatitud(rs.getDouble("latitud"));
        ev.setLongitud(rs.getDouble("longitud"));
        ev.setComentario(rs.getString("comentario"));
        Timestamp ts = rs.getTimestamp("creado_en");
        if (ts != null) ev.setCreadoEn(ts.toLocalDateTime());
        ev.setParadaNombre(rs.getString("parada_nombre"));
        return ev;
    }

    // ── Helpers privados ──────────────────────────────────────────────────────

    /**
     * SELECT base sin GROUP BY.
     * CORRECCIÓN: reemplaza LEFT JOIN + GROUP BY con subconsulta correlacionada
     * para contar asientos_ocupados. Esto evita el problema de ONLY_FULL_GROUP_BY
     * de MySQL 8 donde todas las columnas del SELECT deben estar en GROUP BY.
     */
    private static String buildSelectBase() {
        return """
            SELECT r.id, r.empresa_id, r.vehiculo_id, r.operador_id,
                   r.fecha_inicio, r.fecha_fin_est, r.km_totales, r.costo_total,
                   r.estado, r.asignacion_completa, r.cancelada_tarde,
                   r.penalizacion_puntos, r.created_at, r.updated_at,
                   e.nombre             AS empresa_nombre,
                   e.score              AS empresa_score,
                   v.modelo             AS vehiculo_modelo,
                   v.placa              AS vehiculo_placa,
                   v.capacidad          AS vehiculo_capacidad,
                   op.nombre            AS operador_nombre,
                   op.calificacion_promedio AS operador_score,
                   op.lat AS operador_lat, op.lng AS operador_lng,
                   (SELECT COUNT(*) FROM ruta_asientos ra
                    WHERE ra.ruta_id = r.id AND ra.activo = TRUE) AS asientos_ocupados
            FROM      rutas_b2b r
            JOIN      empresas  e  ON r.empresa_id  = e.id
            JOIN      vehiculos v  ON r.vehiculo_id = v.id
            JOIN      usuarios  op ON r.operador_id = op.id
            """;
    }

    private static List<RutaB2B> listarConFiltro(String where, int param) throws Exception {
        String sql = buildSelectBase()
                   + (where != null ? "WHERE " + where + " " : "")
                   + "ORDER BY r.fecha_inicio DESC";
        List<RutaB2B> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            if (where != null) ps.setInt(1, param);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    private static List<RutaParada> listarParadas(Connection c, int rutaId) throws SQLException {
        List<RutaParada> lista = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement(
                "SELECT * FROM ruta_paradas WHERE ruta_id=? ORDER BY orden")) {
            ps.setInt(1, rutaId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                RutaParada p = new RutaParada();
                p.setId(rs.getInt("id"));
                p.setRutaId(rutaId);
                p.setOrden(rs.getInt("orden"));
                p.setTipo(RutaParada.Tipo.fromDb(rs.getString("tipo")));
                p.setLatitud(rs.getDouble("latitud"));
                p.setLongitud(rs.getDouble("longitud"));
                p.setNombreLugar(rs.getString("nombre_lugar"));
                p.setTiempoEstancia(rs.getInt("tiempo_estancia"));
                Timestamp ts = rs.getTimestamp("hora_estimada");
                if (ts != null) p.setHoraEstimada(ts.toLocalDateTime());
                lista.add(p);
            }
        }
        return lista;
    }

    private static List<RutaAsiento> listarAsientos(Connection c, int rutaId) throws SQLException {
        List<RutaAsiento> lista = new ArrayList<>();
        try (PreparedStatement ps = c.prepareStatement("""
                SELECT ra.*, u.nombre AS empleado_nombre, u.email AS empleado_email
                FROM ruta_asientos ra
                JOIN usuarios u ON ra.empleado_id = u.id
                WHERE ra.ruta_id = ? AND ra.activo = TRUE
                ORDER BY ra.numero_asiento
                """)) {
            ps.setInt(1, rutaId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                RutaAsiento a = new RutaAsiento();
                a.setId(rs.getInt("id"));
                a.setRutaId(rutaId);
                a.setEmpleadoId(rs.getInt("empleado_id"));
                a.setNumeroAsiento(rs.getInt("numero_asiento"));
                a.setActivo(rs.getBoolean("activo"));
                a.setEmpleadoNombre(rs.getString("empleado_nombre"));
                a.setEmpleadoEmail(rs.getString("empleado_email"));
                lista.add(a);
            }
        }
        return lista;
    }

    private static void actualizarAsignacionCompleta(int rutaId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement("""
                     UPDATE rutas_b2b SET asignacion_completa = TRUE
                     WHERE id = ? AND EXISTS (
                         SELECT 1 FROM ruta_asientos WHERE ruta_id = ? AND activo = TRUE
                     )
                     """)) {
            ps.setInt(1, rutaId);
            ps.setInt(2, rutaId);
            ps.executeUpdate();
        }
    }

    private static RutaB2B mapear(ResultSet rs) throws SQLException {
        RutaB2B r = new RutaB2B();
        r.setId(rs.getInt("id"));
        r.setEmpresaId(rs.getInt("empresa_id"));
        r.setVehiculoId(rs.getInt("vehiculo_id"));
        r.setOperadorId(rs.getInt("operador_id"));
        Timestamp ti = rs.getTimestamp("fecha_inicio");
        if (ti != null) r.setFechaInicio(ti.toLocalDateTime());
        Timestamp tf = rs.getTimestamp("fecha_fin_est");
        if (tf != null) r.setFechaFinEst(tf.toLocalDateTime());
        r.setKmTotales(rs.getDouble("km_totales"));
        r.setCostoTotal(rs.getDouble("costo_total"));
        r.setEstado(RutaB2B.Estado.fromDb(rs.getString("estado")));
        r.setAsignacionCompleta(rs.getBoolean("asignacion_completa"));
        r.setCanceladaTarde(rs.getBoolean("cancelada_tarde"));
        r.setPenalizacionPuntos(rs.getDouble("penalizacion_puntos"));
        Timestamp tc = rs.getTimestamp("created_at");
        if (tc != null) r.setCreatedAt(tc.toLocalDateTime());
        r.setEmpresaNombre(rs.getString("empresa_nombre"));
        r.setEmpresaScore(rs.getDouble("empresa_score"));
        r.setVehiculoModelo(rs.getString("vehiculo_modelo"));
        r.setVehiculoPlaca(rs.getString("vehiculo_placa"));
        r.setVehiculoCapacidad(rs.getInt("vehiculo_capacidad"));
        r.setOperadorNombre(rs.getString("operador_nombre"));
        r.setOperadorScore(rs.getDouble("operador_score"));
        double opLat = rs.getDouble("operador_lat");
        r.setOperadorLat(rs.wasNull() ? null : opLat);
        double opLng = rs.getDouble("operador_lng");
        r.setOperadorLng(rs.wasNull() ? null : opLng);
        r.setAsientosOcupados(rs.getInt("asientos_ocupados"));
        return r;
    }
}
