package mx.urbvan.servlet.operador;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.dao.ViajeDAO;
import java.io.IOException;

/** Historial del operador: viajes B2C y rutas B2B asignadas. */
@WebServlet("/operador/historial")
public class HistorialOperadorServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, jakarta.servlet.ServletException {
        int uid = (int) req.getSession().getAttribute("id");
        try {
            req.setAttribute("viajes", ViajeDAO.listarDeOperador(uid));
            req.setAttribute("rutasB2B", RutaB2BDAO.listarDeOperador(uid));
            req.getRequestDispatcher("/WEB-INF/vistas/operador/historial.jsp").forward(req, res);
        } catch (Exception e) {
            req.setAttribute("error", "Error al cargar el historial del operador.");
            req.getRequestDispatcher("/WEB-INF/vistas/operador/historial.jsp").forward(req, res);
        }
    }
}
