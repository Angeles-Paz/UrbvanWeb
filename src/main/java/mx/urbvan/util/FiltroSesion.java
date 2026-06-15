package mx.urbvan.util;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Set;

/**
 * FiltroSesion - intercepta todas las peticiones HTTP.
 *
 * ACTUALIZACIÓN: se agrega la zona /b2b/ruta/ (detalle de ruta)
 * accesible por ADMIN_EMPRESA, OPERADOR y PASAJERO con esEmpleado=true.
 */
@WebFilter("/*")
public class FiltroSesion implements Filter {

    private static final Set<String> RUTAS_PUBLICAS = Set.of(
            "/login", "/registro", "/recuperar", "/logout", "/index.jsp", "/landing.jsp", "/assets/", "/api/"
    );

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;
        String ruta = request.getServletPath();

        // ── 1. Rutas públicas ────────────────────────────────────────────────
        if (RUTAS_PUBLICAS.stream().anyMatch(ruta::startsWith)) {
            chain.doFilter(req, res);
            return;
        }

        // ── 2. Sin sesión ────────────────────────────────────────────────────
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("rol") == null) {
            response.sendRedirect(request.getContextPath() + "/login");
            return;
        }
        String rol = (String) session.getAttribute("rol");

        // ── 3. Zona /b2b/ruta/ - detalle de ruta compartido por 3 roles ─────
        //      Accesible por: ADMIN_EMPRESA, OPERADOR, y PASAJERO+esEmpleado
        if (ruta.startsWith("/b2b/ruta/")) {
            boolean esEmpleadoB2B = Boolean.TRUE.equals(session.getAttribute("esEmpleado"));
            boolean autorizado    = "ADMIN_EMPRESA".equals(rol)
                                 || "OPERADOR".equals(rol)
                                 || ("PASAJERO".equals(rol) && esEmpleadoB2B);
            if (!autorizado) {
                response.sendRedirect(request.getContextPath() + dashboardDe(rol));
                return;
            }
            chain.doFilter(req, res);
            return;
        }

        // ── 4. Zona /b2b/empleado/ - solo PASAJERO con esEmpleado=true ──────
        if (ruta.startsWith("/b2b/empleado/")) {
            Boolean esEmpleado = (Boolean) session.getAttribute("esEmpleado");
            if (!Boolean.TRUE.equals(esEmpleado)) {
                response.sendRedirect(request.getContextPath() + dashboardDe(rol));
                return;
            }
            chain.doFilter(req, res);
            return;
        }

        // ── 5. Verificar zona según rol ──────────────────────────────────────
        boolean accesoPermitido = switch (rol) {
            case "PASAJERO"      -> ruta.startsWith("/pasajero/");
            case "OPERADOR"      -> ruta.startsWith("/operador/");
            case "ADMIN"         -> ruta.startsWith("/admin/");
            case "ADMIN_EMPRESA" -> ruta.startsWith("/b2b/empresa/");
            default              -> false;
        };

        // Endpoint de notificaciones accesible por cualquier rol autenticado
        if (ruta.startsWith("/notificaciones")) accesoPermitido = true;

        if (!accesoPermitido) {
            response.sendRedirect(request.getContextPath() + dashboardDe(rol));
            return;
        }

        chain.doFilter(req, res);
    }

    private String dashboardDe(String rol) {
        return switch (rol) {
            case "PASAJERO"      -> "/pasajero/solicitar";
            case "OPERADOR"      -> "/operador/panel";
            case "ADMIN"         -> "/admin/dashboard";
            case "ADMIN_EMPRESA" -> "/b2b/empresa/dashboard";
            default              -> "/login";
        };
    }

    @Override public void init(FilterConfig fc) throws ServletException {}
    @Override public void destroy() {}
}
