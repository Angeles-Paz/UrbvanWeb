package mx.urbvan.dao;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

/**
 * ConexionDB — gestiona la conexión JDBC con MySQL.
 *
 * Lee las credenciales desde db.properties (no están hardcodeadas
 * en el código fuente). Uso:
 *
 *   try (Connection conn = ConexionDB.obtener()) {
 *       // usar conn...
 *   }  // se cierra automáticamente con try-with-resources
 */
public class ConexionDB {

    private static String URL;
    private static String USUARIO;
    private static String CONTRASENA;

    // Carga las credenciales UNA sola vez cuando se carga la clase
    static {
        try {
            Properties props = new Properties();
            InputStream in = ConexionDB.class
                    .getClassLoader()
                    .getResourceAsStream("db.properties");
            props.load(in);
            URL       = props.getProperty("db.url");
            USUARIO   = props.getProperty("db.usuario");
            CONTRASENA = props.getProperty("db.contrasena");
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (Exception e) {
            throw new RuntimeException("Error al cargar configuración de BD: " + e.getMessage(), e);
        }
    }

    /**
     * Devuelve una nueva conexión a la base de datos.
     * Usar siempre dentro de un try-with-resources para que se cierre sola.
     */
    public static Connection obtener() throws Exception {
        return DriverManager.getConnection(URL, USUARIO, CONTRASENA);
    }

    // Constructor privado — esta clase no se instancia
    private ConexionDB() {}
}
