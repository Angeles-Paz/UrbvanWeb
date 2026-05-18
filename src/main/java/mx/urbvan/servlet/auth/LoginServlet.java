package mx.urbvan.servlet.auth;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;

import java.io.IOException;
import java.sql.*;

/**
 * LoginServlet — maneja GET (mostrar formulario) y POST (autenticar).
 *
 * Tras autenticarse exitosamente guarda en sesión:
 *   - id        → id numérico del usuario/operador/admin
 *   - nombre    → nombre para mostrar en la UI
 *   - rol       → "PASAJERO" | "OPERADOR" | "ADMINISTRADOR"
 *
 * Luego redirige a su dashboard correspondiente.
 */
public class LoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        // Si ya tiene sesión activa, redirigir a su dashboard
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("rol") != null) {
            redirigirSegunRol((String) session.getAttribute("rol"), req, res);
            return;
        }
        req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String correo     = req.getParameter("correo");
        String contrasena = req.getParameter("contrasena");

        // Validación mínima de campos vacíos
        if (correo == null || correo.isBlank() || contrasena == null || contrasena.isBlank()) {
            req.setAttribute("error", "Por favor ingresa tu correo y contraseña.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
            return;
        }

        String hashIngresado = HashUtil.sha256(contrasena);

        try (Connection conn = ConexionDB.obtener()) {

            // --- Intentar como PASAJERO ---
            String sqlUsuario = "SELECT id_usuario, nombre FROM usuarios " +
                                "WHERE correo = ? AND contrasena_hash = ? AND activo = 1";
            try (PreparedStatement ps = conn.prepareStatement(sqlUsuario)) {
                ps.setString(1, correo);
                ps.setString(2, hashIngresado);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    crearSesion(req, rs.getInt("id_usuario"), rs.getString("nombre"), "PASAJERO");
                    redirigirSegunRol("PASAJERO", req, res);
                    return;
                }
            }

            // --- Intentar como OPERADOR ---
            String sqlOperador = "SELECT id_operador, nombre FROM operadores " +
                                 "WHERE correo = ? AND contrasena_hash = ? AND activo = 1";
            try (PreparedStatement ps = conn.prepareStatement(sqlOperador)) {
                ps.setString(1, correo);
                ps.setString(2, hashIngresado);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    crearSesion(req, rs.getInt("id_operador"), rs.getString("nombre"), "OPERADOR");
                    redirigirSegunRol("OPERADOR", req, res);
                    return;
                }
            }

            // --- Intentar como ADMINISTRADOR ---
            String sqlAdmin = "SELECT id_admin, nombre FROM administradores " +
                              "WHERE correo = ? AND contrasena_hash = ?";
            try (PreparedStatement ps = conn.prepareStatement(sqlAdmin)) {
                ps.setString(1, correo);
                ps.setString(2, hashIngresado);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    crearSesion(req, rs.getInt("id_admin"), rs.getString("nombre"), "ADMINISTRADOR");
                    redirigirSegunRol("ADMINISTRADOR", req, res);
                    return;
                }
            }

            // Ninguna tabla coincidió
            req.setAttribute("error", "Correo o contraseña incorrectos.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);

        } catch (Exception e) {
            req.setAttribute("error", "Error del servidor. Intenta de nuevo.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/login.jsp").forward(req, res);
        }
    }

    // ----------------------------------------------------------------

    private void crearSesion(HttpServletRequest req, int id, String nombre, String rol) {
        HttpSession session = req.getSession(true);
        session.setAttribute("id",     id);
        session.setAttribute("nombre", nombre);
        session.setAttribute("rol",    rol);
    }

    private void redirigirSegunRol(String rol, HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        String base = req.getContextPath();
        switch (rol) {
            case "PASAJERO"      -> res.sendRedirect(base + "/pasajero/dashboard");
            case "OPERADOR"      -> res.sendRedirect(base + "/operador/panel");
            case "ADMINISTRADOR" -> res.sendRedirect(base + "/admin/dashboard");
            default              -> res.sendRedirect(base + "/login");
        }
    }
}
