package mx.urbvan.servlet.auth;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.urbvan.dao.RecuperarPasswordDAO;
import java.io.IOException;

@WebServlet("/recuperar")
public class RecuperarPasswordServlet extends HttpServlet {
    private final RecuperarPasswordDAO recuperarDAO = new RecuperarPasswordDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("/WEB-INF/vistas/auth/recuperar.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        try {
            String tipo = request.getParameter("tipo");
            String email = request.getParameter("email");
            String telefono = request.getParameter("telefono");
            String nueva = request.getParameter("nueva");
            String confirmar = request.getParameter("confirmar");

            if (tipo == null || tipo.isBlank() || email == null || email.isBlank()
                    || nueva == null || nueva.isBlank() || confirmar == null || confirmar.isBlank()) {
                request.setAttribute("error", "Completa los datos obligatorios.");
                doGet(request, response);
                return;
            }
            tipo = tipo.trim().toLowerCase();
            email = email.trim();
            telefono = telefono == null ? "" : telefono.trim();
            nueva = nueva.trim();
            confirmar = confirmar.trim();

            if (!nueva.equals(confirmar)) {
                request.setAttribute("error", "Las contraseñas no coinciden.");
                doGet(request, response);
                return;
            }
            if (nueva.length() < 6) {
                request.setAttribute("error", "La contraseña debe tener al menos 6 caracteres.");
                doGet(request, response);
                return;
            }
            if (!(tipo.equals("pasajero") || tipo.equals("operador") || tipo.equals("admin") || tipo.equals("admin_empresa"))) {
                request.setAttribute("error", "Tipo de cuenta no válido.");
                doGet(request, response);
                return;
            }

            boolean existe = recuperarDAO.existeUsuario(email, telefono, tipo);
            if (!existe) {
                request.setAttribute("error", "No se encontró una cuenta con los datos ingresados.");
                doGet(request, response);
                return;
            }
            if (recuperarDAO.actualizar(email, nueva)) {
                response.sendRedirect(request.getContextPath() + "/login?recuperacion=ok");
            } else {
                request.setAttribute("error", "No se pudo actualizar la contraseña.");
                doGet(request, response);
            }
        } catch (Exception e) {
            request.setAttribute("error", "Ocurrió un error al recuperar la contraseña.");
            doGet(request, response);
        }
    }
}
