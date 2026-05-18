package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;

/**
 * SolicitarViajeServlet
 *
 * GET  → muestra el mapa para seleccionar origen y destino
 * POST → valida coordenadas, calcula precio, crea el viaje y
 *        redirige a la pantalla de pago
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/pasajero/SolicitarViajeServlet.java
 */
public class SolicitarViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int idUsuario = (int) req.getSession().getAttribute("id");

        // Si ya tiene un viaje activo, redirigir al seguimiento
        try {
            Viaje activo = new ViajeDAO().buscarActivoPorUsuario(idUsuario);
            if (activo != null) {
                res.sendRedirect(req.getContextPath() + "/pasajero/estado-viaje?id=" + activo.getIdViaje());
                return;
            }
        } catch (Exception e) {
            // Si falla la consulta, mostramos el mapa de todas formas
        }

        req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar-viaje.jsp")
           .forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        // --- Leer parámetros del formulario enviado por el mapa ---
        String origenLatStr  = req.getParameter("origen_lat");
        String origenLngStr  = req.getParameter("origen_lng");
        String origenDir     = req.getParameter("origen_direccion");
        String destinoLatStr = req.getParameter("destino_lat");
        String destinoLngStr = req.getParameter("destino_lng");
        String destinoDir    = req.getParameter("destino_direccion");
        String distanciaStr  = req.getParameter("distancia_km");
        String etaStr        = req.getParameter("eta_min");

        // --- Validar que llegaron todos los datos ---
        if (esVacio(origenLatStr) || esVacio(destinoLatStr) || esVacio(distanciaStr)) {
            req.setAttribute("error", "Selecciona un origen y destino válidos en el mapa.");
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar-viaje.jsp")
               .forward(req, res);
            return;
        }

        try {
            double origenLat  = Double.parseDouble(origenLatStr);
            double origenLng  = Double.parseDouble(origenLngStr);
            double destinoLat = Double.parseDouble(destinoLatStr);
            double destinoLng = Double.parseDouble(destinoLngStr);
            double distanciaKm = Double.parseDouble(distanciaStr);
            int    etaMin      = etaStr != null ? Integer.parseInt(etaStr) : 0;

            // --- Calcular precio usando la tarifa activa ---
            double precio = calcularPrecio(distanciaKm);

            // --- Crear el objeto Viaje ---
            Viaje viaje = new Viaje();
            viaje.setIdUsuario((int) req.getSession().getAttribute("id"));
            viaje.setOrigenLat(origenLat);
            viaje.setOrigenLng(origenLng);
            viaje.setOrigenDireccion(origenDir);
            viaje.setDestinoLat(destinoLat);
            viaje.setDestinoLng(destinoLng);
            viaje.setDestinoDireccion(destinoDir);
            viaje.setDistanciaKm(distanciaKm);
            viaje.setPrecioTotal(precio);
            viaje.setEtaViajeMin(etaMin);

            // --- Insertar en BD ---
            int idViaje = new ViajeDAO().insertar(viaje);

            // --- Guardar ID en sesión para usarlo en el pago ---
            req.getSession().setAttribute("id_viaje_pendiente", idViaje);

            // --- Ir a la pantalla de pago ---
            res.sendRedirect(req.getContextPath() + "/pasajero/pago?id=" + idViaje);

        } catch (Exception e) {
            req.setAttribute("error", "Error al procesar la solicitud: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar-viaje.jsp")
               .forward(req, res);
        }
    }

    /**
     * Calcula el precio del viaje consultando la tarifa activa en la BD.
     * Fórmula: tarifa_base + (distancia_km × costo_por_km) + cargo_servicio
     */
    private double calcularPrecio(double distanciaKm) throws Exception {
        String sql = "SELECT tarifa_base, costo_por_km, cargo_servicio " +
                     "FROM tarifas WHERE activa = 1 ORDER BY fecha_vigencia DESC LIMIT 1";
        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                double base    = rs.getDouble("tarifa_base");
                double porKm   = rs.getDouble("costo_por_km");
                double cargo   = rs.getDouble("cargo_servicio");
                double total   = base + (distanciaKm * porKm) + cargo;
                // Redondear a 2 decimales
                return Math.round(total * 100.0) / 100.0;
            }
            // Si no hay tarifa configurada, usar valores por defecto
            return Math.round((15.0 + distanciaKm * 8.5 + 3.0) * 100.0) / 100.0;
        }
    }

    private boolean esVacio(String v) {
        return v == null || v.isBlank();
    }
}
