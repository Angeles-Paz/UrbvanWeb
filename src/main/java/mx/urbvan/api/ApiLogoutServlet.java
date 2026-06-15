package mx.urbvan.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * ApiLogoutServlet – POST /api/logout
 * Invalida el token Bearer del usuario. La app lo llama cuando el usuario
 * cierra sesión explícitamente y luego limpia SharedPreferences localmente.
 */
@WebServlet("/api/logout")
public class ApiLogoutServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res) throws IOException {
        String authHeader = req.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7).trim();
            ApiTokenStore.getInstance().remove(token);
        }
        ApiUtil.ok(res, "\"msg\":\"Sesión cerrada.\"");
    }
}
