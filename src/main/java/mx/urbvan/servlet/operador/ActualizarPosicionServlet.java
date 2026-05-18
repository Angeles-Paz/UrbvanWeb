package mx.urbvan.servlet.operador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * ActualizarPosicionServlet — recibe la posición GPS del operador
 * y la guarda en posicion_operador usando UPSERT.
 *
 * El JavaScript del operador llama a este endpoint cada 5 segundos.
 * El pasajero lo lee mediante EstadoViajeServlet (polling).
 *
 * Responde JSON: {"ok":true} o {"ok":false,"error":"..."}
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/operador/ActualizarPosicionServlet.java
 */
public class ActualizarPosicionServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        int    idOperador = (int) req.getSession().getAttribute("id");
        String latStr     = req.getParameter("lat");
        String lngStr     = req.getParameter("lng");

        if (latStr == null || lngStr == null) {
            out.print("{\"ok\":false,\"error\":\"Coordenadas faltantes\"}");
            return;
        }

        try {
            double lat = Double.parseDouble(latStr);
            double lng = Double.parseDouble(lngStr);

            String sql = """
                INSERT INTO posicion_operador (id_operador, latitud, longitud)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    latitud  = VALUES(latitud),
                    longitud = VALUES(longitud),
                    ultima_actualizacion = NOW()
                """;

            try (Connection conn = ConexionDB.obtener();
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1,    idOperador);
                ps.setDouble(2, lat);
                ps.setDouble(3, lng);
                ps.executeUpdate();
            }

            out.print("{\"ok\":true}");

        } catch (Exception e) {
            out.print("{\"ok\":false,\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}
