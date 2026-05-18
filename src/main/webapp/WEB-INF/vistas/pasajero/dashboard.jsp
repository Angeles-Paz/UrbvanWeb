<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.sql.Timestamp, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Mi cuenta</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=DM+Mono:wght@400&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --verde: #1D9E75; --verde-dark: #0F6E56; --verde-light: #E1F5EE;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
            --amber: #BA7517; --amber-bg: #FAEEDA;
        }
        body { font-family: 'DM Sans', sans-serif; background: var(--fondo); min-height: 100vh; }

        /* ── Navbar ── */
        nav {
            background: var(--blanco); border-bottom: 1px solid var(--borde);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 32px; height: 56px; position: sticky; top: 0; z-index: 10;
        }
        .nav-logo { font-size: 18px; font-weight: 600; color: var(--verde-dark); }
        .nav-links { display: flex; align-items: center; gap: 8px; }
        .nav-link {
            font-size: 13px; color: var(--texto-2); text-decoration: none;
            padding: 6px 14px; border-radius: 20px; transition: background .15s, color .15s;
        }
        .nav-link:hover { background: var(--fondo); color: var(--texto); }
        .nav-link.activo { background: var(--verde-light); color: var(--verde-dark); font-weight: 500; }
        .btn-logout {
            font-size: 12px; color: var(--texto-3); text-decoration: none;
            padding: 5px 14px; border: 1px solid var(--borde); border-radius: 20px;
            margin-left: 8px; transition: color .15s, border-color .15s;
        }
        .btn-logout:hover { color: var(--error); border-color: var(--error); }

        /* ── Layout ── */
        .contenedor { max-width: 1100px; margin: 0 auto; padding: 32px 24px; }

        /* ── Bienvenida ── */
        .bienvenida { margin-bottom: 28px; }
        .bienvenida h1 { font-size: 26px; font-weight: 600; color: var(--texto); letter-spacing: -0.3px; }
        .bienvenida p  { font-size: 14px; color: var(--texto-2); margin-top: 4px; }

        /* ── Grid principal ── */
        .grid-principal { display: grid; grid-template-columns: 1fr 320px; gap: 24px; align-items: start; }

        /* ── Columna izquierda ── */
        .col-izq { display: flex; flex-direction: column; gap: 20px; }

        /* ── Tarjetas de contadores ── */
        .contadores { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
        .contador-card {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 14px; padding: 16px 20px;
        }
        .contador-label { font-size: 11px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 8px; }
        .contador-valor { font-size: 28px; font-weight: 600; color: var(--texto); line-height: 1; }
        .contador-sub   { font-size: 12px; color: var(--texto-3); margin-top: 4px; }
        .contador-card.verde .contador-valor { color: var(--verde); }

        /* ── Viaje activo ── */
        .viaje-activo-card {
            background: var(--verde-dark); border-radius: 16px; padding: 20px 24px;
            color: white;
        }
        .va-tag { font-size: 11px; font-weight: 500; letter-spacing: .08em; text-transform: uppercase; opacity: .6; margin-bottom: 12px; }
        .va-estado { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 500; background: rgba(255,255,255,.15); padding: 4px 12px; border-radius: 20px; margin-bottom: 14px; }
        .va-estado-dot { width: 7px; height: 7px; border-radius: 50%; background: #6ee7b7; animation: pulso 1.4s ease-in-out infinite; }
        @keyframes pulso { 0%,100%{opacity:1} 50%{opacity:.4} }
        .va-ruta { font-size: 14px; opacity: .9; line-height: 1.6; margin-bottom: 16px; }
        .va-ruta strong { display: block; font-size: 15px; font-weight: 500; opacity: 1; }
        .btn-seguir {
            display: inline-block; background: white; color: var(--verde-dark);
            font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 600;
            padding: 9px 20px; border-radius: 10px; text-decoration: none;
            border: none; cursor: pointer; transition: opacity .15s;
        }
        .btn-seguir:hover { opacity: .9; }

        /* Sin viaje activo */
        .sin-viaje {
            background: var(--blanco); border: 2px dashed var(--borde);
            border-radius: 16px; padding: 28px 24px; text-align: center;
        }
        .sin-viaje-icono { font-size: 32px; margin-bottom: 12px; }
        .sin-viaje h3 { font-size: 15px; font-weight: 600; color: var(--texto); margin-bottom: 6px; }
        .sin-viaje p  { font-size: 13px; color: var(--texto-2); margin-bottom: 18px; }
        .btn-solicitar {
            display: inline-block; background: var(--verde); color: white;
            font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500;
            padding: 11px 28px; border-radius: 10px; text-decoration: none;
            transition: background .15s;
        }
        .btn-solicitar:hover { background: var(--verde-dark); }

        /* ── Historial ── */
        .seccion-titulo { font-size: 14px; font-weight: 600; color: var(--texto); margin-bottom: 12px; }
        .historial-lista { display: flex; flex-direction: column; gap: 8px; }
        .historial-item {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 12px; padding: 14px 16px;
            display: grid; grid-template-columns: 1fr auto; gap: 12px; align-items: center;
        }
        .hi-ruta { font-size: 13px; color: var(--texto); font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .hi-sub  { font-size: 11px; color: var(--texto-3); margin-top: 3px; }
        .hi-derecha { text-align: right; flex-shrink: 0; }
        .hi-precio { font-size: 14px; font-weight: 600; color: var(--texto); }
        .hi-badge {
            display: inline-block; font-size: 10px; font-weight: 500;
            padding: 2px 8px; border-radius: 10px; margin-top: 4px;
        }
        .badge-completado { background: var(--verde-light); color: var(--verde-dark); }
        .badge-cancelado  { background: var(--error-bg);    color: var(--error); }
        .estrellas { color: #BA7517; font-size: 11px; margin-top: 2px; }

        .sin-historial { font-size: 13px; color: var(--texto-3); text-align: center; padding: 24px; }

        /* ── Columna derecha — perfil ── */
        .perfil-card {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 16px; overflow: hidden; position: sticky; top: 72px;
        }
        .perfil-header {
            background: var(--verde-light); padding: 24px 20px; text-align: center;
        }
        .perfil-avatar {
            width: 64px; height: 64px; border-radius: 50%;
            background: var(--verde); display: flex; align-items: center;
            justify-content: center; font-size: 22px; font-weight: 600;
            color: white; margin: 0 auto 12px;
        }
        .perfil-nombre { font-size: 16px; font-weight: 600; color: var(--verde-dark); }
        .perfil-correo { font-size: 12px; color: var(--verde); margin-top: 2px; }
        .perfil-body { padding: 16px 20px; }
        .perfil-campo { padding: 10px 0; border-bottom: 1px solid var(--borde); }
        .perfil-campo:last-child { border-bottom: none; }
        .perfil-campo-label { font-size: 10px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 3px; }
        .perfil-campo-valor { font-size: 13px; color: var(--texto); }
        .perfil-campo-valor.vacio { color: var(--texto-3); font-style: italic; }
        .btn-editar-perfil {
            display: block; width: 100%; margin-top: 16px; padding: 10px;
            background: var(--fondo); border: 1px solid var(--borde); border-radius: 10px;
            font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500;
            color: var(--texto-2); cursor: pointer; text-align: center;
            text-decoration: none; transition: background .15s;
        }
        .btn-editar-perfil:hover { background: var(--borde); }

        @media (max-width: 900px) {
            .grid-principal { grid-template-columns: 1fr; }
            .contadores { grid-template-columns: 1fr 1fr; }
            .perfil-card { position: static; }
        }
    </style>
</head>
<body>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");
    SimpleDateFormat sdfHora = new SimpleDateFormat("dd MMM yyyy, HH:mm");
    String nombre   = (String) request.getAttribute("u_nombre");
    String apellido = (String) request.getAttribute("u_apellido");
    String correo   = (String) request.getAttribute("u_correo");
    String telefono = (String) request.getAttribute("u_telefono");
    Timestamp registro = (Timestamp) request.getAttribute("u_registro");
    int cTotal      = request.getAttribute("c_total")      != null ? (int) request.getAttribute("c_total") : 0;
    int cCompletados= request.getAttribute("c_completados") != null ? (int) request.getAttribute("c_completados") : 0;
    double cGastado = request.getAttribute("c_gastado")    != null ? (double) request.getAttribute("c_gastado") : 0;
    mx.urbvan.modelo.Viaje viajeActivo = (mx.urbvan.modelo.Viaje) request.getAttribute("viaje_activo");
    List<Object[]> historial = (List<Object[]>) request.getAttribute("historial");
    String iniciales = "";
    if (nombre != null && !nombre.isEmpty()) iniciales += nombre.charAt(0);
    if (apellido != null && !apellido.isEmpty()) iniciales += apellido.charAt(0);
%>

<!-- Navbar -->
<nav>
    <span class="nav-logo">Urbvan</span>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/pasajero/dashboard" class="nav-link activo">Inicio</a>
        <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="nav-link">Nuevo viaje</a>
        <a href="${pageContext.request.contextPath}/pasajero/historial" class="nav-link">Mis viajes</a>
        <a href="${pageContext.request.contextPath}/logout" class="btn-logout">Cerrar sesión</a>
    </div>
</nav>

<div class="contenedor">

    <!-- Bienvenida -->
    <div class="bienvenida">
        <h1>Hola, <%= nombre != null ? nombre : "pasajero" %> 👋</h1>
        <p>Aquí tienes un resumen de tu actividad en Urbvan.</p>
    </div>

    <% if ("cancelado".equals(request.getParameter("viaje"))) { %>
    <div style="background:#FAECE7;border-radius:12px;padding:14px 20px;
            font-size:13px;color:#D85A30;margin-bottom:20px;
            display:flex;align-items:center;gap:8px;">
        Tu viaje fue cancelado correctamente.
    </div>
    <% } %>
    <% if ("completado".equals(request.getParameter("viaje"))) { %>
    <div style="background:#E1F5EE;border-radius:12px;padding:14px 20px;
            font-size:13px;color:#0F6E56;margin-bottom:20px;
            display:flex;align-items:center;gap:8px;">
        ¡Viaje completado! Gracias por viajar con Urbvan.
    </div>
    <% } %>

    <div class="grid-principal">
        <div class="col-izq">

            <!-- Contadores -->
            <div class="contadores">
                <div class="contador-card">
                    <div class="contador-label">Viajes totales</div>
                    <div class="contador-valor"><%= cTotal %></div>
                    <div class="contador-sub">desde que te uniste</div>
                </div>
                <div class="contador-card verde">
                    <div class="contador-label">Completados</div>
                    <div class="contador-valor"><%= cCompletados %></div>
                    <div class="contador-sub">viajes finalizados</div>
                </div>
                <div class="contador-card">
                    <div class="contador-label">Total gastado</div>
                    <div class="contador-valor" style="font-size:22px">
                        $<%= String.format("%.0f", cGastado) %>
                    </div>
                    <div class="contador-sub">pesos MXN</div>
                </div>
            </div>

            <!-- Viaje activo o botón de solicitar -->
            <% if (viajeActivo != null) { %>
            <div class="viaje-activo-card">
                <div class="va-tag">Viaje activo</div>
                <div class="va-estado">
                    <span class="va-estado-dot"></span>
                    <%= viajeActivo.getEstado().name().replace("_", " ") %>
                </div>
                <div class="va-ruta">
                    <strong><%= viajeActivo.getOrigenDireccion() != null ? viajeActivo.getOrigenDireccion() : "Origen" %></strong>
                    → <%= viajeActivo.getDestinoDireccion() != null ? viajeActivo.getDestinoDireccion() : "Destino" %>
                </div>
                <a href="${pageContext.request.contextPath}/pasajero/estado-viaje?id=<%= viajeActivo.getIdViaje() %>"
                   class="btn-seguir">Ver seguimiento →</a>
            </div>
            <% } else { %>
            <div class="sin-viaje">
                <div class="sin-viaje-icono">🚐</div>
                <h3>No tienes viajes activos</h3>
                <p>¿A dónde vas hoy? Solicita un viaje y un operador llegará a tu ubicación.</p>
                <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="btn-solicitar">
                    Solicitar un viaje
                </a>
            </div>
            <% } %>

            <!-- Historial reciente -->
            <div>
                <div class="seccion-titulo">Viajes recientes</div>
                <div class="historial-lista">
                    <% if (historial == null || historial.isEmpty()) { %>
                    <div class="sin-historial">Aún no tienes viajes registrados.</div>
                    <% } else {
                        for (Object[] h : historial) {
                            int    idV    = (int) h[0];
                            String origen = (String) h[1];
                            String dest   = (String) h[2];
                            double precio = (double) h[3];
                            String estado = (String) h[4];
                            Timestamp fecha = (Timestamp) h[5];
                            String operador = (String) h[7];
                            int puntuacion  = (int) h[8];
                            String origenCorto = origen != null && origen.length() > 35 ? origen.substring(0,35)+"…" : (origen != null ? origen : "—");
                            String destCorto   = dest   != null && dest.length()   > 35 ? dest.substring(0,35)+"…"   : (dest   != null ? dest   : "—");
                    %>
                    <div class="historial-item">
                        <div>
                            <div class="hi-ruta"><%= origenCorto %> → <%= destCorto %></div>
                            <div class="hi-sub">
                                <%= fecha != null ? sdfHora.format(fecha) : "—" %>
                                <% if (operador != null) { %> · <%= operador %><% } %>
                            </div>
                        </div>
                        <div class="hi-derecha">
                            <div class="hi-precio">$<%= String.format("%.2f", precio) %></div>
                            <% if ("COMPLETADO".equals(estado)) { %>
                                <span class="hi-badge badge-completado">Completado</span>
                                <% if (puntuacion > 0) { %>
                                <div class="estrellas">
                                    <% for (int s=1; s<=5; s++) { %><%= s <= puntuacion ? "★" : "☆" %><% } %>
                                </div>
                                <% } %>
                            <% } else { %>
                                <span class="hi-badge badge-cancelado">Cancelado</span>
                            <% } %>
                        </div>
                    </div>
                    <%  }
                    } %>
                </div>
                <% if (historial != null && !historial.isEmpty()) { %>
                <a href="${pageContext.request.contextPath}/pasajero/historial"
                   style="display:block;text-align:center;font-size:13px;color:var(--verde);
                          text-decoration:none;margin-top:12px;font-weight:500;">
                    Ver todos mis viajes →
                </a>
                <% } %>
            </div>

        </div>

        <!-- Columna derecha — Perfil -->
        <div>
            <div class="perfil-card">
                <div class="perfil-header">
                    <div class="perfil-avatar"><%= iniciales.toUpperCase() %></div>
                    <div class="perfil-nombre"><%= nombre %> <%= apellido %></div>
                    <div class="perfil-correo"><%= correo %></div>
                </div>
                <div class="perfil-body">
                    <div class="perfil-campo">
                        <div class="perfil-campo-label">Teléfono</div>
                        <div class="perfil-campo-valor <%= (telefono == null || telefono.isEmpty()) ? "vacio" : "" %>">
                            <%= (telefono != null && !telefono.isEmpty()) ? telefono : "No registrado" %>
                        </div>
                    </div>
                    <div class="perfil-campo">
                        <div class="perfil-campo-label">Miembro desde</div>
                        <div class="perfil-campo-valor">
                            <%= registro != null ? sdf.format(registro) : "—" %>
                        </div>
                    </div>
                    <div class="perfil-campo">
                        <div class="perfil-campo-label">Viajes completados</div>
                        <div class="perfil-campo-valor"><%= cCompletados %> viajes</div>
                    </div>
                    <a href="#" class="btn-editar-perfil">Editar perfil</a>
                </div>
            </div>
        </div>

    </div>
</div>

</body>
</html>
