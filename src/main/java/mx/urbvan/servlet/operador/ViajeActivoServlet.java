package mx.urbvan.servlet.operador;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.ViajeDAO;
import mx.urbvan.modelo.Viaje;

import java.io.IOException;
import java.sql.*;

/**
 * ViajeActivoServlet — sirve la pantalla del operador durante un viaje activo.
 *
 * GET /operador/viaje-activo?id={idViaje}
 *
 * Carga el viaje, los datos del pasajero y los expone al JSP.
 * Si el operador no tiene un viaje activo, redirige al panel.
 *
 * Ubicación: src/main/java/mx/urbvan/servlet/operador/ViajeActivoServlet.java
 */
public class ViajeActivoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        int idOperador = (int) req.getSession().getAttribute("id");
        String idStr   = req.getParameter("id");

        try {
            Viaje viaje = null;

            // Si viene ID explícito usarlo, si no buscar el viaje activo del operador
            if (idStr != null && !idStr.isBlank()) {
                viaje = new ViajeDAO().buscarPorId(Integer.parseInt(idStr));
                // Verificar que el viaje pertenece a este operador
                if (viaje != null && viaje.getIdOperador() != idOperador) {
                    viaje = null;
                }
            } else {
                viaje = new ViajeDAO().buscarActivoPorOperador(idOperador);
            }

            if (viaje == null || viaje.getEstado() == Viaje.Estado.COMPLETADO
                              || viaje.getEstado() == Viaje.Estado.CANCELADO) {
                res.sendRedirect(req.getContextPath() + "/operador/panel");
                return;
            }

            // Cargar datos del pasajero
            String pasajeroNombre = "—", pasajeroTel = "—";
            try (Connection conn = ConexionDB.obtener();
                 PreparedStatement ps = conn.prepareStatement(
                     "SELECT CONCAT(nombre,' ',apellido) AS nombre, telefono " +
                     "FROM usuarios WHERE id_usuario = ?")) {
                ps.setInt(1, viaje.getIdUsuario());
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    pasajeroNombre = rs.getString("nombre");
                    pasajeroTel    = rs.getString("telefono") != null
                                     ? rs.getString("telefono") : "—";
                }
            }

            req.setAttribute("viaje",           viaje);
            req.setAttribute("pasajero_nombre", pasajeroNombre);
            req.setAttribute("pasajero_tel",    pasajeroTel);

            req.getRequestDispatcher("/WEB-INF/vistas/operador/viaje-activo.jsp")
               .forward(req, res);

        } catch (Exception e) {
            res.sendRedirect(req.getContextPath() + "/operador/panel");
        }
    }
}
