package mx.urbvan.servlet.b2b.empresa;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import mx.urbvan.dao.ConexionDB;
import mx.urbvan.dao.EmpresaDAO;
import mx.urbvan.dao.RutaB2BDAO;
import mx.urbvan.modelo.*;

import java.io.IOException;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/b2b/empresa/crear-ruta")
public class CrearRutaServlet extends HttpServlet {

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");

    // ── GET: mostrar formulario ──────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws IOException, ServletException {

        // ── 1. Verificar que empresaId existe en sesión ──────────────────────
        Object empIdObj = req.getSession().getAttribute("empresaId");
        if (empIdObj == null) {
            req.setAttribute("error",
                "Tu sesión no tiene una empresa asociada. " +
                "Cierra sesión y vuelve a entrar.");
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/crear-ruta.jsp")
               .forward(req, res);
            return;
        }
        int empresaId = (int) empIdObj;

        // ── 2. Cargar datos necesarios para el formulario ────────────────────
        try {
            Empresa empresa = EmpresaDAO.buscarPorId(empresaId);
            List<Vehiculo> vehiculosB2B = obtenerVehiculosB2B();

            req.setAttribute("empresa",      empresa);
            req.setAttribute("vehiculosB2B", vehiculosB2B);

            // Advertir si no hay vehículos B2B registrados
            if (vehiculosB2B.isEmpty()) {
                req.setAttribute("aviso",
                    "⚠ No hay vehículos B2B disponibles con operador asignado. " +
                    "Pide al Admin Urbvan que registre vehículos B2B y los asigne a operadores.");
            }

            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/crear-ruta.jsp")
               .forward(req, res);

        } catch (Exception e) {
            // Mostrar el error real en el JSP en lugar de redirigir silenciosamente
            req.setAttribute("error", "Error al cargar el formulario: " + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/vistas/b2b/empresa/crear-ruta.jsp")
               .forward(req, res);
        }
    }

    // ── POST: procesar creación de ruta ──────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws IOException, ServletException {

        req.setCharacterEncoding("UTF-8");

        Object empIdObj = req.getSession().getAttribute("empresaId");
        if (empIdObj == null) {
            res.sendRedirect(req.getContextPath() + "/b2b/empresa/dashboard");
            return;
        }
        int empresaId = (int) empIdObj;

        try {
            // Validar parámetros requeridos
            String vehiculoIdStr  = req.getParameter("vehiculoId");
            String operadorIdStr  = req.getParameter("operadorId");
            String fechaInicioStr = req.getParameter("fechaInicio");
            String kmStr          = req.getParameter("kmTotales");
            String horasStr       = req.getParameter("duracionHoras");
            String modelo         = req.getParameter("modeloVehiculo");

            if (vehiculoIdStr == null || vehiculoIdStr.isBlank()
                    || operadorIdStr == null || operadorIdStr.isBlank()
                    || fechaInicioStr == null || fechaInicioStr.isBlank()) {
                req.setAttribute("error",
                    "Faltan datos del formulario. Asegúrate de seleccionar origen, " +
                    "destino, vehículo y fecha de inicio.");
                doGet(req, res);
                return;
            }

            int    vehiculoId = Integer.parseInt(vehiculoIdStr);
            int    operadorId = Integer.parseInt(operadorIdStr);
            LocalDateTime inicio = LocalDateTime.parse(fechaInicioStr, FMT);
            double kmTotales  = Double.parseDouble(kmStr != null && !kmStr.isBlank() ? kmStr : "0");
            double durHoras   = Double.parseDouble(horasStr != null && !horasStr.isBlank() ? horasStr : "1");

            // Calcular costo con tarifa del modelo
            TarifaVehiculo tarifa = (modelo != null) ? RutaB2BDAO.obtenerTarifa(modelo) : null;
            double costo = (tarifa != null)
                    ? tarifa.calcularCosto(kmTotales, durHoras)
                    : kmTotales * 18.50 + durHoras * 320.00;   // fallback tarifa base

            LocalDateTime fin = inicio.plusMinutes(Math.round(durHoras * 60));

            RutaB2B ruta = new RutaB2B();
            ruta.setEmpresaId(empresaId);
            ruta.setVehiculoId(vehiculoId);
            ruta.setOperadorId(operadorId);
            ruta.setFechaInicio(inicio);
            ruta.setFechaFinEst(fin);
            ruta.setKmTotales(kmTotales);
            ruta.setCostoTotal(costo);

            // Construir paradas desde los arrays del formulario
            String[] tipos     = req.getParameterValues("paradaTipo");
            String[] lats      = req.getParameterValues("paradaLat");
            String[] lngs      = req.getParameterValues("paradaLng");
            String[] nombres   = req.getParameterValues("paradaNombre");
            String[] estancias = req.getParameterValues("paradaEstancia");

            List<RutaParada> paradas = new ArrayList<>();
            if (tipos != null && tipos.length >= 2) {
                for (int i = 0; i < tipos.length; i++) {
                    RutaParada p = new RutaParada();
                    p.setOrden(i);
                    p.setTipo(RutaParada.Tipo.fromDb(tipos[i]));
                    p.setLatitud(Double.parseDouble(lats[i]));
                    p.setLongitud(Double.parseDouble(lngs[i]));
                    p.setNombreLugar(nombres != null && i < nombres.length ? nombres[i] : "Parada " + (i+1));
                    p.setTiempoEstancia(
                            estancias != null && i < estancias.length
                            && !estancias[i].isBlank()
                                    ? Integer.parseInt(estancias[i]) : 0);
                    paradas.add(p);
                }
            } else {
                req.setAttribute("error",
                    "La ruta debe tener al menos un origen y un destino. " +
                    "Coloca los puntos en el mapa antes de enviar.");
                doGet(req, res);
                return;
            }

            int rutaId = RutaB2BDAO.crear(ruta, paradas);
            res.sendRedirect(req.getContextPath() +
                             "/b2b/empresa/asignar-asientos?rutaId=" + rutaId);

        } catch (Exception e) {
            req.setAttribute("error", "Error al crear la ruta: " + e.getMessage());
            doGet(req, res);
        }
    }

    // ── Vehículos B2B con operador asignado ──────────────────────────────────
    private List<Vehiculo> obtenerVehiculosB2B() throws Exception {
        String sql = """
                SELECT v.id, v.modelo, v.capacidad, v.placa,
                       v.operador_id, u.nombre AS operador_nombre
                FROM   vehiculos v
                JOIN   usuarios  u ON v.operador_id = u.id
                WHERE  v.categoria = 'b2b'
                  AND  v.activo    = TRUE
                  AND  u.activo    = TRUE
                ORDER BY v.modelo, v.placa
                """;
        List<Vehiculo> lista = new ArrayList<>();
        try (Connection c = ConexionDB.obtener();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Vehiculo v = new Vehiculo();
                v.setId(rs.getInt("id"));
                v.setModelo(rs.getString("modelo"));
                v.setCapacidad(rs.getInt("capacidad"));
                v.setPlaca(rs.getString("placa"));
                v.setOperadorId(rs.getInt("operador_id"));
                v.setOperadorNombre(rs.getString("operador_nombre"));
                lista.add(v);
            }
        }
        return lista;
    }
}
