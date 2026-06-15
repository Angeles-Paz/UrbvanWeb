package mx.urbvan.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import mx.urbvan.modelo.RutaAsiento;
import mx.urbvan.modelo.RutaB2BEvento;

import java.io.IOException;
import java.util.List;

/**
 * ApiB2BServlet – endpoints B2B para empleado y operador en la app móvil.
 *
 * URL base: /api/b2b/*
 *
 * GET /api/b2b/rutas?rol=empleado|operador  → rutas activas/pendientes
 * GET /api/b2b/ruta?id=<rutaId>             → detalle completo de una ruta (con paradas)
 * GET /api/b2b/tracking?rutaId=<id>         → polling: posición operador + último evento
 * GET /api/b2b/historial?rol=              → rutas completadas y canceladas
 *
 * Para empleado: devuelve su número de asiento en cada ruta.
 * Para operador: devuelve la lista de empleados con asiento asignado.
 *
 * El rol se infiere del token (sesión) y se confirma opcionalmente con el query param.
 */
@WebServlet("/api/b2b/*")
public class ApiB2BServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String path = req.getPathInfo();
        if (path == null) path = "/";
        switch (path) {
            case "/rutas"     -> getRutas(req, res, false);
            case "/ruta"      -> getDetalleRuta(req, res);
            case "/tracking"  -> getTracking(req, res);
            case "/historial" -> getRutas(req, res, true);
            default -> ApiUtil.error(res, 404, "Endpoint no encontrado: " + path);
        }
    }

    /**
     * GET /api/b2b/rutas?rol=empleado|operador
     * GET /api/b2b/historial?rol=empleado|operador
     *
     * @param soloHistorial true → devuelve completadas/canceladas; false → activas/pendientes
     */
    private void getRutas(HttpServletRequest req, HttpServletResponse res, boolean soloHistorial)
            throws IOException {
        int    uid = ApiUtil.uid(req);
        String rol = ApiUtil.rol(req); // del token: "pasajero" (empleado), "operador", "admin_empresa"

        try {
            List<RutaB2B> lista;
            boolean esEmpleado = ApiUtil.esEmpleado(req) || "pasajero".equals(rol);
            boolean esOperador = "operador".equals(rol);

            if (esEmpleado || "admin_empresa".equals(rol)) {
                lista = RutaB2BDAO.listarDeEmpleado(uid);
            } else if (esOperador) {
                lista = RutaB2BDAO.listarDeOperador(uid);
            } else {
                ApiUtil.error(res, 403, "Rol no autorizado para B2B."); return;
            }

            // Filtrar por activas/pendientes o por historial
            StringBuilder json = new StringBuilder("[");
            boolean first = true;
            for (RutaB2B r : lista) {
                String estado = r.getEstadoTexto();
                boolean esHistorial = "completada".equals(estado) || "cancelada".equals(estado);
                if (soloHistorial != esHistorial) continue;

                if (!first) json.append(",");
                first = false;

                // Buscar número de asiento del empleado (si aplica)
                int numAsiento = -1;
                if (esEmpleado) {
                    numAsiento = obtenerAsientoEmpleado(r, uid);
                }
                json.append(ApiUtil.rutaB2BJson(r, numAsiento));
            }
            json.append("]");
            ApiUtil.ok(res, "\"rutas\":" + json);

        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cargar rutas B2B: " + e.getMessage());
        }
    }

    /**
     * GET /api/b2b/ruta?id=<rutaId>
     * Devuelve detalle completo: paradas + asientos + eventos recientes.
     */
    private void getDetalleRuta(HttpServletRequest req, HttpServletResponse res) throws IOException {
        int uid = ApiUtil.uid(req);
        String ids = req.getParameter("id");
        if (ids == null || ids.isBlank()) { ApiUtil.error(res, 400, "'id' requerido."); return; }
        int rutaId;
        try { rutaId = Integer.parseInt(ids); } catch (NumberFormatException e) {
            ApiUtil.error(res, 400, "id inválido."); return;
        }

        try {
            RutaB2B ruta = RutaB2BDAO.buscarPorId(rutaId);
            if (ruta == null) { ApiUtil.error(res, 404, "Ruta no encontrada."); return; }

            boolean esEmpleado = ApiUtil.esEmpleado(req) || "pasajero".equals(ApiUtil.rol(req));
            int numAsiento = esEmpleado ? obtenerAsientoEmpleado(ruta, uid) : -1;

            ApiUtil.ok(res, "\"ruta\":" + ApiUtil.rutaB2BJson(ruta, numAsiento));
        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al cargar detalle de ruta.");
        }
    }

    /**
     * GET /api/b2b/tracking?rutaId=<id>
     * POLLING – equivalente a TrackingRutaB2BServlet pero en formato ApiResponse estandarizado.
     * La app llama esto cada 5 segundos para actualizar posición del operador en el mapa.
     */
    private void getTracking(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String ids = req.getParameter("rutaId");
        if (ids == null || ids.isBlank()) { ApiUtil.error(res, 400, "'rutaId' requerido."); return; }
        int rutaId;
        try { rutaId = Integer.parseInt(ids); } catch (NumberFormatException e) {
            ApiUtil.error(res, 400, "rutaId inválido."); return;
        }

        try {
            RutaB2B ruta = RutaB2BDAO.buscarPorId(rutaId);
            if (ruta == null) { ApiUtil.error(res, 404, "Ruta no encontrada."); return; }

            List<RutaB2BEvento> eventos = RutaB2BDAO.listarEventos(rutaId);
            RutaB2BEvento ultimo = eventos.isEmpty() ? null : eventos.get(eventos.size() - 1);

            StringBuilder json = new StringBuilder();
            json.append("\"rutaId\":").append(ruta.getId()).append(",");
            json.append("\"estado\":\"").append(ApiUtil.esc(ruta.getEstadoTexto())).append("\",");
            json.append("\"operadorNombre\":\"").append(ApiUtil.esc(ruta.getOperadorNombre())).append("\",");
            json.append("\"operadorLat\":").append(ruta.getOperadorLat() != null ? ruta.getOperadorLat() : 0.0).append(",");
            json.append("\"operadorLng\":").append(ruta.getOperadorLng() != null ? ruta.getOperadorLng() : 0.0).append(",");

            if (ultimo != null) {
                json.append("\"ultimoTipoEvento\":\"").append(ApiUtil.esc(ultimo.getTipoTexto())).append("\",");
                json.append("\"ultimaParadaNombre\":\"").append(ApiUtil.esc(ultimo.getParadaNombre())).append("\",");
                json.append("\"ultimaFechaEvento\":\"").append(
                        ultimo.getCreadoEn() != null ? ApiUtil.esc(ultimo.getCreadoEn().toString()) : "").append("\"");
            } else {
                json.append("\"ultimoTipoEvento\":null,");
                json.append("\"ultimaParadaNombre\":null,");
                json.append("\"ultimaFechaEvento\":null");
            }

            ApiUtil.ok(res, json.toString());

        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error al obtener tracking B2B.");
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    /** Encuentra el número de asiento asignado al empleado en la ruta. Devuelve -1 si no tiene. */
    private int obtenerAsientoEmpleado(RutaB2B ruta, int empleadoId) {
        if (ruta.getAsientos() == null) return -1;
        for (RutaAsiento asiento : ruta.getAsientos()) {
            if (asiento.isActivo() && asiento.getEmpleadoId() == empleadoId) {
                return asiento.getNumeroAsiento();
            }
        }
        return -1;
    }
}
