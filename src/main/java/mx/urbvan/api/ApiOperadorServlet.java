package mx.urbvan.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ApiOperadorServlet – endpoints B2C para el operador en la app móvil.
 *
 * URL base: /api/operador/*
 *
 * GET  /api/operador/solicitudes   → solicitudes pendientes asignadas a este operador
 * GET  /api/operador/viaje-activo  → viaje activo del operador (si hay)
 * GET  /api/operador/historial     → historial de viajes completados/cancelados
 * POST /api/operador/responder     → aceptar o rechazar una solicitud
 * POST /api/operador/estado        → cambiar estado del viaje activo
 * POST /api/operador/posicion      → actualizar coordenadas GPS del operador
 */
@WebServlet("/api/operador/*")
public class ApiOperadorServlet extends HttpServlet {

    // ── GET ───────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String path = req.getPathInfo();
        if (path == null) path = "/";
        switch (path) {
            case "/solicitudes"   -> getSolicitudes(req, res);
            case "/viaje-activo"  -> getViajeActivo(req, res);
            case "/historial"     -> getHistorial(req, res);
            default -> ApiUtil.error(res, 404, "Endpoint no encontrado: " + path);
        }
    }

    /**
     * GET /api/operador/solicitudes
     * POLLING – equivalente a PanelOperadorServlet.buscarSolicitudesPendientes().
     * La app llama esto cada 5 segundos cuando el operador no tiene viaje activo.
     */
    private void getSolicitudes(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        String sql = """
            SELECT v.id, v.pasajero_id, v.operador_id, v.vehiculo_id,
                   v.origen_lat, v.origen_lng, v.origen_nombre,
                   v.destino_lat, v.destino_lng, v.destino_nombre,
                   v.distancia_km, v.duracion_min, v.costo, v.estado,
                   v.metodo_pago, v.cancelado_por, v.created_at, v.updated_at,
                   p.nombre AS pasajero_nombre,
                   NULL AS operador_nombre, 0.0 AS operador_score,
                   NULL AS vehiculo_modelo,  NULL AS vehiculo_placa,
                   NULL AS calificacion_dada
            FROM   solicitudes_operador s
            JOIN   viajes   v ON s.viaje_id    = v.id
            JOIN   usuarios p ON v.pasajero_id = p.id
            WHERE  s.operador_id = ?
              AND  s.estado      = 'pendiente'
              AND  v.estado      = 'asignado'
            ORDER BY s.created_at ASC
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, uid);
            ResultSet rs = ps.executeQuery();
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) json.append(",");
                first = false;
                json.append("{");
                json.append("\"viajeId\":"         ).append(rs.getInt("id")).append(",");
                json.append("\"pasajeroNombre\":\"").append(ApiUtil.esc(rs.getString("pasajero_nombre"))).append("\",");
                json.append("\"origenNombre\":\"" ).append(ApiUtil.esc(rs.getString("origen_nombre"))).append("\",");
                json.append("\"destinoNombre\":\"").append(ApiUtil.esc(rs.getString("destino_nombre"))).append("\",");
                json.append("\"distanciaKm\":"    ).append(rs.getDouble("distancia_km")).append(",");
                json.append("\"costo\":"          ).append(rs.getDouble("costo")).append(",");
                json.append("\"metodoPago\":\""   ).append(ApiUtil.esc(rs.getString("metodo_pago"))).append("\"");
                json.append("}");
            }
            json.append("]");
            ApiUtil.ok(res, "\"solicitudes\":" + json);
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cargar solicitudes.");
        }
    }

    /** GET /api/operador/viaje-activo */
    private void getViajeActivo(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        try {
            Viaje v = ViajeDAO.buscarActivoOperador(uid);
            ApiUtil.ok(res, "\"viaje\":" + ApiUtil.viajeJson(v));
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al obtener viaje activo.");
        }
    }

    /** GET /api/operador/historial */
    private void getHistorial(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        try {
            List<Viaje> lista = ViajeDAO.listarDeOperador(uid);
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            for (Viaje v : lista) {
                if (!first) json.append(",");
                first = false;
                json.append(ApiUtil.viajeJson(v));
            }
            json.append("]");
            ApiUtil.ok(res, "\"viajes\":" + json);
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cargar historial.");
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String path = req.getPathInfo();
        if (path == null) path = "/";
        switch (path) {
            case "/responder" -> responder(req, res);
            case "/estado"    -> cambiarEstado(req, res);
            case "/posicion"  -> actualizarPosicion(req, res);
            default -> ApiUtil.error(res, 404, "Endpoint no encontrado: " + path);
        }
    }

    /**
     * POST /api/operador/responder
     * Body: {"viajeId":5,"respuesta":"aceptar"}  o  "rechazar"
     * Equivalente a ResponderSolicitudServlet.doPost().
     */
    private void responder(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid      = ApiUtil.uid(req);
        String body     = ApiUtil.readBody(req);
        int    viajeId  = ApiUtil.jsonInt(body, "viajeId");
        String respuesta= ApiUtil.jsonVal(body,  "respuesta"); // "aceptar" | "rechazar"

        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getEstado() != Viaje.Estado.ASIGNADO) {
                ApiUtil.error(res, 409, "El viaje ya no está disponible."); return;
            }
            if ("aceptar".equals(respuesta)) {
                actualizarSolicitud(viajeId, uid, "aceptado");
                ViajeDAO.actualizarEstado(viajeId, Viaje.Estado.ACEPTADO);
                ApiUtil.ok(res, "\"msg\":\"Viaje aceptado. Dirígete al origen.\"");
            } else {
                actualizarSolicitud(viajeId, uid, "rechazado");
                // Cascada: buscar siguiente operador
                AsignadorOperador.manejarRechazo(viajeId, uid, v.getOrigenLat(), v.getOrigenLng());
                ApiUtil.ok(res, "\"msg\":\"Solicitud rechazada.\"");
            }
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al responder solicitud.");
        }
    }

    /**
     * POST /api/operador/estado
     * Body: {"viajeId":5,"accion":"en_camino"}
     * accion: "en_camino" | "en_curso" | "completar" | "cancelar"
     * Equivalente a CambiarEstadoViajeServlet.doPost().
     */
    private void cambiarEstado(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid    = ApiUtil.uid(req);
        String body   = ApiUtil.readBody(req);
        int    viajeId= ApiUtil.jsonInt(body, "viajeId");
        String accion = ApiUtil.jsonVal(body,  "accion");

        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getOperadorId() != uid) {
                ApiUtil.error(res, 404, "Viaje no encontrado."); return;
            }
            if ("cancelar".equals(accion)) {
                ViajeDAO.cancelar(viajeId, "operador");
            } else {
                Viaje.Estado nuevoEstado = switch (accion) {
                    case "en_camino" -> Viaje.Estado.EN_CAMINO;
                    case "en_curso"  -> Viaje.Estado.EN_CURSO;
                    case "completar" -> Viaje.Estado.COMPLETADO;
                    default -> v.getEstado();
                };
                ViajeDAO.actualizarEstado(viajeId, nuevoEstado);
            }
            ApiUtil.ok(res, "\"msg\":\"Estado actualizado.\"");
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cambiar estado.");
        }
    }

    /**
     * POST /api/operador/posicion
     * Body: {"lat":19.4326,"lng":-99.1332}
     * Actualiza lat/lng del operador en usuarios. Llamado cada 10 s desde la app.
     * Equivalente a ActualizarPosicionServlet.doPost().
     */
    private void actualizarPosicion(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid = ApiUtil.uid(req);
        String body= ApiUtil.readBody(req);
        double lat = ApiUtil.jsonDouble(body, "lat");
        double lng = ApiUtil.jsonDouble(body, "lng");

        if (lat == 0 && lng == 0) { ApiUtil.error(res, 400, "Coordenadas inválidas."); return; }

        String sql = "UPDATE usuarios SET lat=?, lng=?, updated_at=NOW() WHERE id=?";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setDouble(1, lat);
            ps.setDouble(2, lng);
            ps.setInt(3, uid);
            ps.executeUpdate();
            ApiUtil.ok(res, "\"msg\":\"Posición actualizada.\"");
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al actualizar posición.");
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private void actualizarSolicitud(int viajeId, int operadorId, String estado) throws Exception {
        String sql = """
            UPDATE solicitudes_operador SET estado=?
            WHERE  viaje_id=? AND operador_id=? AND estado='pendiente'
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, estado);
            ps.setInt(2, viajeId);
            ps.setInt(3, operadorId);
            ps.executeUpdate();
        }
    }
}
