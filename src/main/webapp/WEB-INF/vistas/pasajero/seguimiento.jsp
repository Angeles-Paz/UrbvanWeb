<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="mx.urbvan.modelo.Viaje, mx.urbvan.dao.ViajeDAO" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Seguimiento</title>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css"/>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --verde: #1D9E75; --verde-dark: #0F6E56; --verde-light: #E1F5EE;
            --purple: #534AB7; --purple-light: #EEEDFE;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
        }
        body {
            font-family: 'DM Sans', sans-serif; background: var(--fondo);
            height: 100vh; display: grid;
            grid-template-rows: 56px 1fr;
            grid-template-columns: 360px 1fr;
            grid-template-areas: "nav nav" "panel mapa";
        }
        nav {
            grid-area: nav; background: var(--blanco);
            border-bottom: 1px solid var(--borde);
            display: flex; align-items: center;
            justify-content: space-between; padding: 0 24px;
        }
        .nav-logo { font-size: 18px; font-weight: 600; color: var(--verde-dark); }
        .nav-right { display: flex; align-items: center; gap: 14px; font-size: 13px; color: var(--texto-2); }
        .nav-right strong { color: var(--texto); font-weight: 500; }
        .btn-nav { font-size: 12px; color: var(--texto-3); text-decoration: none; padding: 5px 12px; border: 1px solid var(--borde); border-radius: 20px; }
        .panel { grid-area: panel; background: var(--blanco); border-right: 1px solid var(--borde); display: flex; flex-direction: column; overflow-y: auto; }
        .eta-hero { padding: 24px; background: var(--verde-dark); color: white; text-align: center; }
        .eta-sub   { font-size: 11px; font-weight: 500; letter-spacing: .08em; text-transform: uppercase; opacity: .6; margin-bottom: 6px; }
        .eta-valor { font-size: 48px; font-weight: 600; line-height: 1; margin-bottom: 4px; }
        .eta-desc  { font-size: 12px; opacity: .7; }
        .estado-actual { padding: 16px 20px; border-bottom: 1px solid var(--borde); display: flex; align-items: center; gap: 12px; }
        .estado-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; background: var(--verde); animation: pulso 1.4s ease-in-out infinite; }
        @keyframes pulso { 0%,100%{opacity:1}50%{opacity:.3} }
        .estado-texto { font-size: 14px; font-weight: 600; color: var(--texto); }
        .estado-desc  { font-size: 12px; color: var(--texto-2); margin-top: 2px; }
        .timeline { padding: 20px; border-bottom: 1px solid var(--borde); }
        .timeline-step { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 16px; position: relative; }
        .timeline-step:last-child { margin-bottom: 0; }
        .timeline-step::before { content: ''; position: absolute; left: 11px; top: 24px; width: 2px; height: calc(100% + 8px); background: var(--borde); z-index: 0; }
        .timeline-step:last-child::before { display: none; }
        .step-circulo { width: 24px; height: 24px; border-radius: 50%; flex-shrink: 0; border: 2px solid var(--borde); background: var(--blanco); display: flex; align-items: center; justify-content: center; font-size: 10px; font-weight: 600; color: var(--texto-3); position: relative; z-index: 1; }
        .timeline-step.activo .step-circulo { border-color: var(--verde); background: var(--verde); color: white; }
        .timeline-step.hecho  .step-circulo { border-color: var(--verde); background: var(--verde-light); color: var(--verde); }
        .step-label { font-size: 13px; font-weight: 500; color: var(--texto-3); padding-top: 2px; }
        .timeline-step.activo .step-label, .timeline-step.hecho .step-label { color: var(--texto); }
        .step-sub { font-size: 11px; color: var(--texto-3); margin-top: 1px; }
        .info-viaje { padding: 16px 20px; border-bottom: 1px solid var(--borde); }
        .info-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 12px; }
        .info-fila { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 10px; }
        .info-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
        .dot-origen  { background: var(--verde); }
        .dot-destino { background: var(--error); }
        .info-texto { font-size: 12px; color: var(--texto-2); line-height: 1.4; }
        .info-operador { padding: 14px 20px; background: var(--purple-light); border-bottom: 1px solid var(--borde); display: none; }
        .info-operador.visible { display: block; }
        .op-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--purple); margin-bottom: 10px; }
        .op-fila { display: flex; justify-content: space-between; font-size: 12px; color: var(--texto-2); margin-bottom: 6px; }
        .op-fila strong { color: var(--texto); font-weight: 500; }
        .acciones { padding: 16px 20px; margin-top: auto; }
        .btn-cancelar { width: 100%; padding: 11px; background: transparent; color: var(--error); border: 1px solid rgba(216,90,48,.3); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; cursor: pointer; margin-bottom: 8px; }
        .btn-cancelar:hover { background: var(--error-bg); }
        .btn-calificar { display: none; width: 100%; padding: 13px; background: var(--verde); color: white; border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 600; cursor: pointer; text-align: center; }
        .btn-calificar:hover { background: var(--verde-dark); }
        .leyenda { position: absolute; bottom: 24px; left: 376px; background: var(--blanco); border: 1px solid var(--borde); border-radius: 10px; padding: 10px 14px; z-index: 5; display: flex; gap: 16px; }
        .leyenda-item { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--texto-2); }
        .leyenda-dot  { width: 10px; height: 10px; border-radius: 50%; }
        #mapa-seguimiento { grid-area: mapa; width: 100%; height: 100%; position: relative; }
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 100; align-items: center; justify-content: center; }
        .modal-overlay.visible { display: flex; }
        .modal { background: var(--blanco); border-radius: 20px; padding: 32px; width: 100%; max-width: 380px; text-align: center; }
        .modal h3 { font-size: 20px; font-weight: 600; color: var(--texto); margin-bottom: 8px; }
        .modal p  { font-size: 14px; color: var(--texto-2); margin-bottom: 24px; }
        .estrellas-input { display: flex; justify-content: center; gap: 8px; margin-bottom: 20px; }
        .estrella { font-size: 32px; cursor: pointer; color: var(--borde); transition: color .1s; user-select: none; }
        .estrella.on { color: #BA7517; }
        .modal textarea { width: 100%; padding: 10px 14px; border: 1.5px solid var(--borde); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; resize: none; outline: none; margin-bottom: 16px; height: 80px; }
        .modal textarea:focus { border-color: var(--verde); }
        .btn-enviar-cal { width: 100%; padding: 13px; background: var(--verde); color: white; border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 600; cursor: pointer; }
        .btn-saltar { display: block; margin-top: 12px; font-size: 13px; color: var(--texto-3); cursor: pointer; background: none; border: none; width: 100%; }
    </style>
</head>
<body>
<%
    String idStr = (String) request.getAttribute("id_viaje");
    if (idStr == null) idStr = request.getParameter("id");
    Viaje viaje = null;
    String nombreOp = "—", telefonoOp = "—", vehiculoOp = "—", placaOp = "—";
    try {
        viaje = new ViajeDAO().buscarPorId(Integer.parseInt(idStr));
        if (viaje != null && viaje.getIdOperador() > 0) {
            java.sql.Connection conn = mx.urbvan.dao.ConexionDB.obtener();
            java.sql.PreparedStatement ps = conn.prepareStatement(
                "SELECT CONCAT(o.nombre,' ',o.apellido) AS nombre, o.telefono, " +
                "CONCAT(v.marca,' ',v.modelo) AS vehiculo, v.placa " +
                "FROM operadores o LEFT JOIN vehiculos v ON v.id_vehiculo = o.id_vehiculo " +
                "WHERE o.id_operador = ?");
            ps.setInt(1, viaje.getIdOperador());
            java.sql.ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                nombreOp   = rs.getString("nombre");
                telefonoOp = rs.getString("telefono") != null ? rs.getString("telefono") : "—";
                vehiculoOp = rs.getString("vehiculo") != null ? rs.getString("vehiculo") : "—";
                placaOp    = rs.getString("placa")    != null ? rs.getString("placa")    : "—";
            }
            conn.close();
        }
    } catch (Exception e) { }
    if (viaje == null) { response.sendRedirect(request.getContextPath() + "/pasajero/dashboard"); return; }
