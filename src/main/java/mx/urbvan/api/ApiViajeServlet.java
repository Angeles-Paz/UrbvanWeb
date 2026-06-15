package mx.urbvan.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.VehiculoDAO;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Vehiculo;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;

import java.io.IOException;
import java.sql.*;
import java.util.List;

/**
 * ApiViajeServlet – endpoints de viajes B2C para la app móvil.
 *
 * URL base: /api/viaje/*
 *
 * GET  /api/viaje/vehiculos   → lista de vehículos B2C disponibles
 * GET  /api/viaje/activo      → viaje activo del pasajero (o null)
 * GET  /api/viaje/estado?id=  → polling: estado + posición operador + ETA
 * GET  /api/viaje/historial   → historial de viajes del pasajero
 * POST /api/viaje/solicitar   → crea el viaje (estado='solicitado')
 * POST /api/viaje/confirmar   → confirma pago y dispara AsignadorOperador
 * POST /api/viaje/cancelar    → cancela el viaje activo
 */
@WebServlet("/api/viaje/*")
public class ApiViajeServlet extends HttpServlet {

    // ── GET ───────────────────────────────────────────────────────────────────

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String path = req.getPathInfo();
        if (path == null) path = "/";

        switch (path) {
            case "/vehiculos" -> getVehiculos(req, res);
            case "/activo"    -> getViajeActivo(req, res);
            case "/estado"    -> getEstadoViaje(req, res);
            case "/historial" -> getHistorial(req, res);
            default -> ApiUtil.error(res, 404, "Endpoint no encontrado: " + path);
        }
    }

    // GET /api/viaje/vehiculos
    private void getVehiculos(HttpServletRequest req, HttpServletResponse res) throws IOException {
        try {
            List<Vehiculo> lista = VehiculoDAO.listarB2CDisponibles();
            StringBuilder json = new StringBuilder("[");
            for (int i = 0; i < lista.size(); i++) {
                if (i > 0) json.append(",");
                json.append(ApiUtil.vehiculoJson(lista.get(i)));
            }
            json.append("]");
            ApiUtil.ok(res, "\"vehiculos\":" + json);
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cargar vehículos: " + e.getMessage());
        }
    }

    // GET /api/viaje/activo
    private void getViajeActivo(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        try {
            Viaje v = ViajeDAO.buscarActivoPasajero(uid);
            if (v == null) {
                ApiUtil.ok(res, "\"viaje\":null");
            } else {
                double[] opPos = obtenerPosicionOperador(v.getOperadorId());
                String vJson = opPos != null
                        ? ApiUtil.viajeJson(v, opPos[0], opPos[1])
                        : ApiUtil.viajeJson(v);
                ApiUtil.ok(res, "\"viaje\":" + vJson);
            }
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al obtener viaje activo: " + e.getMessage());
        }
    }

    /**
     * GET /api/viaje/estado?id=<viajeId>
     * Endpoint de POLLING (cada 5 s desde la app).
     * Devuelve el estado actualizado + posición GPS del operador para mover el marcador en el mapa.
     */
    private void getEstadoViaje(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid    = ApiUtil.uid(req);
        String ids = req.getParameter("id");
        if (ids == null || ids.isBlank()) { ApiUtil.error(res, 400, "Parámetro 'id' requerido."); return; }
        int viajeId;
        try { viajeId = Integer.parseInt(ids); } catch (NumberFormatException e) { ApiUtil.error(res, 400, "id inválido."); return; }

        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getPasajeroId() != uid) {
                ApiUtil.error(res, 404, "Viaje no encontrado.");
                return;
            }
            double[] opPos = obtenerPosicionOperador(v.getOperadorId());
            String vJson = opPos != null
                    ? ApiUtil.viajeJson(v, opPos[0], opPos[1])
                    : ApiUtil.viajeJson(v);
            ApiUtil.ok(res, "\"viaje\":" + vJson);
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al obtener estado del viaje.");
        }
    }

    // GET /api/viaje/historial
    private void getHistorial(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        try {
            List<Viaje> lista = ViajeDAO.listarDePasajero(uid);
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
            case "/solicitar" -> solicitar(req, res);
            case "/confirmar" -> confirmar(req, res);
            case "/cancelar"  -> cancelar(req, res);
            default -> ApiUtil.error(res, 404, "Endpoint no encontrado: " + path);
        }
    }

    /**
     * POST /api/viaje/solicitar
     * Body JSON: {origenLat, origenLng, origenNombre, destinoLat, destinoLng, destinoNombre,
     *             distanciaKm, duracionMin, vehiculoId, metodoPago}
     * Crea el viaje con estado='solicitado'. Mismo flujo que SolicitarViajeServlet.doPost().
     */
    private void solicitar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid          = ApiUtil.uid(req);
        String body         = ApiUtil.readBody(req);
        double origenLat    = ApiUtil.jsonDouble(body, "origenLat");
        double origenLng    = ApiUtil.jsonDouble(body, "origenLng");
        String origenNombre = ApiUtil.jsonVal(body,    "origenNombre");
        double destinoLat   = ApiUtil.jsonDouble(body, "destinoLat");
        double destinoLng   = ApiUtil.jsonDouble(body, "destinoLng");
        String destinoNombre= ApiUtil.jsonVal(body,    "destinoNombre");
        double distanciaKm  = ApiUtil.jsonDouble(body, "distanciaKm");
        int    duracionMin  = ApiUtil.jsonInt(body,    "duracionMin");
        int    vehiculoId   = ApiUtil.jsonInt(body,    "vehiculoId");
        String metodoPago   = ApiUtil.jsonVal(body,    "metodoPago");

        if (vehiculoId <= 0) { ApiUtil.error(res, 400, "vehiculoId inválido."); return; }
        if (origenNombre == null || destinoNombre == null) {
            ApiUtil.error(res, 400, "Origen y destino son requeridos."); return;
        }

        // Calcular costo usando los valores de configuración en BD
        double costo = calcularCosto(distanciaKm);

        Viaje v = new Viaje();
        v.setPasajeroId(uid);
        v.setVehiculoId(vehiculoId);
        v.setOrigenLat(origenLat);      v.setOrigenLng(origenLng);
        v.setOrigenNombre(origenNombre);
        v.setDestinoLat(destinoLat);    v.setDestinoLng(destinoLng);
        v.setDestinoNombre(destinoNombre);
        v.setDistanciaKm(distanciaKm);
        v.setDuracionMin(Math.max(1, duracionMin));
        v.setCosto(costo);
        v.setMetodoPago("tarjeta".equalsIgnoreCase(metodoPago) ? "tarjeta" : "efectivo");

        try {
            int viajeId = ViajeDAO.insertar(v);
            v.setId(viajeId);
            ApiUtil.ok(res, "\"viaje\":" + ApiUtil.viajeJson(v) + ",\"viajeId\":" + viajeId);
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al crear el viaje: " + e.getMessage());
        }
    }

    /**
     * POST /api/viaje/confirmar
     * Body JSON: {"viajeId": 5}
     * Confirma el pago y dispara AsignadorOperador en cascada.
     * Mismo flujo que PagoServlet.doPost().
     */
    private void confirmar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid    = ApiUtil.uid(req);
        String body   = ApiUtil.readBody(req);
        int    viajeId= ApiUtil.jsonInt(body, "viajeId");

        if (viajeId <= 0) { ApiUtil.error(res, 400, "viajeId requerido."); return; }

        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getPasajeroId() != uid) {
                ApiUtil.error(res, 404, "Viaje no encontrado.");
                return;
            }
            // Disparar asignación en cascada (mismo que PagoServlet)
            boolean asignado = AsignadorOperador.asignarSiguiente(
                    viajeId, v.getOrigenLat(), v.getOrigenLng());
            if (asignado) {
                ApiUtil.ok(res, "\"msg\":\"Operador buscado. Espera aceptación.\"");
            } else {
                ApiUtil.ok(res, "\"msg\":\"Sin operadores disponibles en este momento. Intenta de nuevo.\"");
            }
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al confirmar el viaje.");
        }
    }

    /**
     * POST /api/viaje/cancelar
     * Body JSON: {"viajeId": 5}
     * Cancela el viaje si aún no está en_camino o en_curso.
     */
    private void cancelar(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int    uid    = ApiUtil.uid(req);
        String body   = ApiUtil.readBody(req);
        int    viajeId= ApiUtil.jsonInt(body, "viajeId");

        try {
            Viaje v = ViajeDAO.buscarPorId(viajeId);
            if (v == null || v.getPasajeroId() != uid) {
                ApiUtil.error(res, 404, "Viaje no encontrado."); return;
            }
            String estado = v.getEstado() != null ? v.getEstado().toDb() : "";
            if ("en_camino".equals(estado) || "en_curso".equals(estado)) {
                ApiUtil.error(res, 409, "No se puede cancelar un viaje en curso."); return;
            }
            ViajeDAO.cancelar(viajeId, "pasajero");
            ApiUtil.ok(res, "\"msg\":\"Viaje cancelado correctamente.\"");
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cancelar el viaje.");
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * Lee la posición actual del operador desde la tabla usuarios.
     * La actualiza ActualizarPosicionServlet (web) y ApiOperadorServlet (app).
     */
    private double[] obtenerPosicionOperador(int operadorId) {
        if (operadorId <= 0) return null;
        String sql = "SELECT lat, lng FROM usuarios WHERE id = ? AND lat IS NOT NULL AND lng IS NOT NULL";
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, operadorId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                double lat = rs.getDouble("lat");
                double lng = rs.getDouble("lng");
                if (lat != 0 || lng != 0) return new double[]{lat, lng};
            }
        } catch (Exception ignored) {}
        return null;
    }

    /** Costo usando los valores de configuracion en BD (misma lógica que el web). */
    private double calcularCosto(double distanciaKm) {
        double base    = 35.0;
        double porKm   = 12.0;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                     "SELECT clave, valor FROM configuracion WHERE clave IN ('b2c_costo_base','b2c_costo_por_km')")) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                if ("b2c_costo_base".equals(rs.getString("clave")))
                    base = Double.parseDouble(rs.getString("valor"));
                else if ("b2c_costo_por_km".equals(rs.getString("clave")))
                    porKm = Double.parseDouble(rs.getString("valor"));
            }
        } catch (Exception ignored) {}
        return Math.round((base + distanciaKm * porKm) * 100.0) / 100.0;
    }
}
