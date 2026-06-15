package mx.urbvan.servlet.pasajero;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.urbvan.dao.BitacoraDAO;
import mx.urbvan.dao.PerfilDAO;
import java.io.IOException;

@WebServlet("/pasajero/perfil")
public class PerfilServlet extends HttpServlet {
    private final PerfilDAO perfilDAO = new PerfilDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            Integer idUsuario = (Integer) request.getSession().getAttribute("id");
            if (idUsuario == null) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }
            request.setAttribute("perfil", perfilDAO.buscarPerfilPorId(idUsuario));
            request.getRequestDispatcher("/WEB-INF/vistas/pasajero/perfil.jsp").forward(request, response);
        } catch (Exception e) {
            request.setAttribute("error", "No se pudo cargar la información del perfil.");
            request.getRequestDispatcher("/WEB-INF/vistas/pasajero/perfil.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        try {
            Integer idUsuario = (Integer) request.getSession().getAttribute("id");
            String nombreSesion = (String) request.getSession().getAttribute("nombre");
            if (idUsuario == null) {
                response.sendRedirect(request.getContextPath() + "/login");
                return;
            }
            String nombre = request.getParameter("nombre");
            String apellido = request.getParameter("apellido");
            String telefono = request.getParameter("telefono");
            if (nombre == null || nombre.trim().isEmpty()) {
                request.setAttribute("error", "El nombre no puede quedar vacío.");
                doGet(request, response);
                return;
            }
            if (apellido == null) apellido = "";
            if (telefono == null) telefono = "";
            nombre = nombre.trim();
            apellido = apellido.trim();
            telefono = telefono.trim();
            if (!telefono.isEmpty() && telefono.length() < 8) {
                request.setAttribute("error", "El teléfono debe tener al menos 8 caracteres.");
                doGet(request, response);
                return;
            }
            boolean actualizado = perfilDAO.actualizarPerfil(idUsuario, nombre, apellido, telefono);
            if (actualizado) {
                request.getSession().setAttribute("nombre", nombre);
                BitacoraDAO.registrar(idUsuario, nombreSesion, "PASAJERO", "ACTUALIZAR_PERFIL",
                        "El pasajero actualizó su información personal.", request.getRemoteAddr());
                response.sendRedirect(request.getContextPath() + "/pasajero/perfil?actualizado=ok");
            } else {
                request.setAttribute("error", "No se pudo actualizar el perfil.");
                doGet(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Ocurrió un error al actualizar el perfil.");
            doGet(request, response);
        }
    }
}