%>
<nav>
    <span class="nav-logo">Urbvan</span>
    <div class="nav-right">
        Hola, <strong>${sessionScope.nombre}</strong>
        <a href="${pageContext.request.contextPath}/pasajero/dashboard" class="btn-nav">Mi cuenta</a>
    </div>
</nav>
<div class="panel">
    <div class="eta-hero">
        <div class="eta-sub" id="eta-sub">Buscando operador</div>
        <div class="eta-valor" id="eta-valor">...</div>
        <div class="eta-desc">minutos estimados</div>
    </div>
    <div class="estado-actual">
        <div class="estado-dot"></div>
        <div>
            <div class="estado-texto" id="estado-texto">Buscando operador</div>
            <div class="estado-desc"  id="estado-desc">Estamos asignando el operador más cercano.</div>
        </div>
    </div>
    <div class="timeline">
        <div class="timeline-step activo">
            <div class="step-circulo">1</div>
            <div><div class="step-label">Asignando operador</div><div class="step-sub">Se busca al más cercano</div></div>
        </div>
        <div class="timeline-step">
            <div class="step-circulo">2</div>
            <div><div class="step-label">Operador en camino</div><div class="step-sub">Dirigiéndose a tu origen</div></div>
        </div>
        <div class="timeline-step">
            <div class="step-circulo">3</div>
            <div><div class="step-label">Viaje en curso</div><div class="step-sub">En ruta al destino</div></div>
        </div>
        <div class="timeline-step">
            <div class="step-circulo">✓</div>
            <div><div class="step-label">Completado</div><div class="step-sub">Llegaste a tu destino</div></div>
        </div>
    </div>
    <div class="info-viaje">
        <div class="info-titulo">Tu ruta</div>
        <div class="info-fila"><span class="info-dot dot-origen"></span><span class="info-texto"><%= viaje.getOrigenDireccion() != null ? viaje.getOrigenDireccion() : "Origen" %></span></div>
        <div class="info-fila"><span class="info-dot dot-destino"></span><span class="info-texto"><%= viaje.getDestinoDireccion() != null ? viaje.getDestinoDireccion() : "Destino" %></span></div>
    </div>
    <div class="info-operador <%= viaje.getIdOperador() > 0 ? "visible" : "" %>" id="info-operador">
        <div class="op-titulo">Tu operador</div>
        <div class="op-fila"><span>Nombre</span><strong><%= nombreOp %></strong></div>
        <div class="op-fila"><span>Teléfono</span><strong><%= telefonoOp %></strong></div>
        <div class="op-fila"><span>Vehículo</span><strong><%= vehiculoOp %></strong></div>
        <div class="op-fila"><span>Placa</span><strong><%= placaOp %></strong></div>
    </div>
    <div class="acciones">
        <% if (viaje.getEstado() == mx.urbvan.modelo.Viaje.Estado.EN_ASIGNACION ||
               viaje.getEstado() == mx.urbvan.modelo.Viaje.Estado.ACEPTADO) { %>
        <button type="button" class="btn-cancelar" onclick="abrirModalCancelar()">
            Cancelar viaje
        </button>
        <% } %>
        <button id="btn-calificar" class="btn-calificar" onclick="abrirCalificacion()">
            Calificar al operador ★
        </button>
    </div>
