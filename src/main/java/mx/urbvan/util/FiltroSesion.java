package mx.urbvan.util;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * FiltroSesion — intercepta TODAS las peticiones HTTP.
 *
 * Lógica:
 *  1. Si la ruta es pública (login, registro, assets) → deja pasar.
 *  2. Si no hay sesión activa → redirige al login.
 *  3. Si hay sesión pero el rol no coincide con la ruta → redirige a su dashboard.
 */
public class FiltroSesion implements Filter {

    // Rutas accesibles sin iniciar sesión
    private static final List<String> RUTAS_PUBLICAS = Arrays.asList(
            "/login",
            "/registro",
            "/logout",
            "/index.jsp",
            "/assets/"
    );

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        String ruta = request.getServletPath();

        // --- 1. Rutas públicas: dejar pasar sin verificar sesión ---
        boolean esPublica = RUTAS_PUBLICAS.stream().anyMatch(ruta::startsWith);
        if (esPublica) {
            chain.doFilter(req, res);
            return;
        }

        // --- 2. Sin sesión: redirigir al login ---
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }

        // --- 3. Verificar que el rol coincida con la ruta solicitada ---
        String rol = (String) session.getAttribute("rol");

        boolean accesoPermitido =
                (rol.equals("PASAJERO")      && ruta.startsWith("/pasajero/")) ||
                (rol.equals("OPERADOR")      && ruta.startsWith("/operador/")) ||
                (rol.equals("ADMINISTRADOR") && ruta.startsWith("/admin/"));

        if (!accesoPermitido) {
            // Redirigir a su propio dashboard si intenta acceder a zona de otro rol
            response.sendRedirect(request.getContextPath() + dashboardDe(rol));
            return;
        }

        // Todo en orden — continuar con la petición
        chain.doFilter(req, res);
    }

    private String dashboardDe(String rol) {
        return switch (rol) {
            case "PASAJERO"      -> "/pasajero/dashboard";
            case "OPERADOR"      -> "/operador/panel";
            case "ADMINISTRADOR" -> "/admin/dashboard";
            default              -> "/login";
        };
    }

    @Override public void init(FilterConfig fc) {}
    @Override public void destroy() {}
}
