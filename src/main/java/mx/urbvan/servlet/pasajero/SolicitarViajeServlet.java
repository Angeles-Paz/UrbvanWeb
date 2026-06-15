package mx.urbvan.servlet.pasajero;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.dao.VehiculoDAO;
import mx.urbvan.modelo.Viaje;
import java.io.IOException;

/**
 * SolicitarViajeServlet - crea el viaje en BD y redirige a pago.
 * CAMBIOS vs v1: usa nuevos nombres de campo del modelo Viaje.
 */
@WebServlet("/pasajero/solicitar")
public class SolicitarViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        // Mostrar mapa de solicitud - verificar que no haya viaje activo
        try {
            int uid = (int) req.getSession().getAttribute("id");
            Viaje activo = ViajeDAO.buscarActivoPasajero(uid);
            if (activo != null) {
                req.setAttribute("viaje", activo);
                req.getRequestDispatcher("/WEB-INF/vistas/pasajero/estado.jsp").forward(req, res);
                return;
            }
        } catch (Exception ignored) {}
        try {
            req.setAttribute("vehiculosB2C", VehiculoDAO.listarB2CDisponibles());
        } catch (Exception e) {
            req.setAttribute("error", "No se pudieron cargar las unidades disponibles.");
        }
        req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        try {
            int    uid          = (int) req.getSession().getAttribute("id");
            double origenLat    = Double.parseDouble(req.getParameter("origenLat"));
            double origenLng    = Double.parseDouble(req.getParameter("origenLng"));
            String origenNombre = req.getParameter("origenNombre");
            double destinoLat   = Double.parseDouble(req.getParameter("destinoLat"));
            double destinoLng   = Double.parseDouble(req.getParameter("destinoLng"));
            String destinoNombre= req.getParameter("destinoNombre");
            double distanciaKm  = Double.parseDouble(req.getParameter("distanciaKm"));
            int    duracionMin  = Integer.parseInt(req.getParameter("duracionMin"));
            int    vehiculoId   = Integer.parseInt(req.getParameter("vehiculoId"));

            if (vehiculoId <= 0) {
                req.setAttribute("error", "Selecciona una unidad disponible para continuar.");
                req.setAttribute("vehiculosB2C", VehiculoDAO.listarB2CDisponibles());
                req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar.jsp").forward(req, res);
                return;
            }

            // Calcular costo con valores de configuracion (leídos del parámetro pasado por JS)
            double costoBase   = Double.parseDouble(req.getParameter("costoBase"));
            double costoPorKm  = Double.parseDouble(req.getParameter("costoPorKm"));
            double costo       = costoBase + (distanciaKm * costoPorKm);

            Viaje v = new Viaje();
            v.setPasajeroId(uid);
            v.setVehiculoId(vehiculoId);
            v.setOrigenLat(origenLat);   v.setOrigenLng(origenLng);
            v.setOrigenNombre(origenNombre);
            v.setDestinoLat(destinoLat); v.setDestinoLng(destinoLng);
            v.setDestinoNombre(destinoNombre);
            v.setDistanciaKm(distanciaKm);
            v.setDuracionMin(duracionMin);
            v.setCosto(costo);
            v.setMetodoPago(req.getParameter("metodoPago") != null
                            ? req.getParameter("metodoPago") : "efectivo");

            int viajeId = ViajeDAO.insertar(v);
            req.getSession().setAttribute("viajeIdPendiente", viajeId);
            res.sendRedirect(req.getContextPath() + "/pasajero/pago");
        } catch (Exception e) {
            req.setAttribute("error", "Error al crear el viaje: " + e.getMessage());
            try { req.setAttribute("vehiculosB2C", VehiculoDAO.listarB2CDisponibles()); } catch (Exception ignored) {}
            req.getRequestDispatcher("/WEB-INF/vistas/pasajero/solicitar.jsp").forward(req, res);
        }
    }
}