</div>

<div id="mapa-seguimiento"></div>

<div class="leyenda">
    <div class="leyenda-item"><div class="leyenda-dot" style="background:#1D9E75"></div>Tu ubicación</div>
    <div class="leyenda-item"><div class="leyenda-dot" style="background:#534AB7"></div>Operador</div>
    <div class="leyenda-item"><div class="leyenda-dot" style="background:#D85A30"></div>Destino</div>
</div>

<div class="modal-overlay" id="modal-cal">
    <div class="modal">
        <h3>¿Cómo fue tu viaje?</h3>
        <p>Califica al operador <strong><%= nombreOp %></strong></p>
        <div class="estrellas-input">
            <span class="estrella" onclick="calificar(1)">★</span>
            <span class="estrella" onclick="calificar(2)">★</span>
            <span class="estrella" onclick="calificar(3)">★</span>
            <span class="estrella" onclick="calificar(4)">★</span>
            <span class="estrella" onclick="calificar(5)">★</span>
        </div>
        <textarea id="comentario-cal" placeholder="Comentario opcional..."></textarea>
        <form method="POST" action="${pageContext.request.contextPath}/pasajero/calificar" id="form-cal">
            <input type="hidden" name="id_viaje"    value="<%= viaje.getIdViaje() %>">
            <input type="hidden" name="id_operador" value="<%= viaje.getIdOperador() %>">
            <input type="hidden" name="puntuacion"  id="puntuacion-input" value="0">
            <input type="hidden" name="comentario"  id="comentario-input" value="">
            <button type="submit" class="btn-enviar-cal">Enviar calificación</button>
        </form>
        <button class="btn-saltar" onclick="saltar()">Saltar por ahora</button>
    </div>
