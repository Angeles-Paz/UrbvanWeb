package mx.urbvan.dao;

import mx.urbvan.modelo.Empresa;
import mx.urbvan.modelo.Usuario;
import mx.urbvan.util.HashUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class EmpresaDAO {

    // ── Listar todas las empresas (panel Admin Urbvan) ────────────────────────
    public static List<Empresa> listarTodas() throws Exception {
        String sql = """
            SELECT e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at,
                   COUNT(DISTINCT CASE WHEN eu.rol='empleado' AND eu.activo=TRUE
                         THEN eu.usuario_id END)          AS empleados_activos,
                   COUNT(DISTINCT CASE WHEN r.estado='completada'
                         THEN r.id END)                   AS rutas_completadas,
                   COUNT(DISTINCT CASE WHEN r.estado IN ('pendiente','activa')
                         THEN r.id END)                   AS rutas_en_curso
            FROM      empresas e
            LEFT JOIN empresa_usuarios eu ON eu.empresa_id = e.id
            LEFT JOIN rutas_b2b        r  ON r.empresa_id  = e.id
            GROUP BY  e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at
            ORDER BY  e.nombre
            """;
        List<Empresa> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) lista.add(mapear(rs));
        }
        return lista;
    }

    // ── Buscar por id ─────────────────────────────────────────────────────────
    public static Empresa buscarPorId(int id) throws Exception {
        String sql = """
            SELECT e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at,
                   COUNT(DISTINCT CASE WHEN eu.rol='empleado' AND eu.activo=TRUE
                         THEN eu.usuario_id END) AS empleados_activos,
                   COUNT(DISTINCT CASE WHEN r.estado='completada'
                         THEN r.id END)          AS rutas_completadas,
                   COUNT(DISTINCT CASE WHEN r.estado IN ('pendiente','activa')
                         THEN r.id END)          AS rutas_en_curso
            FROM      empresas e
            LEFT JOIN empresa_usuarios eu ON eu.empresa_id = e.id
            LEFT JOIN rutas_b2b        r  ON r.empresa_id  = e.id
            WHERE e.id = ?
            GROUP BY  e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    // ── Buscar empresa de un usuario (admin_empresa o empleado) ──────────────
    public static Empresa buscarDeUsuario(int usuarioId) throws Exception {
        String sql = """
            SELECT e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at,
                   0 AS empleados_activos, 0 AS rutas_completadas, 0 AS rutas_en_curso
            FROM   empresas e
            JOIN   empresa_usuarios eu ON eu.empresa_id = e.id
            WHERE  eu.usuario_id = ? AND eu.activo = TRUE
            LIMIT 1
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, usuarioId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapear(rs) : null;
        }
    }

    // ── Crear empresa + admin_empresa en una transacción ─────────────────────
    public static void crearConAdmin(String nombreEmpresa,
                                      String adminNombre,
                                      String adminEmail,
                                      String passwordTemporal) throws Exception {
        try (Connection c = ConexionDB.obtener()) {
            c.setAutoCommit(false);
            try {
                // 1. Insertar empresa
                int empresaId;
                try (PreparedStatement ps = c.prepareStatement(
                        "INSERT INTO empresas (nombre) VALUES (?)",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, nombreEmpresa);
                    ps.executeUpdate();
                    ResultSet gk = ps.getGeneratedKeys();
                    gk.next();
                    empresaId = gk.getInt(1);
                }
                // 2. Insertar usuario admin_empresa
                int usuarioId;
                try (PreparedStatement ps = c.prepareStatement("""
                        INSERT INTO usuarios (nombre, email, contrasena, rol, activo, primer_login)
                        VALUES (?, ?, ?, 'admin_empresa', TRUE, TRUE)
                        """, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, adminNombre);
                    ps.setString(2, adminEmail);
                    ps.setString(3, HashUtil.sha256(passwordTemporal));
                    ps.executeUpdate();
                    ResultSet gk = ps.getGeneratedKeys();
                    gk.next();
                    usuarioId = gk.getInt(1);
                }
                // 3. Vincular admin_empresa con la empresa
                try (PreparedStatement ps = c.prepareStatement("""
                        INSERT INTO empresa_usuarios (empresa_id, usuario_id, rol)
                        VALUES (?, ?, 'admin_empresa')
                        """)) {
                    ps.setInt(1, empresaId);
                    ps.setInt(2, usuarioId);
                    ps.executeUpdate();
                }
                c.commit();
            } catch (Exception e) {
                c.rollback();
                throw e;
            } finally {
                c.setAutoCommit(true);
            }
        }
    }

    // ── Inhabilitar empresa (via SP) ──────────────────────────────────────────
    public static void inhabilitar(int empresaId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             CallableStatement cs = c.prepareCall("{CALL sp_inhabilitar_empresa(?)}")) {
            cs.setInt(1, empresaId);
            cs.execute();
        }
    }

    // ── Habilitar empresa ─────────────────────────────────────────────────────
    public static void habilitar(int empresaId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(
                     "UPDATE empresas SET activa = TRUE WHERE id = ?")) {
            ps.setInt(1, empresaId);
            ps.executeUpdate();
        }
    }

    // ── Listar empleados de una empresa ───────────────────────────────────────
    public static List<Usuario> listarEmpleados(int empresaId) throws Exception {
        String sql = """
            SELECT u.id, u.nombre, u.email, u.activo, u.calificacion_promedio,
                   eu.rol, eu.activo AS activo_empresa
            FROM   empresa_usuarios eu
            JOIN   usuarios u ON eu.usuario_id = u.id
            WHERE  eu.empresa_id = ? AND eu.activo = TRUE
            ORDER BY u.nombre
            """;
        List<Usuario> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, empresaId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Usuario u = new Usuario();
                u.setId(rs.getInt("id"));
                u.setNombre(rs.getString("nombre"));
                u.setEmail(rs.getString("email"));
                u.setActivo(rs.getBoolean("activo"));
                u.setCalificacionPromedio(rs.getDouble("calificacion_promedio"));
                u.setRol(rs.getString("rol"));
                lista.add(u);
            }
        }
        return lista;
    }

    // ── Agregar empleado a empresa ────────────────────────────────────────────
    public static void agregarEmpleado(int empresaId, int usuarioId) throws Exception {
        String sql = """
            INSERT INTO empresa_usuarios (empresa_id, usuario_id, rol, activo)
            VALUES (?, ?, 'empleado', TRUE)
            ON DUPLICATE KEY UPDATE activo = TRUE
            """;
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, empresaId);
            ps.setInt(2, usuarioId);
            ps.executeUpdate();
        }
    }

    // ── Dar de baja empleado de empresa ──────────────────────────────────────
    public static void bajaEmpleado(int empresaId, int usuarioId) throws Exception {
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement("""
                     UPDATE empresa_usuarios SET activo = FALSE
                     WHERE empresa_id = ? AND usuario_id = ? AND rol = 'empleado'
                     """)) {
            ps.setInt(1, empresaId);
            ps.setInt(2, usuarioId);
            ps.executeUpdate();
        }
    }

    // ── Mapper ────────────────────────────────────────────────────────────────
    private static Empresa mapear(ResultSet rs) throws SQLException {
        Empresa e = new Empresa();
        e.setId(rs.getInt("id"));
        e.setNombre(rs.getString("nombre"));
        e.setScore(rs.getDouble("score"));
        e.setGastoTotal(rs.getDouble("gasto_total"));
        e.setActiva(rs.getBoolean("activa"));
        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) e.setCreatedAt(ts.toLocalDateTime());
        e.setEmpleadosActivos(rs.getInt("empleados_activos"));
        e.setRutasCompletadas(rs.getInt("rutas_completadas"));
        e.setRutasEnCurso(rs.getInt("rutas_en_curso"));
        return e;
    }
}
