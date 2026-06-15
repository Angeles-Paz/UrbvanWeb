package mx.urbvan.servlet.b2b;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import mx.urbvan.modelo.RutaB2BEvento;
import java.io.IOException;
import java.util.List;

/** Endpoint JSON para consultar posición del operador y eventos de ruta B2B en vivo. */
@WebServlet("/b2b/ruta/tracking-data")
public class TrackingRutaB2BServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        res.setContentType("application/json;charset=UTF-8");
        try {
            int rutaId = Integer.parseInt(req.getParameter("rutaId"));
            RutaB2B ruta = RutaB2BDAO.buscarPorId(rutaId);
            if (ruta == null) {
                res.setStatus(HttpServletResponse.SC_NOT_FOUND);
                res.getWriter().write("{\"error\":\"Ruta no encontrada\"}");
                return;
            }

            List<RutaB2BEvento> eventos = RutaB2BDAO.listarEventos(rutaId);
            RutaB2BEvento ultimo = eventos.isEmpty() ? null : eventos.get(eventos.size() - 1);
            StringBuilder json = new StringBuilder();
            json.append("{");
            json.append("\"rutaId\":").append(ruta.getId()).append(',');
            json.append("\"estado\":\"").append(escape(ruta.getEstadoTexto())).append("\",");
            json.append("\"operador\":{");
            json.append("\"nombre\":\"").append(escape(ruta.getOperadorNombre())).append("\",");
            json.append("\"lat\":").append(ruta.getOperadorLat() == null ? "null" : ruta.getOperadorLat()).append(',');
            json.append("\"lng\":").append(ruta.getOperadorLng() == null ? "null" : ruta.getOperadorLng());
            json.append("},");
            json.append("\"ultimoEvento\":");
            if (ultimo == null) {
                json.append("null");
            } else {
                json.append("{")
                    .append("\"tipo\":\"").append(escape(ultimo.getTipoTexto())).append("\",")
                    .append("\"parada\":\"").append(escape(ultimo.getParadaNombre())).append("\",")
                    .append("\"fecha\":\"").append(ultimo.getCreadoEn() == null ? "" : escape(ultimo.getCreadoEn().toString())).append("\"")
                    .append("}");
            }
            json.append(',');
            json.append("\"eventos\":[");
            for (int i = 0; i < eventos.size(); i++) {
                RutaB2BEvento ev = eventos.get(i);
                if (i > 0) json.append(',');
                json.append("{")
                    .append("\"tipo\":\"").append(escape(ev.getTipoTexto())).append("\",")
                    .append("\"parada\":\"").append(escape(ev.getParadaNombre())).append("\",")
                    .append("\"fecha\":\"").append(ev.getCreadoEn() == null ? "" : escape(ev.getCreadoEn().toString())).append("\"")
                    .append("}");
            }
            json.append("]}");
            res.getWriter().write(json.toString());
        } catch (Exception e) {
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write("{\"error\":\"No se pudo cargar tracking B2B\"}");
        }
    }

    private String escape(String txt) {
        if (txt == null) return "";
        return txt.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", " ");
    }
}
