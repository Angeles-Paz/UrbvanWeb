package mx.urbvan.util;

import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;

/**
 * HashUtil - utilidad para hashear contraseñas con SHA-256.
 *
 * Uso:
 *   String hash = HashUtil.sha256("MiContrasena123");
 *
 * Ubicación: src/main/java/mx/urbvan/util/HashUtil.java
 */
public class HashUtil {

    /**
     * Convierte un texto plano en su representación SHA-256 hexadecimal.
     * @param texto contraseña en texto plano
     * @return cadena hexadecimal de 64 caracteres
     */
    public static String sha256(String texto) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(texto.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("Error al aplicar SHA-256: " + e.getMessage(), e);
        }
    }

    // Constructor privado - clase de utilidad, no se instancia
    private HashUtil() {}
}
