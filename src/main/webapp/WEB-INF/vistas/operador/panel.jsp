<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.Timestamp, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Panel Operador</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --verde: #1D9E75; --verde-dark: #0F6E56; --verde-light: #E1F5EE;
            --purple: #534AB7; --purple-light: #EEEDFE;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
            --amber: #BA7517; --amber-bg: #FAEEDA;
        }
        body { font-family: 'DM Sans', sans-serif; background: var(--fondo); min-height: 100vh; }
        nav {
            background: var(--purple); border-bottom: 1px solid rgba(255,255,255,.1);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 32px; height: 56px;
        }
        .nav-logo { font-size: 18px; font-weight: 600; color: white; }
        .nav-badge { font-size: 11px; background: rgba(255,255,255,.15); color: white; padding: 3px 10px; border-radius: 20px; margin-left: 8px; }
        .nav-right { display: flex; align-items: center; gap: 12px; }
        .nav-nombre { font-size: 13px; color: rgba(255,255,255,.8); }
        .btn-logout { font-size: 12px; color: rgba(255,255,255,.6); text-decoration: none; padding: 5px 12px; border: 1px solid rgba(255,255,255,.2); border-radius: 20px; }
        .btn-logout:hover { color: white; border-color: rgba(255,255,255,.5); }

        .contenedor { max-width: 1000px; margin: 0 auto; padding: 32px 24px; }

        /* Alertas */
        .alerta { border-radius: 12px; padding: 14px 18px; font-size: 13px; margin-bottom: 20px; display: flex; align-items: center; gap: 10px; }
        .alerta-sol  { background: var(--amber-bg); color: var(--amber); border: 1px solid rgba(186,117,23,.2); }
        .alerta-ok   { background: var(--verde-light); color: var(--verde-dark); border: 1px solid rgba(29,158,117,.2); }
        .alerta-err  { background: var(--error-bg); color: var(--error); border: 1px solid rgba(216,90,48,.2); }

        /* Grid principal */
        .grid { display: grid; grid-template-columns: 1fr 300px; gap: 24px; align-items: start; }

        /* Disponibilidad */
        .disponibilidad-card {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 16px; padding: 24px; margin-bottom: 20px;
        }
        .disp-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
        .disp-titulo { font-size: 16px; font-weight: 600; color: var(--texto); }
        .disp-desc   { font-size: 13px; color: var(--texto-2); margin-bottom: 20px; }
        .toggle-wrap { display: flex; gap: 10px; }
        .btn-disp {
            flex: 1; padding: 12px; border-radius: 12px; border: 2px solid var(--borde);
            font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500;
            cursor: pointer; transition: all .15s; background: var(--blanco); color: var(--texto-2);
        }
        .btn-disp.disponible  { background: var(--verde-light); color: var(--verde-dark); border-color: var(--verde); }
        .btn-disp.ocupado     { background: var(--error-bg);    color: var(--error);      border-color: var(--error); }
        .indicador {
            width: 12px; height: 12px; border-radius: 50%; display: inline-block; margin-right: 6px;
        }
        .ind-verde { background: var(--verde); animation: pulso 1.4s ease-in-out infinite; }
        .ind-gris  { background: var(--texto-3); }
        @keyframes pulso { 0%,100%{opacity:1}50%{opacity:.3} }

        /* Solicitud pendiente */
        .solicitud-card {
            background: var(--blanco); border: 2px solid var(--amber);
            border-radius: 16px; overflow: hidden; margin-bottom: 20px;
        }
        .sol-header { background: var(--amber-bg); padding: 14px 20px; display: flex; align-items: center; justify-content: space-between; }
        .sol-titulo { font-size: 14px; font-weight: 600; color: var(--amber); }
        .sol-timer  { font-size: 13px; font-weight: 600; color: var(--amber); font-family: monospace; }
        .sol-body   { padding: 20px; }
        .sol-fila   { display: flex; justify-content: space-between; font-size: 13px; color: var(--texto-2); margin-bottom: 10px; }
        .sol-fila strong { color: var(--texto); font-weight: 500; }
        .sol-ruta { margin: 14px 0; padding: 14px; background: var(--fondo); border-radius: 10px; }
        .sol-ruta-item { display: flex; align-items: flex-start; gap: 8px; margin-bottom: 8px; font-size: 13px; color: var(--texto-2); }
        .sol-ruta-item:last-child { margin-bottom: 0; }
        .ruta-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
        .dot-v { background: var(--verde); }
        .dot-r { background: var(--error); }
        .sol-acciones { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 16px; }
        .btn-aceptar {
            padding: 13px; background: var(--verde); color: white; border: none;
            border-radius: 10px; font-family: 'DM Sans', sans-serif;
            font-size: 14px; font-weight: 600; cursor: pointer; transition: background .15s;
        }
        .btn-aceptar:hover { background: var(--verde-dark); }
        .btn-rechazar {
            padding: 13px; background: transparent; color: var(--error);
            border: 1.5px solid rgba(216,90,48,.3); border-radius: 10px;
            font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500;
            cursor: pointer; transition: background .15s;
        }
        .btn-rechazar:hover { background: var(--error-bg); }

        /* Viaje activo */
        .viaje-activo-card {
            background: var(--purple); border-radius: 16px;
            padding: 20px 24px; color: white; margin-bottom: 20px;
        }
        .va-tag   { font-size: 11px; font-weight: 500; letter-spacing: .08em; text-transform: uppercase; opacity: .6; margin-bottom: 10px; }
        .va-estado{ display: inline-flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 500; background: rgba(255,255,255,.15); padding: 4px 12px; border-radius: 20px; margin-bottom: 14px; }
        .va-dot   { width: 7px; height: 7px; border-radius: 50%; background: #a5b4fc; animation: pulso 1.4s ease-in-out infinite; }
        .va-ruta  { font-size: 13px; opacity: .85; line-height: 1.6; margin-bottom: 14px; }
        .va-ruta strong { display: block; font-size: 14px; opacity: 1; font-weight: 500; }
        .btn-ver-viaje {
            display: inline-block; background: white; color: var(--purple);
            font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 600;
            padding: 9px 20px; border-radius: 10px; text-decoration: none;
            border: none; cursor: pointer;
        }

        /* Sin actividad */
        .sin-actividad {
            background: var(--blanco); border: 2px dashed var(--borde);
            border-radius: 16px; padding: 40px 24px; text-align: center;
            margin-bottom: 20px;
        }
        .sin-actividad h3 { font-size: 15px; font-weight: 600; color: var(--texto); margin-bottom: 6px; }
        .sin-actividad p  { font-size: 13px; color: var(--texto-2); }

        /* Contadores */
        .contadores { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; margin-bottom: 20px; }
        .contador-card { background: var(--blanco); border: 1px solid var(--borde); border-radius: 12px; padding: 14px 16px; }
        .c-label { font-size: 10px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 6px; }
        .c-valor { font-size: 24px; font-weight: 600; color: var(--texto); }
        .c-valor.morado { color: var(--purple); }

        /* Panel derecho — perfil */
        .perfil-card { background: var(--blanco); border: 1px solid var(--borde); border-radius: 16px; overflow: hidden; position: sticky; top: 24px; }
        .perfil-header { background: var(--purple-light); padding: 20px; text-align: center; }
        .perfil-avatar { width: 56px; height: 56px; border-radius: 50%; background: var(--purple); display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 600; color: white; margin: 0 auto 10px; }
        .perfil-nombre { font-size: 15px; font-weight: 600; color: var(--purple); }
        .perfil-cal    { font-size: 13px; color: var(--amber); margin-top: 4px; }
        .perfil-body   { padding: 14px 18px; }
        .perfil-fila   { display: flex; justify-content: space-between; font-size: 12px; padding: 8px 0; border-bottom: 1px solid var(--borde); }
        .perfil-fila:last-child { border-bottom: none; }
        .perfil-fila span { color: var(--texto-3); }
        .perfil-fila strong { color: var(--texto); font-weight: 500; }

        @media (max-width: 780px) {
            .grid { grid-template-columns: 1fr; }
            .perfil-card { position: static; }
            .contadores { grid-template-columns: 1fr 1fr; }
        }
    </style>
</head>
<body>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
    int disponible     = request.getAttribute("op_disponible") != null ? (int) request.getAttribute("op_disponible") : 0;
    double calificacion= request.getAttribute("op_calificacion") != null ? (double)request.getAttribute("op_calificacion") : 5.0;
    int cTotal         = request.getAttribute("c_total")       != null ? (int)request.getAttribute("c_total") : 0;
    int cCompletados   = request.getAttribute("c_completados") != null ? (int)request.getAttribute("c_completados") : 0;
    mx.urbvan.modelo.Viaje viajeActivo = (mx.urbvan.modelo.Viaje) request.getAttribute("viaje_activo");
    String opNombre  = (String) request.getAttribute("op_nombre");
    String opApellido= (String) request.getAttribute("op_apellido");
    String iniciales = "";
    if (opNombre != null && !opNombre.isEmpty())   iniciales += opNombre.charAt(0);
    if (opApellido != null && !opApellido.isEmpty()) iniciales += opApellido.charAt(0);
    String solOrigen  = (String) request.getAttribute("sol_origen");
    String solDestino = (String) request.getAttribute("sol_destino");
    Integer solId     = (Integer) request.getAttribute("sol_id");
    Integer solViajeId= (Integer) request.getAttribute("sol_viaje_id");
    String estrellas  = "";
    int cal = (int) Math.round(calificacion);
    for (int i = 1; i <= 5; i++) estrellas += i <= cal ? "★" : "☆";
%>

<nav>
    <div>
        <span class="nav-logo">Urbvan</span>
        <span class="nav-badge">Operador</span>
    </div>
    <div class="nav-right">
        <span class="nav-nombre"><%= opNombre %> <%= opApellido %></span>
        <a href="${pageContext.request.contextPath}/logout" class="btn-logout">Salir</a>
    </div>
</nav>

<div class="contenedor">

    <%-- Alertas de estado --%>
    <% if ("completado".equals(request.getParameter("viaje"))) { %>
    <div class="alerta alerta-ok">Viaje completado exitosamente. ¡Buen trabajo!</div>
    <% } %>
    <% if ("rechazada".equals(request.getParameter("solicitud"))) { %>
    <div class="alerta alerta-err">Solicitud rechazada. Sigues disponible para nuevas asignaciones.</div>
    <% } %>

    <div class="grid">
        <div>

            <!-- Disponibilidad -->
            <div class="disponibilidad-card">
                <div class="disp-header">
                    <div class="disp-titulo">
                        <span class="indicador <%= disponible == 1 ? "ind-verde" : "ind-gris" %>"></span>
                        Estado actual: <%= disponible == 1 ? "Disponible" : "No disponible" %>
                    </div>
                </div>
                <div class="disp-desc">
                    <%= disponible == 1
                        ? "Estás recibiendo solicitudes de viaje. Puedes cambiar tu estado cuando lo necesites."
                        : "No estás recibiendo solicitudes. Actívate cuando estés listo para trabajar." %>
                </div>
                <div class="toggle-wrap">
                    <form method="POST" action="${pageContext.request.contextPath}/operador/panel">
                        <input type="hidden" name="accion" value="disponibilidad">
                        <input type="hidden" name="disponible" value="1">
                        <button type="submit" class="btn-disp <%= disponible == 1 ? "disponible" : "" %>">
                            Activarme
                        </button>
                    </form>
                    <form method="POST" action="${pageContext.request.contextPath}/operador/panel">
                        <input type="hidden" name="accion" value="disponibilidad">
                        <input type="hidden" name="disponible" value="0">
                        <button type="submit" class="btn-disp <%= disponible == 0 ? "ocupado" : "" %>">
                            Desactivarme
                        </button>
                    </form>
                </div>
            </div>

            <!-- Solicitud pendiente -->
            <% if (solId != null) { %>
            <div class="solicitud-card">
                <div class="sol-header">
                    <span class="sol-titulo">Nueva solicitud de viaje</span>
                    <span class="sol-timer" id="timer">00:30</span>
                </div>
                <div class="sol-body">
                    <div class="sol-fila"><span>Pasajero</span><strong><%= request.getAttribute("sol_pasajero") %></strong></div>
                    <div class="sol-fila"><span>Distancia</span><strong><%= String.format("%.1f", request.getAttribute("sol_distancia")) %> km</strong></div>
                    <div class="sol-fila"><span>Tiempo de viaje</span><strong><%= request.getAttribute("sol_eta") %> min</strong></div>
                    <div class="sol-fila"><span>Cobro al pasajero</span><strong>$<%= String.format("%.2f", request.getAttribute("sol_precio")) %></strong></div>
                    <div class="sol-ruta">
                        <div class="sol-ruta-item"><span class="ruta-dot dot-v"></span><span><%= solOrigen != null ? solOrigen : "—" %></span></div>
                        <div class="sol-ruta-item"><span class="ruta-dot dot-r"></span><span><%= solDestino != null ? solDestino : "—" %></span></div>
                    </div>
                    <div class="sol-acciones">
                        <form method="POST" action="${pageContext.request.contextPath}/operador/responder">
                            <input type="hidden" name="id_solicitud" value="<%= solId %>">
                            <input type="hidden" name="id_viaje"     value="<%= solViajeId %>">
                            <input type="hidden" name="respuesta"    value="ACEPTAR">
                            <button type="submit" class="btn-aceptar" style="width:100%">Aceptar viaje</button>
                        </form>
                        <form method="POST" action="${pageContext.request.contextPath}/operador/responder">
                            <input type="hidden" name="id_solicitud" value="<%= solId %>">
                            <input type="hidden" name="id_viaje"     value="<%= solViajeId %>">
                            <input type="hidden" name="respuesta"    value="RECHAZAR">
                            <button type="submit" class="btn-rechazar" style="width:100%">Rechazar</button>
                        </form>
                    </div>
                </div>
            </div>
            <% } else if (viajeActivo != null) { %>

            <!-- Viaje activo -->
            <div class="viaje-activo-card">
                <div class="va-tag">Viaje en curso</div>
                <div class="va-estado"><span class="va-dot"></span><%= viajeActivo.getEstado().name().replace("_"," ") %></div>
                <div class="va-ruta">
                    <strong><%= viajeActivo.getOrigenDireccion() != null ? viajeActivo.getOrigenDireccion() : "Origen" %></strong>
                    → <%= viajeActivo.getDestinoDireccion() != null ? viajeActivo.getDestinoDireccion() : "Destino" %>
                </div>
                <a href="${pageContext.request.contextPath}/operador/viaje-activo?id=<%= viajeActivo.getIdViaje() %>"
                   class="btn-ver-viaje">Ver mapa del viaje →</a>
            </div>

            <% } else { %>
            <!-- Sin actividad -->
            <div class="sin-actividad">
                <div style="font-size:40px;margin-bottom:12px">🚐</div>
                <h3><%= disponible == 1 ? "Esperando solicitudes..." : "No estás activo" %></h3>
                <p><%= disponible == 1
                    ? "Cuando un pasajero solicite un viaje cerca de ti, aparecerá aquí."
                    : "Actívate para comenzar a recibir viajes." %></p>
            </div>
            <% } %>

            <!-- Contadores -->
            <div class="contadores">
                <div class="contador-card">
                    <div class="c-label">Total viajes</div>
                    <div class="c-valor"><%= cTotal %></div>
                </div>
                <div class="contador-card">
                    <div class="c-label">Completados</div>
                    <div class="c-valor morado"><%= cCompletados %></div>
                </div>
                <div class="contador-card">
                    <div class="c-label">Calificación</div>
                    <div class="c-valor" style="font-size:18px;color:#BA7517"><%= String.format("%.1f", calificacion) %> ★</div>
                </div>
            </div>

        </div>

        <!-- Panel derecho — perfil -->
        <div>
            <div class="perfil-card">
                <div class="perfil-header">
                    <div class="perfil-avatar"><%= iniciales.toUpperCase() %></div>
                    <div class="perfil-nombre"><%= opNombre %> <%= opApellido %></div>
                    <div class="perfil-cal"><%= estrellas %> <%= String.format("%.1f", calificacion) %></div>
                </div>
                <div class="perfil-body">
                    <div class="perfil-fila"><span>Correo</span><strong><%= request.getAttribute("op_correo") %></strong></div>
                    <div class="perfil-fila"><span>Teléfono</span><strong><%= request.getAttribute("op_telefono") != null ? request.getAttribute("op_telefono") : "—" %></strong></div>
                    <div class="perfil-fila"><span>Vehículo</span><strong><%= request.getAttribute("veh_marca") %> <%= request.getAttribute("veh_modelo") %></strong></div>
                    <div class="perfil-fila"><span>Placa</span><strong><%= request.getAttribute("veh_placa") != null ? request.getAttribute("veh_placa") : "—" %></strong></div>
                    <div class="perfil-fila"><span>Color</span><strong><%= request.getAttribute("veh_color") != null ? request.getAttribute("veh_color") : "—" %></strong></div>
                    <div class="perfil-fila"><span>Capacidad</span><strong><%= request.getAttribute("veh_capacidad") %> pasajeros</strong></div>
                </div>
            </div>
        </div>

    </div>
</div>

<% if (solId != null) { %>
<script>
    var segundos = 30;
    var timer = setInterval(function() {
        segundos--;
        var s = segundos < 10 ? '0' + segundos : segundos;
        document.getElementById('timer').textContent = '00:' + s;
        if (segundos <= 0) {
            clearInterval(timer);
            window.location.reload();
        }
    }, 1000);
</script>
<% } %>

<%-- Auto-refresh cada 8 segundos siempre que no haya solicitud pendiente activa --%>
<%-- Cubre: esperando viaje, viaje activo (para detectar cancelaciones del pasajero) --%>
<% if (solId == null) { %>
<script>
    setTimeout(function() { window.location.reload(); }, 8000);
</script>
<% } %>

</body>
</html>
