package mx.urbvan.servlet.operador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;

import java.io.IOException;
import java.sql.*;

/**
 * ResponderSolicitudServlet — el operador acepta o rechaza un viaje.
 *
 * Si acepta:
 *   - Actualiza la solicitud a ACEPTADA
 *   - Asigna el operador al viaje
 *   - Marca al operador como no disponible
 *   - Redirige a la pantalla de viaje activo
 *
 * Si rechaza:
 *   - Marca la solicitud como RECHAZADA
 *   - El viaje queda en EN_ASIGNACION para el siguiente operador
 *   - Redirige al panel
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/operador/ResponderSolicitudServlet.java
 */
public class ResponderSolicitudServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        int    idOperador  = (int) req.getSession().getAttribute("id");
        String idSolStr    = req.getParameter("id_solicitud");
        String idViajeStr  = req.getParameter("id_viaje");
        String respuesta   = req.getParameter("respuesta"); // "ACEPTAR" o "RECHAZAR"

        if (idSolStr == null || idViajeStr == null || respuesta == null) {
            res.sendRedirect(req.getContextPath() + "/operador/panel");
            return;
        }

        try {
            int idSolicitud = Integer.parseInt(idSolStr);
            int idViaje     = Integer.parseInt(idViajeStr);

            try (Connection conn = ConexionDB.obtener()) {

                if ("ACEPTAR".equals(respuesta)) {

                    // --- Aceptar el viaje ---

                    // 1. Actualizar solicitud
                    String sqlSol = """
                        UPDATE solicitudes_asignacion
                        SET estado = 'ACEPTADA', fecha_respuesta = NOW()
                        WHERE id_solicitud = ? AND id_operador = ?
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sqlSol)) {
                        ps.setInt(1, idSolicitud);
                        ps.setInt(2, idOperador);
                        ps.executeUpdate();
                    }

                    // 2. Asignar operador al viaje
                    int eta = 3 + (int)(Math.random() * 10);
                    new ViajeDAO().asignarOperador(idViaje, idOperador, eta);

                    // 3. Marcar operador como no disponible
                    String sqlOp = "UPDATE operadores SET disponible = 0 WHERE id_operador = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sqlOp)) {
                        ps.setInt(1, idOperador);
                        ps.executeUpdate();
                    }

                    // 4. Insertar posición inicial simulada del operador
                    // (se tomará la posición real cuando el operador la reporte)
                    String sqlPos = """
                        INSERT INTO posicion_operador (id_operador, latitud, longitud)
                        VALUES (?, 19.4326, -99.1332)
                        ON DUPLICATE KEY UPDATE
                            ultima_actualizacion = NOW()
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sqlPos)) {
                        ps.setInt(1, idOperador);
                        ps.executeUpdate();
                    }

                    // Redirigir al viaje activo
                    res.sendRedirect(req.getContextPath() +
                        "/operador/viaje-activo?id=" + idViaje);

                } else {

                    // --- Rechazar el viaje ---

                    // 1. Marcar solicitud como rechazada
                    String sqlSol = """
                        UPDATE solicitudes_asignacion
                        SET estado = 'RECHAZADA', fecha_respuesta = NOW()
                        WHERE id_solicitud = ? AND id_operador = ?
                        """;
                    try (PreparedStatement ps = conn.prepareStatement(sqlSol)) {
                        ps.setInt(1, idSolicitud);
                        ps.setInt(2, idOperador);
                        ps.executeUpdate();
                    }

                    // 2. Redirigir al panel con mensaje
                    res.sendRedirect(req.getContextPath() +
                        "/operador/panel?solicitud=rechazada");
                }
            }

        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/panel?error=respuesta");
        }
    }
}
