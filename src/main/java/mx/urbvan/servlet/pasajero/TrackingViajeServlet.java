package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/** Endpoint JSON para refrescar la ubicación del operador en el viaje B2C del pasajero. */
@WebServlet("/pasajero/tracking-data")
public class TrackingViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        res.setContentType("application/json;charset=UTF-8");
        int pasajeroId = (int) req.getSession().getAttribute("id");
        try {
            Viaje v = ViajeDAO.buscarActivoPasajero(pasajeroId);
            if (v == null) {
                res.getWriter().write("{\"activo\":false}");
                return;
            }
            res.getWriter().write("{"
                    + "\"activo\":true,"
                    + "\"viajeId\":" + v.getId() + ","
                    + "\"estado\":\"" + escape(v.getEstado().etiqueta()) + "\","
                    + "\"operadorId\":" + v.getOperadorId() + ","
                    + "\"operadorNombre\":\"" + escape(v.getOperadorNombre()) + "\","
                    + "\"lat\":" + obtenerLatOperador(v.getOperadorId()) + ","
                    + "\"lng\":" + obtenerLngOperador(v.getOperadorId())
                    + "}");
        } catch (Exception e) {
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            res.getWriter().write("{\"error\":\"No se pudo cargar tracking\"}");
        }
    }

    private String obtenerLatOperador(int operadorId) throws Exception {
        if (operadorId <= 0) return "null";
        try (java.sql.Connection c = mx.urbvan.dao.ConexionDB.obtener();
             java.sql.PreparedStatement ps = c.prepareStatement("SELECT lat FROM usuarios WHERE id=?")) {
            ps.setInt(1, operadorId);
            java.sql.ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                double v = rs.getDouble("lat");
                return rs.wasNull() ? "null" : String.valueOf(v);
            }
            return "null";
        }
    }

    private String obtenerLngOperador(int operadorId) throws Exception {
        if (operadorId <= 0) return "null";
        try (java.sql.Connection c = mx.urbvan.dao.ConexionDB.obtener();
             java.sql.PreparedStatement ps = c.prepareStatement("SELECT lng FROM usuarios WHERE id=?")) {
            ps.setInt(1, operadorId);
            java.sql.ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                double v = rs.getDouble("lng");
                return rs.wasNull() ? "null" : String.valueOf(v);
            }
            return "null";
        }
    }

    private String escape(String txt) {
        if (txt == null) return "";
        return txt.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
