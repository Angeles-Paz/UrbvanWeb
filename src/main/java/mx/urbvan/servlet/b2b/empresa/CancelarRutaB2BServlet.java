package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.RutaB2B;
import java.io.IOException;

/** Admin Empresa - cancelar ruta B2B. URL: /b2b/empresa/cancelar-ruta */
@WebServlet("/b2b/empresa/cancelar-ruta")
public class CancelarRutaB2BServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int empresaId = (int) req.getSession().getAttribute("empresaId");
        try {
            int rutaId = Integer.parseInt(req.getParameter("rutaId"));
            RutaB2B ruta = RutaB2BDAO.buscarPorId(rutaId);
            // Verificar que la ruta pertenece a esta empresa
            if (ruta != null && ruta.getEmpresaId() == empresaId && ruta.puedeCancelarse()) {
                RutaB2BDAO.cancelar(rutaId);
            }
        } catch (Exception e) {
            // Log silencioso - redirigir siempre
        }
        res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
    }
}
