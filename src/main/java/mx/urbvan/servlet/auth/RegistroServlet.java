package mx.urbvan.servlet.auth;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;
import java.io.IOException;
import java.sql.*;

/**
 * RegistroServlet - registro de nuevos pasajeros.
 * CAMBIOS vs v1: columnas correo→email, contrasena_hash→contrasena; se inserta rol='pasajero'.
 */
@WebServlet("/registro")
public class RegistroServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String nombre    = req.getParameter("nombre");
        String apellido  = req.getParameter("apellido");
        String telefono  = req.getParameter("telefono");
        String email     = req.getParameter("email");
        String password  = req.getParameter("contrasena");
        String password2 = req.getParameter("contrasena2");

        if (nombre == null || nombre.isBlank() || email == null || email.isBlank()
                || password == null || password.isBlank()) {
            req.setAttribute("error", "Todos los campos son obligatorios.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
            return;
        }
        if (!password.equals(password2)) {
            req.setAttribute("error", "Las contraseñas no coinciden.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
            return;
        }

        try (Connection conn = ConexionDB.obtener()) {
            // Verificar email único
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM usuarios WHERE email = ?")) {
                ps.setString(1, email.trim());
                if (ps.executeQuery().next()) {
                    req.setAttribute("error", "Ese correo ya está registrado.");
                    req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
                    return;
                }
            }
            // Insertar en tabla unificada con rol='pasajero'
            String sql = """
                INSERT INTO usuarios (nombre, apellido, telefono, email, contrasena, rol, activo)
                VALUES (?, ?, ?, ?, ?, 'pasajero', TRUE)
                """;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, nombre.trim());
                ps.setString(2, apellido == null ? "" : apellido.trim());
                ps.setString(3, telefono == null ? "" : telefono.trim());
                ps.setString(4, email.trim());
                ps.setString(5, HashUtil.sha256(password));
                ps.executeUpdate();
            }
            res.sendRedirect(req.getContextPath() + "/login?registro=ok");
        } catch (Exception e) {
            req.setAttribute("error", "Error al registrarse. Intenta de nuevo.");
            req.getRequestDispatcher("/WEB-INF/vistas/auth/registro.jsp").forward(req, res);
        }
    }
}
