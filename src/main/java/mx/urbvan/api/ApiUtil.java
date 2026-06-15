package mx.urbvan.api;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.urbvan.modelo.RutaB2B;
import mx.urbvan.modelo.RutaParada;
import mx.urbvan.modelo.Vehiculo;
import mx.urbvan.modelo.Viaje;

import java.io.BufferedReader;
import java.io.IOException;

/**
 * ApiUtil – utilidades compartidas por todos los servlets de la API móvil.
 *
 * Incluye:
 *  - Lectura y parseo de JSON desde el cuerpo de la petición
 *  - Escritura de respuestas JSON (ok / error)
 *  - Serialización de los modelos del web a JSON
 *  - Cálculo de ETA (haversine simplificado)
 *  - Atributos que ApiAuthFilter deja en el request
 */
public final class ApiUtil {

    // ── Atributos de request que deja ApiAuthFilter ──────────────────────────
    public static final String ATTR_UID        = "_uid";
    public static final String ATTR_NOMBRE     = "_nombre";
    public static final String ATTR_ROL        = "_rol";
    public static final String ATTR_ES_EMPLEADO = "_esEmpleado";
    public static final String ATTR_EMPRESA_ID  = "_empresaId";

    // ── Lectura del cuerpo JSON ───────────────────────────────────────────────

