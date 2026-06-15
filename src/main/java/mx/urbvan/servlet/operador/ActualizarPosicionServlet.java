package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import java.io.IOException;
import java.sql.*;

/**
 * ActualizarPosicionServlet - actualiza la posición GPS del operador.
 * CAMBIOS vs v1: ahora actualiza la tabla 'usuarios' (antes 'operadores' separada).
 * Llamado por seguimiento.js cada N segundos usando fetch/XHR.
 */
@WebServlet("/operador/actualizar-posicion")
public class ActualizarPosicionServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            double lat = Double.parseDouble(req.getParameter("lat"));
            double lng = Double.parseDouble(req.getParameter("lng"));

            // Actualiza en tabla unificada 'usuarios' (v1 actualizaba tabla 'operadores')
            String sql = "UPDATE usuarios SET lat=?, lng=?, updated_at=NOW() WHERE id=?";
            try (Connection c = ConexionDB.obtener();
                 PreparedStatement ps = c.prepareStatement(sql)) {
                ps.setDouble(1, lat);
                ps.setDouble(2, lng);
                ps.setInt(3, uid);
                ps.executeUpdate();
            }
            res.setStatus(HttpServletResponse.SC_OK);
        } catch (Exception e) {
            res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        }
    }
}
