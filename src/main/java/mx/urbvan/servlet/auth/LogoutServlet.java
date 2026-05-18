package mx.urbvan.servlet.auth;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * LogoutServlet — invalida la sesión activa y redirige al login.
 * Ubicación: src/main/java/mx/urbvan/servlet/auth/LogoutServlet.java
 */
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        res.sendRedirect(req.getContextPath() + "/login");
    }

    // Permite cerrar sesión también por POST (buton de form)
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        doGet(req, res);
    }
}
