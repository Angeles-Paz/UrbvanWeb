<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="mx.urbvan.modelo.Viaje" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Viaje activo</title>
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
            --amber: #BA7517; --amber-bg: #FAEEDA;
        }
        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--fondo); height: 100vh;
            display: grid;
            grid-template-rows: 56px 1fr;
            grid-template-columns: 340px 1fr;
            grid-template-areas: "nav nav" "panel mapa";
        }
        nav {
            grid-area: nav; background: var(--purple);
            display: flex; align-items: center;
            justify-content: space-between; padding: 0 24px;
        }
        .nav-logo  { font-size: 18px; font-weight: 600; color: white; }
        .nav-right { display: flex; align-items: center; gap: 12px; }
        .nav-nombre{ font-size: 13px; color: rgba(255,255,255,.8); }
        .btn-panel { font-size: 12px; color: rgba(255,255,255,.7); text-decoration: none;
                     padding: 5px 12px; border: 1px solid rgba(255,255,255,.2); border-radius: 20px; }
        .btn-panel:hover { color: white; border-color: rgba(255,255,255,.5); }

        /* ── Panel lateral ── */
        .panel {
            grid-area: panel; background: var(--blanco);
            border-right: 1px solid var(--borde);
            display: flex; flex-direction: column; overflow-y: auto;
        }

        /* Estado hero */
        .estado-hero {
            padding: 20px 24px; color: white; text-align: center;
        }
        .eh-aceptado        { background: var(--purple); }
        .eh-operador_en_camino { background: #7C3AED; }
        .eh-viaje_iniciado  { background: var(--verde-dark); }

        .eh-tag   { font-size: 11px; font-weight: 500; letter-spacing: .08em;
                    text-transform: uppercase; opacity: .65; margin-bottom: 8px; }
        .eh-icono { font-size: 36px; margin-bottom: 8px; }
        .eh-titulo{ font-size: 18px; font-weight: 600; margin-bottom: 4px; }
        .eh-desc  { font-size: 12px; opacity: .75; line-height: 1.5; }

        /* Ruta */
        .seccion { padding: 16px 20px; border-bottom: 1px solid var(--borde); }
        .sec-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em;
                      text-transform: uppercase; color: var(--texto-3); margin-bottom: 10px; }
        .ruta-item  { display: flex; align-items: flex-start; gap: 10px; margin-bottom: 8px; }
        .ruta-item:last-child { margin-bottom: 0; }
        .ruta-dot   { width: 10px; height: 10px; border-radius: 50%;
                      flex-shrink: 0; margin-top: 3px; }
        .dot-v { background: var(--verde); }
        .dot-r { background: var(--error); }
        .ruta-texto { font-size: 13px; color: var(--texto-2); line-height: 1.4; }

        /* Pasajero */
        .pasajero-card {
            background: var(--verde-light); padding: 14px 20px;
            border-bottom: 1px solid var(--borde);
        }
        .pas-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em;
                      text-transform: uppercase; color: var(--verde-dark); margin-bottom: 10px; }
        .pas-fila   { display: flex; justify-content: space-between;
                      font-size: 13px; color: var(--texto-2); margin-bottom: 6px; }
        .pas-fila:last-child { margin-bottom: 0; }
        .pas-fila strong { color: var(--texto); font-weight: 500; }

        /* Controles de estado — el corazón de esta pantalla */
        .controles { padding: 20px; border-bottom: 1px solid var(--borde); }
        .ctrl-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em;
                       text-transform: uppercase; color: var(--texto-3); margin-bottom: 14px; }

        .btn-estado {
            width: 100%; padding: 14px 16px; border: none; border-radius: 12px;
            font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 600;
            cursor: pointer; margin-bottom: 10px; display: flex;
            align-items: center; justify-content: center; gap: 10px;
            transition: opacity .15s, transform .1s;
        }
        .btn-estado:last-child { margin-bottom: 0; }
        .btn-estado:hover  { opacity: .9; }
        .btn-estado:active { transform: scale(0.99); }

        .btn-encamino  { background: var(--purple);     color: white; }
        .btn-iniciar   { background: var(--verde);       color: white; }
        .btn-completar { background: var(--verde-dark);  color: white; }

        .btn-icono { font-size: 18px; }

        /* Instrucción contextual */
        .instruccion {
            background: var(--amber-bg); border-radius: 10px;
            padding: 12px 14px; font-size: 12px; color: var(--amber);
            line-height: 1.6; margin-bottom: 14px;
            display: flex; gap: 8px; align-items: flex-start;
        }
        .instruccion-icono { font-size: 16px; flex-shrink: 0; }

        /* Precio */
        .precio-seccion { padding: 16px 20px; margin-top: auto; }
        .precio-fila    { display: flex; justify-content: space-between;
                          font-size: 13px; color: var(--texto-2); margin-bottom: 6px; }
        .precio-total   { display: flex; justify-content: space-between;
                          font-size: 17px; font-weight: 600; color: var(--texto);
                          border-top: 1px solid var(--borde); padding-top: 10px; margin-top: 6px; }

        /* Mapa */
        #mapa-op { grid-area: mapa; width: 100%; height: 100%; }
    </style>
