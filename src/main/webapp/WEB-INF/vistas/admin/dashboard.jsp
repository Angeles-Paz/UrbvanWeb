<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.sql.Timestamp, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Administrador</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=DM+Mono:wght@400&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --coral: #993C1D; --coral-dark: #712B13; --coral-light: #FAECE7;
            --verde: #1D9E75; --verde-light: #E1F5EE;
            --purple: #534AB7; --purple-light: #EEEDFE;
            --amber: #BA7517; --amber-light: #FAEEDA;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30;
        }
        body { font-family: 'DM Sans', sans-serif; background: var(--fondo); min-height: 100vh; }

        /* ── Navbar ── */
        nav {
            background: var(--coral-dark); height: 56px;
            display: flex; align-items: center;
            justify-content: space-between; padding: 0 32px;
            position: sticky; top: 0; z-index: 10;
        }
        .nav-marca { display: flex; align-items: center; gap: 10px; }
        .nav-logo  { font-size: 18px; font-weight: 600; color: white; }
        .nav-badge { font-size: 11px; background: rgba(255,255,255,.15); color: white; padding: 3px 10px; border-radius: 20px; }
        .nav-links { display: flex; align-items: center; gap: 4px; }
        .nav-link  {
            font-size: 13px; color: rgba(255,255,255,.7); text-decoration: none;
            padding: 6px 14px; border-radius: 20px; transition: background .15s, color .15s;
        }
        .nav-link:hover  { background: rgba(255,255,255,.1); color: white; }
        .nav-link.activo { background: rgba(255,255,255,.15); color: white; font-weight: 500; }
        .btn-logout { font-size: 12px; color: rgba(255,255,255,.6); text-decoration: none; padding: 5px 12px; border: 1px solid rgba(255,255,255,.2); border-radius: 20px; margin-left: 8px; }
        .btn-logout:hover { color: white; }

        .contenedor { max-width: 1200px; margin: 0 auto; padding: 32px 24px; }

        /* ── Encabezado ── */
        .encabezado { margin-bottom: 28px; }
        .encabezado h1 { font-size: 24px; font-weight: 600; color: var(--texto); letter-spacing: -0.3px; }
        .encabezado p  { font-size: 13px; color: var(--texto-2); margin-top: 4px; }

        /* ── Métricas ── */
        .metricas { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; margin-bottom: 28px; }
        .metrica-card {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 14px; padding: 18px 20px;
        }
        .metrica-card.destacada { border-color: var(--coral); }
        .m-label { font-size: 11px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 10px; }
        .m-valor { font-size: 32px; font-weight: 600; color: var(--texto); line-height: 1; }
        .m-valor.verde  { color: var(--verde); }
        .m-valor.purple { color: var(--purple); }
        .m-valor.coral  { color: var(--coral); }
        .m-sub   { font-size: 12px; color: var(--texto-3); margin-top: 6px; }

        /* ── Grid principal ── */
        .grid-2 { display: grid; grid-template-columns: 1fr 340px; gap: 24px; margin-bottom: 24px; }

        /* ── Sección ── */
        .seccion {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 16px; overflow: hidden;
        }
        .seccion-header {
            padding: 16px 20px; border-bottom: 1px solid var(--borde);
            display: flex; align-items: center; justify-content: space-between;
        }
        .seccion-titulo { font-size: 14px; font-weight: 600; color: var(--texto); }
        .seccion-sub    { font-size: 12px; color: var(--texto-3); margin-top: 2px; }
        .badge-count {
            font-size: 11px; font-weight: 500; padding: 3px 10px;
            border-radius: 20px; background: var(--coral-light); color: var(--coral);
        }

        /* ── Tabla de viajes activos ── */
        .tabla { width: 100%; border-collapse: collapse; font-size: 12px; }
        .tabla th {
            text-align: left; font-weight: 500; color: var(--texto-3);
            font-size: 11px; padding: 10px 16px;
            border-bottom: 1px solid var(--borde); white-space: nowrap;
        }
        .tabla td { padding: 11px 16px; border-bottom: 1px solid var(--borde); color: var(--texto-2); vertical-align: middle; }
        .tabla tr:last-child td { border-bottom: none; }
        .tabla tr:hover td { background: var(--fondo); }
        .td-truncate { max-width: 180px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .td-id { font-family: 'DM Mono', monospace; color: var(--texto-3); font-size: 11px; }

        /* Badges de estado */
        .badge-estado {
            display: inline-block; font-size: 10px; font-weight: 500;
            padding: 3px 8px; border-radius: 10px; white-space: nowrap;
        }
        .be-en_asignacion    { background: var(--amber-light);  color: var(--amber); }
        .be-aceptado         { background: var(--purple-light); color: var(--purple); }
        .be-operador_en_camino { background: var(--purple-light); color: var(--purple); }
        .be-viaje_iniciado   { background: var(--verde-light);  color: #0F6E56; }
        .be-completado       { background: var(--verde-light);  color: #0F6E56; }
        .be-cancelado        { background: var(--coral-light);  color: var(--coral); }
        .be-solicitado       { background: #F1EFE8; color: var(--texto-3); }

        /* ── Operadores ── */
        .op-lista { padding: 4px 0; }
        .op-item  {
            display: flex; align-items: center; gap: 12px;
            padding: 12px 20px; border-bottom: 1px solid var(--borde);
        }
        .op-item:last-child { border-bottom: none; }
        .op-avatar {
            width: 36px; height: 36px; border-radius: 50%; flex-shrink: 0;
            display: flex; align-items: center; justify-content: center;
            font-size: 13px; font-weight: 600;
        }
        .av-disponible { background: var(--verde-light); color: #0F6E56; }
        .av-ocupado    { background: var(--purple-light); color: var(--purple); }
        .av-inactivo   { background: #F1EFE8; color: var(--texto-3); }
        .op-info { flex: 1; min-width: 0; }
        .op-nombre { font-size: 13px; font-weight: 500; color: var(--texto); }
        .op-vehiculo { font-size: 11px; color: var(--texto-3); margin-top: 1px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .op-estado-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
        .dot-disp  { background: var(--verde); }
        .dot-ocup  { background: var(--purple); }
        .dot-inact { background: var(--texto-3); }
        .op-cal { font-size: 11px; color: var(--amber); white-space: nowrap; }

        /* ── Historial ── */
        .sin-datos { padding: 32px; text-align: center; font-size: 13px; color: var(--texto-3); }

        @media (max-width: 900px) {
            .metricas { grid-template-columns: repeat(2,1fr); }
            .grid-2   { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM HH:mm");
    int mTotalViajes     = request.getAttribute("m_total_viajes")     != null ? (int)request.getAttribute("m_total_viajes") : 0;
    int mCompletados     = request.getAttribute("m_completados")      != null ? (int)request.getAttribute("m_completados") : 0;
    int mActivos         = request.getAttribute("m_activos")          != null ? (int)request.getAttribute("m_activos") : 0;
    int mUsuarios        = request.getAttribute("m_total_usuarios")   != null ? (int)request.getAttribute("m_total_usuarios") : 0;
    int mOperadores      = request.getAttribute("m_total_operadores") != null ? (int)request.getAttribute("m_total_operadores") : 0;
    int mOpDisp          = request.getAttribute("m_op_disponibles")   != null ? (int)request.getAttribute("m_op_disponibles") : 0;
    double mIngresos     = request.getAttribute("m_ingresos")         != null ? (double)request.getAttribute("m_ingresos") : 0;
    List<Object[]> viajesActivos = (List<Object[]>) request.getAttribute("viajes_activos");
    List<Object[]> operadores   = (List<Object[]>) request.getAttribute("operadores");
    List<Object[]> historial    = (List<Object[]>) request.getAttribute("historial");
    String adminNombre = (String) request.getSession().getAttribute("nombre");
%>

<nav>
    <div class="nav-marca">
        <span class="nav-logo">Urbvan</span>
        <span class="nav-badge">Administrador</span>
    </div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard"  class="nav-link activo">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios"   class="nav-link">Usuarios</a>
        <a href="${pageContext.request.contextPath}/admin/operadores" class="nav-link">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos"  class="nav-link">Vehículos</a>
        <a href="${pageContext.request.contextPath}/logout"           class="btn-logout">Salir</a>
    </div>
</nav>

<div class="contenedor">

    <div class="encabezado">
        <h1>Panel de control</h1>
        <p>Bienvenido, <%= adminNombre %>. Vista general del sistema Urbvan.</p>
    </div>

    <!-- Métricas -->
    <div class="metricas">
        <div class="metrica-card destacada">
            <div class="m-label">Viajes activos</div>
            <div class="m-valor coral"><%= mActivos %></div>
            <div class="m-sub">en este momento</div>
        </div>
        <div class="metrica-card">
            <div class="m-label">Viajes totales</div>
            <div class="m-valor"><%= mTotalViajes %></div>
            <div class="m-sub"><%= mCompletados %> completados</div>
        </div>
        <div class="metrica-card">
            <div class="m-label">Operadores activos</div>
            <div class="m-valor purple"><%= mOpDisp %> / <%= mOperadores %></div>
            <div class="m-sub">disponibles ahora</div>
        </div>
        <div class="metrica-card">
            <div class="m-label">Ingresos simulados</div>
            <div class="m-valor verde">$<%= String.format("%.0f", mIngresos) %></div>
            <div class="m-sub"><%= mUsuarios %> usuarios registrados</div>
        </div>
    </div>

    <!-- Grid: viajes activos + operadores -->
    <div class="grid-2">

        <!-- Viajes activos -->
        <div class="seccion">
            <div class="seccion-header">
                <div>
                    <div class="seccion-titulo">Viajes en curso</div>
                    <div class="seccion-sub">Actualizados en tiempo real</div>
                </div>
                <span class="badge-count"><%= viajesActivos != null ? viajesActivos.size() : 0 %> activos</span>
            </div>
            <% if (viajesActivos == null || viajesActivos.isEmpty()) { %>
            <div class="sin-datos">No hay viajes activos en este momento.</div>
            <% } else { %>
            <table class="tabla">
                <tr>
                    <th>#</th><th>Estado</th><th>Pasajero</th>
                    <th>Operador</th><th>Origen</th><th>Precio</th><th>Hora</th>
                </tr>
                <% for (Object[] v : viajesActivos) {
                    String estadoBadge = v[1].toString().toLowerCase().replace("_","-");
                    String origenCorto = v[3] != null && v[3].toString().length() > 30
                        ? v[3].toString().substring(0,30) + "…" : (v[3] != null ? v[3].toString() : "—");
                %>
                <tr>
                    <td class="td-id">#<%= v[0] %></td>
                    <td><span class="badge-estado be-<%= estadoBadge %>"><%= v[1].toString().replace("_"," ") %></span></td>
                    <td><%= v[6] != null ? v[6] : "—" %></td>
                    <td><%= v[7] != null ? v[7] : "Sin asignar" %></td>
                    <td class="td-truncate"><%= origenCorto %></td>
                    <td>$<%= String.format("%.2f", v[2]) %></td>
                    <td style="white-space:nowrap"><%= v[5] != null ? sdf.format(v[5]) : "—" %></td>
                </tr>
                <% } %>
            </table>
            <% } %>
        </div>

        <!-- Estado de operadores -->
        <div class="seccion">
            <div class="seccion-header">
                <div>
                    <div class="seccion-titulo">Operadores</div>
                    <div class="seccion-sub"><%= mOpDisp %> disponibles</div>
                </div>
                <a href="${pageContext.request.contextPath}/admin/operadores"
                   style="font-size:12px;color:var(--coral);text-decoration:none;font-weight:500">
                    Ver todos →
                </a>
            </div>
            <div class="op-lista">
                <% if (operadores == null || operadores.isEmpty()) { %>
                <div class="sin-datos">No hay operadores registrados.</div>
                <% } else { for (Object[] op : operadores) {
                    int disponible = (int) op[2];
                    String iniciales = "";
                    if (op[1] != null) {
                        String[] partes = op[1].toString().split(" ");
                        for (String p : partes) if (!p.isEmpty()) iniciales += p.charAt(0);
                        if (iniciales.length() > 2) iniciales = iniciales.substring(0,2);
                    }
                    String avClass  = disponible == 1 ? "av-disponible" : "av-ocupado";
                    String dotClass = disponible == 1 ? "dot-disp" : "dot-ocup";
                %>
                <div class="op-item">
                    <div class="op-avatar <%= avClass %>"><%= iniciales.toUpperCase() %></div>
                    <div class="op-info">
                        <div class="op-nombre"><%= op[1] %></div>
                        <div class="op-vehiculo"><%= op[4] != null ? op[4] : "Sin vehículo" %></div>
                    </div>
                    <div style="text-align:right;flex-shrink:0">
                        <div class="op-cal">★ <%= String.format("%.1f", op[3]) %></div>
                        <div style="display:flex;align-items:center;gap:4px;justify-content:flex-end;margin-top:4px">
                            <span class="op-estado-dot <%= dotClass %>"></span>
                            <span style="font-size:11px;color:var(--texto-3)"><%= disponible == 1 ? "Disponible" : "Ocupado" %></span>
                        </div>
                    </div>
                </div>
                <% } } %>
            </div>
        </div>
    </div>

    <!-- Historial reciente -->
    <div class="seccion">
        <div class="seccion-header">
            <div>
                <div class="seccion-titulo">Últimos viajes</div>
                <div class="seccion-sub">Los 10 más recientes del sistema</div>
            </div>
        </div>
        <% if (historial == null || historial.isEmpty()) { %>
        <div class="sin-datos">Aún no hay viajes registrados.</div>
        <% } else { %>
        <table class="tabla">
            <tr>
                <th>#</th><th>Estado</th><th>Pasajero</th><th>Operador</th>
                <th>Destino</th><th>Precio</th><th>Fecha</th>
            </tr>
            <% for (Object[] h : historial) {
                String estadoBadge = h[1].toString().toLowerCase().replace("_","-");
                String destCorto = h[6] != null && h[6].toString().length() > 35
                    ? h[6].toString().substring(0,35) + "…" : (h[6] != null ? h[6].toString() : "—");
            %>
            <tr>
                <td class="td-id">#<%= h[0] %></td>
                <td><span class="badge-estado be-<%= estadoBadge %>"><%= h[1].toString().replace("_"," ") %></span></td>
                <td><%= h[7] != null ? h[7] : "—" %></td>
                <td><%= h[8] != null ? h[8] : "—" %></td>
                <td class="td-truncate"><%= destCorto %></td>
                <td>$<%= String.format("%.2f", h[2]) %></td>
                <td style="white-space:nowrap"><%= h[3] != null ? sdf.format(h[3]) : "—" %></td>
            </tr>
            <% } %>
        </table>
        <% } %>
    </div>

</div>

<%-- Auto-refresh cada 15 segundos para mantener los datos actualizados --%>
<script>setTimeout(function(){ window.location.reload(); }, 15000);</script>

</body>
</html>