</div>

<script>
    var AZURE_KEY   = '1iXcaVW3TPpFb16nqn0fOdmUzXa9PTEIUz67L6z8IhMUGCgC3CazJQQJ99CEAC8vTInh3jNvAAAgAZMPPoqn';
    var CTX_PATH    = '${pageContext.request.contextPath}';
    var ID_VIAJE    = <%= viaje.getIdViaje() %>;
    var ORIGEN_LAT  = <%= viaje.getOrigenLat() %>;
    var ORIGEN_LNG  = <%= viaje.getOrigenLng() %>;
    var DESTINO_LAT = <%= viaje.getDestinoLat() %>;
    var DESTINO_LNG = <%= viaje.getDestinoLng() %>;
</script>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/seguimiento.js"></script>
<script>
    function abrirCalificacion() {
        document.getElementById('modal-cal').classList.add('visible');
    }
    function calificar(n) {
        document.querySelectorAll('.estrella').forEach(function(el,i){ el.classList.toggle('on', i < n); });
        document.getElementById('puntuacion-input').value = n;
    }
    function saltar() {
        document.getElementById('modal-cal').classList.remove('visible');
        window.location.href = CTX_PATH + '/pasajero/dashboard';
    }
    document.getElementById('form-cal').addEventListener('submit', function() {
        document.getElementById('comentario-input').value = document.getElementById('comentario-cal').value;
    });
</script>
<!-- Modal cancelación -->
<div class="modal-overlay" id="modal-cancelar">
    <div class="modal" style="text-align:left">
        <div style="display:flex;align-items:center;gap:12px;margin-bottom:16px">
            <div style="width:44px;height:44px;border-radius:50%;background:var(--error-bg);
                        display:flex;align-items:center;justify-content:center;flex-shrink:0">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
                     stroke="#D85A30" stroke-width="2.5" stroke-linecap="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="15" y1="9" x2="9" y2="15"/>
                    <line x1="9" y1="9" x2="15" y2="15"/>
                </svg>
            </div>
            <div>
                <div style="font-size:16px;font-weight:600;color:var(--texto)">Cancelar viaje</div>
                <div style="font-size:13px;color:var(--texto-2);margin-top:2px">Esta acción no se puede deshacer</div>
            </div>
        </div>
        <p style="font-size:13px;color:var(--texto-2);line-height:1.6;margin-bottom:20px;
                  background:var(--error-bg);padding:12px 14px;border-radius:10px;color:var(--error)">
            Si cancelas el viaje se liberará al operador asignado y
            el pago quedará marcado como cancelado.
        </p>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
            <button onclick="cerrarModalCancelar()"
                style="padding:12px;border-radius:10px;border:1.5px solid var(--borde);
                       background:transparent;font-family:'DM Sans',sans-serif;
                       font-size:14px;font-weight:500;color:var(--texto-2);cursor:pointer">
                Mantener viaje
            </button>
            <form method="POST" action="${pageContext.request.contextPath}/pasajero/cancelar">
                <input type="hidden" name="id_viaje" value="<%= viaje.getIdViaje() %>">
                <button type="submit"
                    style="width:100%;padding:12px;border-radius:10px;border:none;
                           background:var(--error);color:white;
                           font-family:'DM Sans',sans-serif;font-size:14px;
                           font-weight:600;cursor:pointer">
                    Sí, cancelar
                </button>
            </form>
        </div>
    </div>
</div>

<script>
    function abrirModalCancelar() {
        document.getElementById('modal-cancelar').classList.add('visible');
    }
    function cerrarModalCancelar() {
        document.getElementById('modal-cancelar').classList.remove('visible');
    }
    // Cerrar modal al hacer clic fuera
    document.getElementById('modal-cancelar').addEventListener('click', function(e) {
        if (e.target === this) cerrarModalCancelar();
    });
</script>

</body>
</html>