</head>
<body>

<%
    Viaje viaje = (Viaje) request.getAttribute("viaje");
    if (viaje == null) {
        response.sendRedirect(request.getContextPath() + "/operador/panel");
        return;
    }
    String pasajeroNombre = (String) request.getAttribute("pasajero_nombre");
    String pasajeroTel    = (String) request.getAttribute("pasajero_tel");
    Viaje.Estado estado   = viaje.getEstado();

    // Configuración visual según estado
    String heroClass, ehTag, ehIcono, ehTitulo, ehDesc;
    switch (estado) {
        case ACEPTADO:
            heroClass = "eh-aceptado";
            ehTag     = "Viaje aceptado";
            ehIcono   = "🗺️";
            ehTitulo  = "Dirígete al pasajero";
            ehDesc    = "Ve al punto de origen y confirma cuando estés listo para salir.";
            break;
        case OPERADOR_EN_CAMINO:
            heroClass = "eh-operador_en_camino";
            ehTag     = "En camino";
            ehIcono   = "🚐";
            ehTitulo  = "Rumbo al pasajero";
            ehDesc    = "Confirma cuando el pasajero esté a bordo.";
            break;
        case VIAJE_INICIADO:
            heroClass = "eh-viaje_iniciado";
            ehTag     = "Viaje en curso";
            ehIcono   = "✅";
            ehTitulo  = "Llevando al pasajero";
            ehDesc    = "Confirma al llegar al destino para completar el viaje.";
            break;
        default:
            heroClass = "eh-aceptado";
            ehTag = ehIcono = ehTitulo = ehDesc = "";
    }

    // Instrucción contextual
    String instruccion;
    switch (estado) {
        case ACEPTADO:
            instruccion = "El pasajero está esperando en el origen. Haz clic en 'Salir hacia el pasajero' cuando comiences a moverte.";
            break;
        case OPERADOR_EN_CAMINO:
            instruccion = "Cuando el pasajero esté a bordo de tu vehículo, presiona 'Pasajero a bordo' para iniciar el viaje.";
            break;
        case VIAJE_INICIADO:
            instruccion = "Lleva al pasajero a su destino. Al llegar, presiona 'Completar viaje' para finalizar el servicio.";
            break;
        default:
            instruccion = "";
    }
%>

<nav>
    <span class="nav-logo">Urbvan</span>
    <div class="nav-right">
        <span class="nav-nombre">${sessionScope.nombre}</span>
        <a href="${pageContext.request.contextPath}/operador/panel" class="btn-panel">← Panel</a>
    </div>
</nav>

