package mx.urbvan.servlet.auth;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;

import java.io.IOException;
import java.sql.*;

/**
 * RegistroServlet — maneja GET (mostrar formulario) y POST (crear cuenta).
 *
 * Solo registra pasajeros. Los operadores los crea el administrador.
 * Ubicación: src/main/java/mx/urbvan/servlet/auth/RegistroServlet.java
 */
public class RegistroServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        // Si ya tiene sesión activa, no tiene sentido registrarse
        HttpSession session = req.getSession(false);
        if (session != null && session.getAttribute("rol") != null) {
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String nombre    = req.getParameter("nombre");
        String apellido  = req.getParameter("apellido");
        String correo    = req.getParameter("correo");
        String telefono  = req.getParameter("telefono");
        String contrasena       = req.getParameter("contrasena");
        String contrasenaConfirm = req.getParameter("contrasena_confirm");

        // --- Validaciones ---
        String error = validar(nombre, apellido, correo, contrasena, contrasenaConfirm);
        if (error != null) {
            req.setAttribute("error", error);
            reenviarFormulario(req, res);
            return;
        }

        // --- Verificar que el correo no esté registrado ---
        try (Connection conn = ConexionDB.obtener()) {

            if (correoExiste(conn, correo)) {
                req.setAttribute("error", "Este correo ya está registrado. ¿Quieres iniciar sesión?");
                reenviarFormulario(req, res);
                return;
            }

            // --- Insertar nuevo usuario ---
            String hash = HashUtil.sha256(contrasena);
            String sql  = "INSERT INTO usuarios (nombre, apellido, correo, contrasena_hash, telefono) " +
                          "VALUES (?, ?, ?, ?, ?)";

            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, nombre.trim());
                ps.setString(2, apellido.trim());
                ps.setString(3, correo.trim().toLowerCase());
                ps.setString(4, hash);
                ps.setString(5, telefono != null ? telefono.trim() : null);
                ps.executeUpdate();
            }

            // Registro exitoso → redirigir al login con mensaje de éxito
            res.sendRedirect(req.getContextPath() + "/login?registro=ok");

        } catch (Exception e) {
            req.setAttribute("error", "Error del servidor al crear la cuenta. Intenta de nuevo.");
            reenviarFormulario(req, res);
        }
    }

    // ----------------------------------------------------------------

    private String validar(String nombre, String apellido, String correo,
                            String contrasena, String confirm) {
        if (esVacio(nombre))     return "El nombre es obligatorio.";
        if (esVacio(apellido))   return "El apellido es obligatorio.";
        if (esVacio(correo))     return "El correo es obligatorio.";
        if (!correo.contains("@")) return "Ingresa un correo válido.";
        if (esVacio(contrasena)) return "La contraseña es obligatoria.";
        if (contrasena.length() < 6) return "La contraseña debe tener al menos 6 caracteres.";
        if (!contrasena.equals(confirm)) return "Las contraseñas no coinciden.";
        return null;
    }

    private boolean esVacio(String valor) {
        return valor == null || valor.isBlank();
    }

    private boolean correoExiste(Connection conn, String correo) throws SQLException {
        String sql = "SELECT 1 FROM usuarios WHERE correo = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, correo.trim().toLowerCase());
            return ps.executeQuery().next();
        }
    }

    private void reenviarFormulario(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        // Preservar los valores escritos para no perderlos al mostrar el error
        req.setAttribute("val_nombre",   req.getParameter("nombre"));
        req.setAttribute("val_apellido", req.getParameter("apellido"));
        req.setAttribute("val_correo",   req.getParameter("correo"));
        req.setAttribute("val_telefono", req.getParameter("telefono"));
        req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
    }
}
