package mx.urbvan.api;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.util.HashUtil;

import java.io.IOException;
import java.sql.*;

/**
 * ApiLoginServlet – POST /api/login
 *
 * Mismo proceso que LoginServlet.doPost() del web, pero:
 *  - Lee credenciales del cuerpo JSON en lugar de form-params
 *  - Devuelve JSON con token Bearer en lugar de redirigir a una vista
 *  - No crea HttpSession (la app móvil es stateless)
 *
 * Request body (JSON):
 *  {"email":"maria@correo.com","contrasena":"Pasajero1"}
 *
 * Response (JSON):
 *  {"ok":true,"token":"uuid","userId":6,"nombre":"María López",
 *   "rol":"pasajero","esEmpleado":false,"empresaId":-1}
 *
 *  {"ok":false,"error":"Correo o contraseña incorrectos."}
 */
@WebServlet("/api/login")
public class ApiLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException {

        // 1. Leer y parsear body JSON
        String body = ApiUtil.readBody(req);
        String email     = ApiUtil.jsonVal(body, "email");
        String contrasena = ApiUtil.jsonVal(body, "contrasena");

        if (email == null || email.isBlank() || contrasena == null || contrasena.isBlank()) {
            ApiUtil.error(res, 400, "Correo y contraseña requeridos.");
            return;
        }

        String hashIngresado = HashUtil.sha256(contrasena);

        // 2. Consultar BD (misma query que LoginServlet)
        String sql = """
            SELECT id, nombre, rol, activo, primer_login
            FROM   usuarios
            WHERE  email      = ?
              AND  contrasena  = ?
            """;

        try (Connection conn = ConexionDB.obtener();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email.trim().toLowerCase());
            ps.setString(2, hashIngresado);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                ApiUtil.error(res, 401, "Correo o contraseña incorrectos.");
                return;
            }

            if (!rs.getBoolean("activo")) {
                ApiUtil.error(res, 403, "Cuenta deshabilitada. Contacta al administrador.");
                return;
            }

            int    userId = rs.getInt("id");
            String nombre = rs.getString("nombre");
            String rol    = rs.getString("rol");  // "pasajero" | "operador" | "admin_empresa" | "admin"

            // 3. Datos B2B adicionales (igual que LoginServlet)
            boolean esEmpleado = false;
            int     empresaId  = -1;

            if ("pasajero".equals(rol)) {
                String sqlEmp = """
                    SELECT empresa_id FROM empresa_usuarios
                    WHERE  usuario_id = ? AND rol = 'empleado' AND activo = TRUE
                    LIMIT 1
                    """;
                try (PreparedStatement ps2 = conn.prepareStatement(sqlEmp)) {
                    ps2.setInt(1, userId);
                    ResultSet rs2 = ps2.executeQuery();
                    if (rs2.next()) {
                        esEmpleado = true;
                        empresaId  = rs2.getInt("empresa_id");
                    }
                }
            }

            if ("admin_empresa".equals(rol)) {
                String sqlEmp = """
                    SELECT empresa_id FROM empresa_usuarios
                    WHERE  usuario_id = ? AND rol = 'admin_empresa' AND activo = TRUE
                    LIMIT 1
                    """;
                try (PreparedStatement ps2 = conn.prepareStatement(sqlEmp)) {
                    ps2.setInt(1, userId);
                    ResultSet rs2 = ps2.executeQuery();
                    if (rs2.next()) empresaId = rs2.getInt("empresa_id");
                }
            }

            // 4. Generar token y guardar sesión
            String token = ApiTokenStore.getInstance()
                    .createToken(userId, nombre, rol, esEmpleado, empresaId);

            // 5. Responder con token y datos de sesión
            ApiUtil.ok(res, String.format(
                "\"token\":\"%s\",\"userId\":%d,\"nombre\":\"%s\"," +
                "\"rol\":\"%s\",\"esEmpleado\":%b,\"empresaId\":%d",
                token, userId, ApiUtil.esc(nombre),
                rol, esEmpleado, empresaId));

        } catch (Exception e) {
            ApiUtil.error(res, 500, "Error interno al iniciar sesión.");
        }
    }

    /** Permite verificar que el endpoint existe (GET /api/login). */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
        ApiUtil.writeJson(res, 200, "{\"ok\":true,\"msg\":\"Urbvan API v1.0 - POST /api/login para autenticarte\"}");
    }
}