<div class="panel">

    <!-- Hero de estado -->
    <div class="estado-hero <%= heroClass %>">
        <div class="eh-tag">Viaje #<%= viaje.getIdViaje() %> · <%= ehTag %></div>
        <div class="eh-icono"><%= ehIcono %></div>
        <div class="eh-titulo"><%= ehTitulo %></div>
        <div class="eh-desc"><%= ehDesc %></div>
    </div>

    <!-- Ruta -->
    <div class="seccion">
        <div class="sec-titulo">Ruta del viaje</div>
        <div class="ruta-item">
            <span class="ruta-dot dot-v"></span>
            <span class="ruta-texto">
                <strong style="display:block;color:var(--texto);margin-bottom:2px">Origen</strong>
                <%= viaje.getOrigenDireccion() != null ? viaje.getOrigenDireccion() : "—" %>
            </span>
        </div>
        <div class="ruta-item">
            <span class="ruta-dot dot-r"></span>
            <span class="ruta-texto">
                <strong style="display:block;color:var(--texto);margin-bottom:2px">Destino</strong>
                <%= viaje.getDestinoDireccion() != null ? viaje.getDestinoDireccion() : "—" %>
            </span>
        </div>
    </div>

    <!-- Pasajero -->
    <div class="pasajero-card">
        <div class="pas-titulo">Datos del pasajero</div>
        <div class="pas-fila"><span>Nombre</span><strong><%= pasajeroNombre %></strong></div>
        <div class="pas-fila"><span>Teléfono</span><strong><%= pasajeroTel %></strong></div>
        <div class="pas-fila"><span>Distancia</span><strong><%= String.format("%.2f", viaje.getDistanciaKm()) %> km</strong></div>
    </div>

    <!-- Controles de estado -->
    <div class="controles">
        <div class="ctrl-titulo">Acciones del viaje</div>

        <div class="instruccion">
            <span class="instruccion-icono">💡</span>
            <%= instruccion %>
        </div>

        <% if (estado == Viaje.Estado.ACEPTADO) { %>
        <form method="POST" action="${pageContext.request.contextPath}/operador/cambiar-estado">
            <input type="hidden" name="id_viaje" value="<%= viaje.getIdViaje() %>">
            <input type="hidden" name="accion"   value="en_camino">
            <button type="submit" class="btn-estado btn-encamino">
                <span class="btn-icono">🚐</span>
                Salir hacia el pasajero
            </button>
        </form>

        <% } else if (estado == Viaje.Estado.OPERADOR_EN_CAMINO) { %>
        <form method="POST" action="${pageContext.request.contextPath}/operador/cambiar-estado">
            <input type="hidden" name="id_viaje" value="<%= viaje.getIdViaje() %>">
            <input type="hidden" name="accion"   value="iniciar">
            <button type="submit" class="btn-estado btn-iniciar">
                <span class="btn-icono">✅</span>
                Pasajero a bordo — Iniciar viaje
            </button>
        </form>

        <% } else if (estado == Viaje.Estado.VIAJE_INICIADO) { %>
        <form method="POST" action="${pageContext.request.contextPath}/operador/cambiar-estado"
              onsubmit="return confirmarCompletado()">
            <input type="hidden" name="id_viaje" value="<%= viaje.getIdViaje() %>">
            <input type="hidden" name="accion"   value="completar">
            <button type="submit" class="btn-estado btn-completar">
                <span class="btn-icono">🏁</span>
                Llegamos al destino — Completar viaje
            </button>
        </form>
        <% } %>
    </div>

    <!-- Precio -->
    <div class="precio-seccion">
        <div class="precio-fila"><span>Tarifa base</span><span>$15.00</span></div>
        <div class="precio-fila">
            <span>Por distancia (<%= String.format("%.2f", viaje.getDistanciaKm()) %> km)</span>
            <span>$<%= String.format("%.2f", viaje.getDistanciaKm() * 8.5) %></span>
        </div>
        <div class="precio-fila"><span>Cargo de servicio</span><span>$3.00</span></div>
        <div class="precio-total">
            <span>Total cobrado</span>
            <span>$<%= String.format("%.2f", viaje.getPrecioTotal()) %></span>
        </div>
    </div>

</div>

<!-- Mapa -->
<div id="mapa-op"></div>

<!-- Variables para el JS -->
<script>
    var AZURE_KEY   = '1iXcaVW3TPpFb16nqn0fOdmUzXa9PTEIUz67L6z8IhMUGCgC3CazJQQJ99CEAC8vTInh3jNvAAAgAZMPPoqn';
    var CTX_PATH    = '${pageContext.request.contextPath}';
    var ID_VIAJE    = <%= viaje.getIdViaje() %>;
    var ID_OP       = <%= viaje.getIdOperador() %>;
    var ORIGEN_LAT  = <%= viaje.getOrigenLat() %>;
    var ORIGEN_LNG  = <%= viaje.getOrigenLng() %>;
    var DESTINO_LAT = <%= viaje.getDestinoLat() %>;
    var DESTINO_LNG = <%= viaje.getDestinoLng() %>;
    var ESTADO      = '<%= estado.name() %>';
</script>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script>
var mapa, marcadorOp, marcadorPasajero, marcadorDestino;
var simLat = 19.4326, simLng = -99.1332;
var rutaDibujada = false;

