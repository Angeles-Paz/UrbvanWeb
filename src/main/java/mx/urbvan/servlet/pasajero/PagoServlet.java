package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;
import mx.urbvan.util.AsignadorOperador;

import java.io.IOException;
import java.sql.*;
import java.util.UUID;

/**
 * PagoServlet — versión corregida.
 * No asigna operador automáticamente. Solo crea el pago y
 * cambia el estado a EN_ASIGNACION. El polling se encarga del resto.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/PagoServlet.java
 */
public class PagoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        String idStr = req.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard"); return;
        }
        try {
            int idViaje   = Integer.parseInt(idStr);
            Viaje viaje   = new ViajeDAO().buscarPorId(idViaje);
            int idUsuario = (int) req.getSession().getAttribute("id");
            if (viaje == null || viaje.getIdUsuario() != idUsuario) {
                res.sendRedirect(req.getContextPath() + "/pasajero/dashboard"); return;
            }
            if (viaje.getEstado() != Viaje.Estado.SOLICITADO) {
                res.sendRedirect(req.getContextPath() + "/pasajero/estado-viaje?id=" + idViaje); return;
            }
            req.setAttribute("viaje", viaje);
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/pago.jsp").forward(req, res);
        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String idStr  = req.getParameter("id_viaje");
        String metodo = req.getParameter("metodo_pago");
        int idUsuario = (int) req.getSession().getAttribute("id");

        if (idStr == null || idStr.isBlank()) {
            res.sendRedirect(req.getContextPath() + "/pasajero/dashboard"); return;
        }

        try {
            int   idViaje = Integer.parseInt(idStr);
            Viaje viaje   = new ViajeDAO().buscarPorId(idViaje);

            if (viaje == null || viaje.getIdUsuario() != idUsuario) {
                res.sendRedirect(req.getContextPath() + "/pasajero/dashboard"); return;
            }
            if (viaje.getEstado() != Viaje.Estado.SOLICITADO) {
                res.sendRedirect(req.getContextPath() + "/pasajero/estado-viaje?id=" + idViaje); return;
            }
            if (metodo == null || (!metodo.equals("TARJETA") && !metodo.equals("EFECTIVO"))) {
                req.setAttribute("viaje", viaje);
                req.setAttribute("error", "Selecciona un método de pago.");
                req.getRequestDispatcher("/WEB-INF/vistas/pasajero/pago.jsp").forward(req, res);
                return;
            }

            try (Connection conn = ConexionDB.obtener()) {
                // 1. Registrar pago simulado
                String ref = UUID.randomUUID().toString().replace("-","").substring(0,20).toUpperCase();
                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO pagos (id_viaje, metodo_pago, monto, estado_pago, referencia_sim) VALUES (?,?,?,'APROBADO',?)")) {
                    ps.setInt(1, idViaje); ps.setString(2, metodo);
                    ps.setDouble(3, viaje.getPrecioTotal()); ps.setString(4, ref);
                    ps.executeUpdate();
                }
                // 2. Cambiar estado a EN_ASIGNACION
                try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE viajes SET estado='EN_ASIGNACION' WHERE id_viaje=?")) {
                    ps.setInt(1, idViaje); ps.executeUpdate();
                }
            }

            // 3. Primer intento de asignación (el polling reintentará si falla)
            try { AsignadorOperador.intentarAsignar(idViaje); } catch (Exception ignored) {}

            res.sendRedirect(req.getContextPath() + "/pasajero/estado-viaje?id=" + idViaje + "&pago=ok");

        } catch (Exception e) {
            req.setAttribute("error", "Error al procesar el pago: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/pago.jsp").forward(req, res);
        }
    }
}
