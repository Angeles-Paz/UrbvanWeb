package mx.urbvan.api;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * ApiAuthFilter – valida el token Bearer en todas las rutas /api/*.
 *
 * Cómo funciona:
 *  1. Intercepta TODAS las peticiones a /api/*
 *  2. Excluye /api/login (no necesita token todavía)
 *  3. Lee el header: Authorization: Bearer <token>
 *  4. Valida el token en ApiTokenStore
 *  5. Si válido: establece atributos de request con datos del usuario y continúa
 *  6. Si inválido: responde 401 JSON sin llegar al servlet
 *
 * Los atributos que deja en el request (leídos por ApiUtil.*):
 *   _uid        → int   (usuarios.id)
 *   _nombre     → String
 *   _rol        → String ("pasajero" | "operador" | "admin_empresa")
 *   _esEmpleado → Boolean
 *   _empresaId  → int
 */
@WebFilter("/api/*")
public class ApiAuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        // Configurar cabeceras CORS (útil para pruebas con Postman / emulador)
        response.setHeader("Access-Control-Allow-Origin",  "*");
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");

        // Pre-flight CORS
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            response.setStatus(HttpServletResponse.SC_OK);
            return;
        }

        String path = request.getServletPath();

        // /api/login no necesita token (es el endpoint que lo genera)
        if ("/api/login".equals(path)) {
            chain.doFilter(req, res);
            return;
        }

        // Extraer token del header "Authorization: Bearer <token>"
        String authHeader = request.getHeader("Authorization");
        String token = null;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            token = authHeader.substring(7).trim();
        }

        // Validar token
        ApiTokenStore.UserSession session = ApiTokenStore.getInstance().getSession(token);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"ok\":false,\"error\":\"Token inválido o sesión expirada. Inicia sesión nuevamente.\"}");
            return;
        }

        // Token válido: pasar datos de sesión como atributos del request
        request.setAttribute(ApiUtil.ATTR_UID,         session.userId);
        request.setAttribute(ApiUtil.ATTR_NOMBRE,      session.nombre);
        request.setAttribute(ApiUtil.ATTR_ROL,         session.rol);
        request.setAttribute(ApiUtil.ATTR_ES_EMPLEADO, session.esEmpleado);
        request.setAttribute(ApiUtil.ATTR_EMPRESA_ID,  session.empresaId);

        chain.doFilter(req, res);
    }

    @Override public void init(FilterConfig fc) throws ServletException {}
    @Override public void destroy() {}
}