window.addEventListener('load', function () {
    mapa = new atlas.Map('mapa-op', {
        center: [ORIGEN_LNG, ORIGEN_LAT],
        zoom: 13, language: 'es-MX',
        authOptions: { authType: 'subscriptionKey', subscriptionKey: AZURE_KEY }
    });

    mapa.events.add('ready', function () {
        // Marcador del pasajero (origen)
        marcadorPasajero = new atlas.HtmlMarker({
            color: '#1D9E75',
            position: [ORIGEN_LNG, ORIGEN_LAT],
            text: 'P'
        });
        mapa.markers.add(marcadorPasajero);

        // Marcador del destino
        marcadorDestino = new atlas.HtmlMarker({
            color: '#D85A30',
            position: [DESTINO_LNG, DESTINO_LAT]
        });
        mapa.markers.add(marcadorDestino);

        // Dibujar ruta inicial
        var dLat = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LAT : ORIGEN_LAT;
        var dLng = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LNG : ORIGEN_LNG;

        // Intentar usar GPS real primero
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(function (pos) {
                simLat = pos.coords.latitude;
                simLng = pos.coords.longitude;
                iniciarActualizacion();
            }, function () {
                iniciarActualizacion();
            });
        } else {
            iniciarActualizacion();
        }
    });
});

function iniciarActualizacion() {
    actualizarPosicion();
    setInterval(actualizarPosicion, 5000);
}

function actualizarPosicion() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            function (pos) {
                var lat = pos.coords.latitude;
                var lng = pos.coords.longitude;
                procesarPosicion(lat, lng);
            },
            function () { simularMovimiento(); }
        );
    } else {
        simularMovimiento();
    }
}

function procesarPosicion(lat, lng) {
    // Reportar posición al servidor para el polling del pasajero
    fetch(CTX_PATH + '/operador/posicion', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'lat=' + lat + '&lng=' + lng
    });

    actualizarMarcadorOp(lat, lng);

    // Dibujar ruta si aún no se ha dibujado o cambió el destino
    var targetLat = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LAT : ORIGEN_LAT;
    var targetLng = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LNG : ORIGEN_LNG;
    dibujarRuta(lat, lng, targetLat, targetLng);
}

function simularMovimiento() {
    var targetLat = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LAT : ORIGEN_LAT;
    var targetLng = ESTADO === 'VIAJE_INICIADO' ? DESTINO_LNG : ORIGEN_LNG;

    simLat += (targetLat - simLat) * 0.08;
    simLng += (targetLng - simLng) * 0.08;

    fetch(CTX_PATH + '/operador/posicion', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'lat=' + simLat + '&lng=' + simLng
    });

    actualizarMarcadorOp(simLat, simLng);
    dibujarRuta(simLat, simLng, targetLat, targetLng);
}

function actualizarMarcadorOp(lat, lng) {
    var pos = [lng, lat];
    if (!marcadorOp) {
        marcadorOp = new atlas.HtmlMarker({ color: '#534AB7', position: pos, text: 'Yo' });
        mapa.markers.add(marcadorOp);
    } else {
        marcadorOp.setOptions({ position: pos });
    }
    mapa.setCamera({ center: pos, zoom: 14 });
}

function dibujarRuta(oLat, oLng, dLat, dLng) {
    var url = 'https://atlas.microsoft.com/route/directions/json?api-version=1.0' +
        '&query=' + oLat + ',' + oLng + ':' + dLat + ',' + dLng +
        '&travelMode=car&subscription-key=' + AZURE_KEY;

    fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (!data.routes || !data.routes[0]) return;
            var coords = data.routes[0].legs[0].points.map(function (p) {
                return [p.longitude, p.latitude];
            });

            // Limpiar ruta anterior
            if (mapa.layers.getLayerById('ruta-op-layer')) {
                mapa.layers.remove('ruta-op-layer');
            }
            if (mapa.sources.getById('ruta-op-source')) {
                mapa.sources.remove('ruta-op-source');
            }

            var source = new atlas.source.DataSource('ruta-op-source');
            mapa.sources.add(source);
            source.add(new atlas.data.LineString(coords));

            var color = ESTADO === 'VIAJE_INICIADO' ? '#1D9E75' : '#534AB7';
            mapa.layers.add(new atlas.layer.LineLayer(source, 'ruta-op-layer', {
                strokeColor: color,
                strokeWidth: 4
            }));
        })
        .catch(function () { });
}

function confirmarCompletado() {
    return confirm('¿Confirmas que llegaron al destino y deseas completar el viaje?');
}
</script>

</body>
</html>
