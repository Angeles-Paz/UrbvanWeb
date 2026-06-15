package mx.urbvan.servlet.pasajero;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ViajeDAO;
import java.io.IOException;

/**
 * ModificarViajeServlet - limpia la solicitud pendiente antes de regresar
 * a la pantalla de solicitar viaje. Evita que el botón "Modificar ruta"
 * deje un viaje en estado buscando operador.
 */
@WebServlet("/pasajero/modificar-viaje")
public class ModificarViajeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession sesion = req.getSession(false);
        if (sesion != null) {
            Integer viajeId = (Integer) sesion.getAttribute("viajeIdPendiente");
            Object uidObj = sesion.getAttribute("id");
            if (viajeId != null && uidObj instanceof Integer) {
                try {
                    ViajeDAO.eliminarSiPendiente(viajeId, (Integer) uidObj);
                } catch (Exception ignored) {
                    // Si no se puede eliminar, por seguridad al menos se limpia la sesión.
                }
            }
            sesion.removeAttribute("viajeIdPendiente");
            sesion.removeAttribute("viajeActivoId");
        }
        res.sendRedirect(req.getContextPath() + "/pasajero/solicitar");
    }
}
