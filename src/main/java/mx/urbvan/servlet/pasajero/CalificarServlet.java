package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;

import java.io.IOException;
import java.sql.*;

/**
 * CalificarServlet — guarda la calificación del pasajero al operador.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/CalificarServlet.java
 */
public class CalificarServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String idViajeStr   = req.getParameter("id_viaje");
        String idOperStr    = req.getParameter("id_operador");
        String puntuacionStr= req.getParameter("puntuacion");
        String comentario   = req.getParameter("comentario");

        if (idViajeStr == null || idOperStr == null || puntuacionStr == null) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
            return;
        }

        try {
            int idViaje    = Integer.parseInt(idViajeStr);
            int idOperador = Integer.parseInt(idOperStr);
            int puntuacion = Integer.parseInt(puntuacionStr);

            // Validar rango
            if (puntuacion < 1 || puntuacion > 5) {
                res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
                return;
            }

            try (Connection conn = ConexionDB.obtener()) {

                // Insertar calificación (ignorar si ya existe)
                String sqlCal = """
                    INSERT IGNORE INTO calificaciones
                        (id_viaje, id_operador, puntuacion, comentario)
                    VALUES (?, ?, ?, ?)
                    """;
                try (PreparedStatement ps = conn.prepareStatement(sqlCal)) {
                    ps.setInt(1,    idViaje);
                    ps.setInt(2,    idOperador);
                    ps.setInt(3,    puntuacion);
                    ps.setString(4, comentario != null ? comentario.trim() : null);
                    ps.executeUpdate();
                }

                // Recalcular promedio del operador
                String sqlProm = """
                    UPDATE operadores SET calificacion_prom = (
                        SELECT AVG(puntuacion) FROM calificaciones WHERE id_operador = ?
                    ) WHERE id_operador = ?
                    """;
                try (PreparedStatement ps = conn.prepareStatement(sqlProm)) {
                    ps.setInt(1, idOperador);
                    ps.setInt(2, idOperador);
                    ps.executeUpdate();
                }
            }

            res.sendRedirect(req.getContextPath() +
                "/pasajero/dashboard?viaje=calificado");

        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
        }
    }
}
