package mx.urbvan.api;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ApiTokenStore – almacén de tokens Bearer para la API móvil.
 *
 * Singleton de JVM. Guarda la sesión del usuario vinculada a un UUID
 * en un ConcurrentHashMap (thread-safe, sin bloqueos costosos).
 *
 * Los tokens no tienen expiración en esta versión; se invalidan solo
 * al hacer logout explícito desde la app.
 *
 * NOTA: como toda estructura en memoria, los tokens se pierden si Tomcat
 * se reinicia. La app móvil detectará el 401 y llevará al usuario al login.
 */
public final class ApiTokenStore {

    // ── Estructura de sesión ──────────────────────────────────────────────────

    public static final class UserSession {
        public final int     userId;
        public final String  nombre;
        public final String  rol;          // "pasajero" | "operador" | "admin_empresa"
        public final boolean esEmpleado;
        public final int     empresaId;

        public UserSession(int userId, String nombre, String rol,
                           boolean esEmpleado, int empresaId) {
            this.userId     = userId;
            this.nombre     = nombre;
            this.rol        = rol;
            this.esEmpleado = esEmpleado;
            this.empresaId  = empresaId;
        }
    }

    // ── Singleton ─────────────────────────────────────────────────────────────

    private static final ApiTokenStore INSTANCE = new ApiTokenStore();

    public static ApiTokenStore getInstance() { return INSTANCE; }

    private final ConcurrentHashMap<String, UserSession> store = new ConcurrentHashMap<>();

    private ApiTokenStore() {}

    // ── API pública ───────────────────────────────────────────────────────────

    /**
     * Crea un token nuevo y almacena la sesión del usuario.
     * @return token UUID que el cliente guardará para autenticarse.
     */
    public String createToken(int userId, String nombre, String rol,
                              boolean esEmpleado, int empresaId) {
        String token = UUID.randomUUID().toString();
        store.put(token, new UserSession(userId, nombre, rol, esEmpleado, empresaId));
        return token;
    }

    /**
     * Busca la sesión asociada al token.
     * @return UserSession o null si el token no existe / es inválido.
     */
    public UserSession getSession(String token) {
        if (token == null || token.isBlank()) return null;
        return store.get(token);
    }

    /**
     * Invalida el token (logout). La app móvil deberá pedir nuevas credenciales.
     */
    public void remove(String token) {
        if (token != null) store.remove(token);
    }

    /** Número de sesiones activas (útil para diagnóstico). */
    public int activeCount() { return store.size(); }
}
