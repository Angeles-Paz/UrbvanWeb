package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * PanelOperadorServlet - panel principal del operador con polling.
 * CAMBIOS vs v1: consulta solicitudes_operador (tabla nueva) en lugar de
 * buscar directamente en viajes. El operador ve las solicitudes pendientes
 * asignadas a él, no todos los viajes en estado 'solicitado'.
 */
@WebServlet("/operador/panel")
public class PanelOperadorServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            // Si tiene viaje activo, redirigir a viaje-activo
            Viaje activo = ViajeDAO.buscarActivoOperador(uid);
            if (activo != null) {
                req.setAttribute("viaje", activo);
                req.getRequestDispatcher("/WEB-INF/vistas/operador/viaje-activo.jsp").forward(req, res);
                return;
            }
            // Solicitudes pendientes asignadas a este operador
            req.setAttribute("solicitudes", buscarSolicitudesPendientes(uid));
            req.getRequestDispatcher("/WEB-INF/vistas/operador/panel.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar el panel.");
            req.getRequestDispatcher("/WEB-INF/vistas/operador/panel.jsp").forward(req, res);
        }
    }

    /** Devuelve los viajes cuya solicitud está pendiente para este operador. */
    private List<Viaje> buscarSolicitudesPendientes(int operadorId) throws Exception {
        String sql = """
            SELECT v.id, v.pasajero_id, v.operador_id, v.vehiculo_id,
                   v.origen_lat, v.origen_lng, v.origen_nombre,
                   v.destino_lat, v.destino_lng, v.destino_nombre,
                   v.distancia_km, v.duracion_min, v.costo, v.estado,
                   v.metodo_pago, v.cancelado_por, v.created_at, v.updated_at,
                   p.nombre AS pasajero_nombre,
                   NULL AS operador_nombre, 0.0 AS operador_score,
                   NULL AS vehiculo_modelo, NULL AS vehiculo_placa,
                   NULL AS calificacion_dada
            FROM   solicitudes_operador s
            JOIN   viajes v    ON s.viaje_id    = v.id
            JOIN   usuarios p  ON v.pasajero_id = p.id
            WHERE  s.operador_id = ?
              AND  s.estado      = 'pendiente'
              AND  v.estado      = 'asignado'
            ORDER BY s.created_at ASC
            """;
        List<Viaje> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, operadorId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Viaje v = new Viaje();
                v.setId(rs.getInt("id"));
                v.setPasajeroId(rs.getInt("pasajero_id"));
                v.setOrigenLat(rs.getDouble("origen_lat"));
                v.setOrigenLng(rs.getDouble("origen_lng"));
                v.setOrigenNombre(rs.getString("origen_nombre"));
                v.setDestinoLat(rs.getDouble("destino_lat"));
                v.setDestinoLng(rs.getDouble("destino_lng"));
                v.setDestinoNombre(rs.getString("destino_nombre"));
                v.setDistanciaKm(rs.getDouble("distancia_km"));
                v.setCosto(rs.getDouble("costo"));
                v.setEstado(Viaje.Estado.fromDb(rs.getString("estado")));
                v.setPasajeroNombre(rs.getString("pasajero_nombre"));
                lista.add(v);
            }
        }
        return lista;
    }
}