    /** Lee el cuerpo de la petición como String. */
    public static String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line);
        }
        return sb.toString();
    }

    /**
     * Extrae el valor de una clave de un JSON plano (un nivel).
     * Funciona para String, número y boolean.
     * Ejemplo: jsonVal("{\"email\":\"a@b.com\"}", "email") → "a@b.com"
     */
    public static String jsonVal(String json, String key) {
        if (json == null || key == null) return null;
        String search = "\"" + key + "\"";
        int idx = json.indexOf(search);
        if (idx < 0) return null;
        idx = json.indexOf(':', idx + search.length());
        if (idx < 0) return null;
        idx++;
        // saltar espacios
        while (idx < json.length() && json.charAt(idx) == ' ') idx++;
        if (idx >= json.length()) return null;

        if (json.charAt(idx) == '"') {
            // valor String
            int start = idx + 1;
            int end   = json.indexOf('"', start);
            return end < 0 ? null : json.substring(start, end);
        } else {
            // número, boolean o null
            int start = idx;
            int end   = start;
            while (end < json.length()) {
                char c = json.charAt(end);
                if (c == ',' || c == '}' || c == ']' || c == ' ' || c == '\n') break;
                end++;
            }
            return json.substring(start, end).trim();
        }
    }

    public static int    jsonInt(String json, String key)    { try { return Integer.parseInt(jsonVal(json, key)); } catch (Exception e) { return 0; } }
    public static double jsonDouble(String json, String key) { try { return Double.parseDouble(jsonVal(json, key)); } catch (Exception e) { return 0.0; } }
    public static boolean jsonBool(String json, String key)  { return "true".equalsIgnoreCase(jsonVal(json, key)); }

    // ── Escritura de respuestas JSON ──────────────────────────────────────────

    public static void writeJson(HttpServletResponse res, int status, String json) throws IOException {
        res.setStatus(status);
        res.setContentType("application/json;charset=UTF-8");
        res.setHeader("Access-Control-Allow-Origin", "*");  // CORS para pruebas
        res.getWriter().write(json);
    }

    public static void ok(HttpServletResponse res, String body) throws IOException {
        writeJson(res, 200, "{\"ok\":true" + (body != null && !body.isEmpty() ? "," + body : "") + "}");
    }

    public static void error(HttpServletResponse res, int status, String msg) throws IOException {
        writeJson(res, status, "{\"ok\":false,\"error\":\"" + esc(msg) + "\"}");
    }

    // ── Helpers de sesión ─────────────────────────────────────────────────────

    public static int     uid(HttpServletRequest req)        { return (int)  req.getAttribute(ATTR_UID); }
    public static String  rol(HttpServletRequest req)        { return (String) req.getAttribute(ATTR_ROL); }
    public static boolean esEmpleado(HttpServletRequest req) { return Boolean.TRUE.equals(req.getAttribute(ATTR_ES_EMPLEADO)); }
    public static int     empresaId(HttpServletRequest req)  { Object v = req.getAttribute(ATTR_EMPRESA_ID); return v != null ? (int) v : -1; }

    // ── Serialización de modelos a JSON ───────────────────────────────────────

    public static String viajeJson(Viaje v) {
        if (v == null) return "null";
        // Calcular ETA aproximado si el operador tiene posición
        int eta = v.getDuracionMin();

        return "{" +
            "\"id\":"               + v.getId()                                       + "," +
            "\"estado\":\""         + esc(v.getEstado() != null ? v.getEstado().toDb() : "") + "\"," +
            "\"origenNombre\":\""   + esc(v.getOrigenNombre())                        + "\"," +
            "\"destinoNombre\":\""  + esc(v.getDestinoNombre())                       + "\"," +
            "\"origenLat\":"        + v.getOrigenLat()                                + "," +
            "\"origenLng\":"        + v.getOrigenLng()                                + "," +
            "\"destinoLat\":"       + v.getDestinoLat()                               + "," +
            "\"destinoLng\":"       + v.getDestinoLng()                               + "," +
            "\"distanciaKm\":"      + v.getDistanciaKm()                              + "," +
            "\"duracionMin\":"      + v.getDuracionMin()                              + "," +
            "\"costo\":"            + v.getCosto()                                    + "," +
            "\"metodoPago\":\""     + esc(v.getMetodoPago())                          + "\"," +
            "\"operadorNombre\":\""  + esc(v.getOperadorNombre())                     + "\"," +
            "\"operadorScore\":"    + v.getOperadorScore()                            + "," +
            "\"vehiculoModelo\":\""  + esc(v.getVehiculoModelo())                     + "\"," +
            "\"vehiculoPlaca\":\""   + esc(v.getVehiculoPlaca())                      + "\"," +
            "\"calificacionDada\":" + v.getCalificacionDada()                         + "," +
            "\"etaMinutos\":"       + eta                                             + "," +
            "\"createdAt\":\""      + (v.getCreatedAt() != null ? v.getCreatedAt().toString() : "") + "\"" +
        "}";
    }

    /** Versión enriquecida con posición actual del operador (para polling de estado). */
    public static String viajeJson(Viaje v, double opLat, double opLng) {
        if (v == null) return "null";
        // Calcular ETA usando posición real del operador
        int eta = calcularEta(v, opLat, opLng);
        String base = viajeJson(v);
        // Insertar campos de posición antes del cierre }
        return base.substring(0, base.length() - 1) +
            ",\"operadorLat\":"  + opLat  +
            ",\"operadorLng\":"  + opLng  +
            ",\"etaMinutos\":"   + eta    +
        "}";
    }

    public static String vehiculoJson(Vehiculo v) {
        return "{" +
            "\"id\":"        + v.getId()               + "," +
            "\"modelo\":\"" + esc(v.getModelo())       + "\"," +
            "\"capacidad\":" + v.getCapacidad()        + "," +
            "\"placa\":\""  + esc(v.getPlaca())        + "\"," +
            "\"color\":\""  + esc(v.getColor())        + "\"" +
        "}";
    }

    public static String rutaB2BJson(RutaB2B r) {
        return rutaB2BJson(r, -1);
    }

    public static String rutaB2BJson(RutaB2B r, int numeroAsiento) {
        if (r == null) return "null";

        StringBuilder paradasArr = new StringBuilder("[");
        if (r.getParadas() != null) {
            boolean first = true;
            for (RutaParada p : r.getParadas()) {
                if (!first) paradasArr.append(",");
                first = false;
                paradasArr.append(paradaJson(p));
            }
        }
        paradasArr.append("]");

        return "{" +
            "\"id\":"                  + r.getId()                                                               + "," +
            "\"estado\":\""            + esc(r.getEstadoTexto())                                                 + "\"," +
            "\"fechaInicio\":\""       + (r.getFechaInicio() != null ? r.getFechaInicio().toString() : "")       + "\"," +
            "\"fechaFinEst\":\""       + (r.getFechaFinEst() != null ? r.getFechaFinEst().toString() : "")       + "\"," +
            "\"kmTotales\":"           + r.getKmTotales()                                                        + "," +
            "\"costoTotal\":"          + r.getCostoTotal()                                                       + "," +
            "\"empresaId\":"           + r.getEmpresaId()                                                        + "," +
            "\"empresaNombre\":\""     + esc(r.getEmpresaNombre())                                               + "\"," +
            "\"empresaScore\":"        + r.getEmpresaScore()                                                     + "," +
            "\"vehiculoModelo\":\""    + esc(r.getVehiculoModelo())                                              + "\"," +
            "\"vehiculoPlaca\":\""     + esc(r.getVehiculoPlaca())                                               + "\"," +
            "\"vehiculoCapacidad\":"   + r.getVehiculoCapacidad()                                                + "," +
            "\"operadorId\":"          + r.getOperadorId()                                                       + "," +
            "\"operadorNombre\":\""    + esc(r.getOperadorNombre())                                              + "\"," +
            "\"operadorScore\":"       + r.getOperadorScore()                                                    + "," +
            "\"operadorLat\":"         + (r.getOperadorLat()  != null ? r.getOperadorLat()  : 0.0)              + "," +
            "\"operadorLng\":"         + (r.getOperadorLng()  != null ? r.getOperadorLng()  : 0.0)              + "," +
            "\"numeroAsiento\":"       + numeroAsiento                                                           + "," +
            "\"asientosOcupados\":"    + r.getAsientosOcupados()                                                 + "," +
            "\"paradas\":"             + paradasArr                                                              +
        "}";
    }

    public static String paradaJson(RutaParada p) {
        if (p == null) return "null";
        return "{" +
            "\"id\":"              + p.getId()                                                                    + "," +
            "\"orden\":"           + p.getOrden()                                                                 + "," +
            "\"tipo\":\""          + esc(p.getTipo() != null ? p.getTipo().toDb() : "")                          + "\"," +
            "\"latitud\":"         + p.getLatitud()                                                              + "," +
            "\"longitud\":"        + p.getLongitud()                                                             + "," +
            "\"nombreLugar\":\""   + esc(p.getNombreLugar())                                                     + "\"," +
            "\"tiempoEstancia\":"  + p.getTiempoEstancia()                                                       + "," +
            "\"horaEstimada\":\""  + (p.getHoraEstimada() != null ? p.getHoraEstimada().toString() : "")        + "\"" +
        "}";
    }

    // ── ETA simplificado (Haversine) ──────────────────────────────────────────

    /**
     * Calcula ETA aproximado en minutos usando la posición actual del operador.
     * Velocidad promedio urbana asumida: 30 km/h (0.5 km/min).
     */
    public static int calcularEta(Viaje v, double opLat, double opLng) {
        if (opLat == 0 || opLng == 0) return v.getDuracionMin();
        String estado = v.getEstado() != null ? v.getEstado().toDb() : "";
        double targetLat, targetLng;
        if ("asignado".equals(estado) || "aceptado".equals(estado)) {
            targetLat = v.getOrigenLat();
            targetLng = v.getOrigenLng();
        } else {
            targetLat = v.getDestinoLat();
            targetLng = v.getDestinoLng();
        }
        double distKm = haversineKm(opLat, opLng, targetLat, targetLng);
        int eta = (int) Math.ceil(distKm / 0.5); // 30 km/h
        return Math.max(1, eta);
    }

    public static double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat/2) * Math.sin(dLat/2)
                 + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                 * Math.sin(dLng/2) * Math.sin(dLng/2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    // ── JSON escape ───────────────────────────────────────────────────────────

    public static String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", " ")
                .replace("\r", "");
    }

    private ApiUtil() {}
}
