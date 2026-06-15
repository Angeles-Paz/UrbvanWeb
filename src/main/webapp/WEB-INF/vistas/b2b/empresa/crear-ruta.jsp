<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Crear ruta corporativa</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#39207c;
        --role-dark:#2C1862;
        --role-light:#F2EEFF;
        --role-subtle:rgba(57,32,124,.1);
    }
    </style>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css">
    <%-- SDK cargado en head para que atlas este disponible antes del DOMContentLoaded --%>
    <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
    <style>
        #mapa{width:100%;height:420px;border-radius:12px;overflow:hidden;border:1px solid var(--borde)}
        .layout{display:grid;grid-template-columns:1fr 340px;gap:20px;align-items:start}
        .parada-item{background:var(--surface2);border-radius:10px;padding:12px 14px;margin-bottom:8px;display:flex;align-items:center;gap:10px}
        .parada-tipo{width:20px;height:20px;border-radius:50%;flex-shrink:0}
        .paso{display:flex;align-items:center;gap:8px;padding:8px 0;border-bottom:1px solid var(--borde);font-size:14px;color:var(--texto2)}
        .paso-num{width:24px;height:24px;border-radius:50%;background:var(--role);color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;flex-shrink:0}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" height="200"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard">Panel</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/empleados">Empleados</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/crear-ruta" class="activo">+ Nueva ruta</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Crear ruta corporativa</div>
    <div class="page-sub">Configura la ruta, el vehiculo y el horario</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${not empty aviso}"><div class="alerta-ok">${aviso}</div></c:if>

    <form id="fRuta" method="post" action="${pageContext.request.contextPath}/b2b/empresa/crear-ruta">
    <div class="layout">
        <div>
            <p style="color:var(--texto2);font-size:13px;background:var(--surface2);padding:10px 14px;border-radius:8px;margin-bottom:12px">
                Haz clic en el mapa: 1er clic = Origen, 2do clic = Destino. Clicks adicionales agregan paradas intermedias (max 6).
            </p>
            <div id="mapa"></div>
            <div id="listaParadas" style="margin-top:12px"></div>
            <div id="camposOcultos"></div>
        </div>

        <div>
            <div class="card" style="margin-bottom:16px">
                <div class="card-title">Configuracion de la ruta</div>
                <div class="form-group">
                    <label class="form-label">Fecha y hora de inicio</label>
                    <input type="datetime-local" name="fechaInicio" id="fechaInicio" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Vehiculo B2B</label>
                    <select name="vehiculoId" id="selVehiculo" required onchange="actualizarVehiculo(this)">
                        <option value="">-- Selecciona --</option>
                        <c:forEach var="v" items="${vehiculosB2B}">
                            <option value="${v.id}"
                                    data-modelo="${v.modelo}"
                                    data-operador="${v.operadorId}"
                                    data-operador-nombre="${v.operadorNombre}"
                                    data-capacidad="${v.capacidad}">
                                ${v.modelo} - ${v.placa} (${v.capacidad} pax)
                            </option>
                        </c:forEach>
                    </select>
                </div>
                <div id="infoVehiculo" style="display:none;background:var(--surface2);border-radius:10px;padding:12px;margin-bottom:16px;font-size:14px">
                    <div style="color:var(--texto2);font-size:12px;margin-bottom:4px">OPERADOR ASIGNADO</div>
                    <div style="font-weight:600" id="lblOperador">--</div>
                </div>
                <input type="hidden" name="modeloVehiculo" id="modeloVehiculo">
                <input type="hidden" name="operadorId"     id="operadorId">
                <input type="hidden" name="kmTotales"      id="kmTotales"     value="0">
                <input type="hidden" name="duracionHoras"  id="duracionHoras" value="1">
            </div>

            <div class="card" style="margin-bottom:16px">
                <div class="card-title">Resumen calculado</div>
                <div class="paso"><div class="paso-num">O</div><span id="resOrigenNombre">Sin origen</span></div>
                <div style="padding:4px 0 4px 32px;color:var(--texto3);font-size:12px" id="resParadas">0 paradas intermedias</div>
                <div class="paso"><div class="paso-num">D</div><span id="resDestinoNombre">Sin destino</span></div>
                <div style="margin-top:12px;display:grid;grid-template-columns:1fr 1fr;gap:10px">
                    <div style="background:var(--surface2);border-radius:8px;padding:10px;text-align:center">
                        <div style="color:var(--texto2);font-size:11px">DISTANCIA</div>
                        <div style="font-weight:700" id="resKm">--</div>
                    </div>
                    <div style="background:var(--surface2);border-radius:8px;padding:10px;text-align:center">
                        <div style="color:var(--texto2);font-size:11px">COSTO EST.</div>
                        <div style="font-weight:700;color:#10b981" id="resCosto">--</div>
                    </div>
                </div>
            </div>

            <button type="submit" id="btnCrear" class="btn btn-primary" disabled
                    style="width:100%;justify-content:center;padding:14px">
                Crear ruta y asignar asientos
            </button>
            <p id="msgEstado" style="text-align:center;color:var(--texto2);font-size:12px;margin-top:8px">
                Agrega al menos origen y destino en el mapa.
            </p>
        </div>
    </div>
    </form>
</div>

<%-- AZURE_KEY inyectada como variable JS - SIN template literals para evitar conflicto EL --%>
<script>
var AZURE_KEY    = '<%= application.getInitParameter("azure.maps.key") %>';
var TARIFA_KM    = 18.50;
var TARIFA_HORA  = 320.00;

var mapaObj, dsParadas, dsRuta;
var paradas = [];
var COLORES_PIN = { origen: '#10b981', parada: '#06b6d4', destino: '#ef4444' };

document.addEventListener('DOMContentLoaded', function() {
    // Fecha minima: 2 horas desde ahora
    var ahora = new Date(Date.now() + 2 * 3600 * 1000);
    var pad = function(n){ return String(n).padStart(2,'0'); };
    document.getElementById('fechaInicio').min =
        ahora.getFullYear() + '-' + pad(ahora.getMonth()+1) + '-' + pad(ahora.getDate()) +
        'T' + pad(ahora.getHours()) + ':' + pad(ahora.getMinutes());
    document.getElementById('fechaInicio').addEventListener('change', validarFormulario);

    if (!AZURE_KEY || AZURE_KEY === 'null') {
        document.getElementById('mapa').innerHTML =
            '<div style="padding:20px;color:#ef4444;text-align:center">Azure Maps key no configurada en web.xml</div>';
        return;
    }

    mapaObj = new atlas.Map('mapa', {
        center: [-99.1332, 19.4326],
        zoom: 11,
        language: 'es-MX',
        authOptions: { authType: 'subscriptionKey', subscriptionKey: AZURE_KEY }
    });

    mapaObj.events.add('ready', function() {
        dsParadas = new atlas.source.DataSource();
        dsRuta    = new atlas.source.DataSource();
        mapaObj.sources.add([dsRuta, dsParadas]);

        mapaObj.layers.add(new atlas.layer.LineLayer(dsRuta, null,
            { strokeColor: '#06b6d4', strokeWidth: 3, lineCap: 'round' }));
        mapaObj.layers.add(new atlas.layer.BubbleLayer(dsParadas, null,
            { color: ['get', 'color'], radius: 10, strokeColor: '#fff', strokeWidth: 2 }));

        mapaObj.events.add('click', onMapClick);
    });
});

async function onMapClick(e) {
    if (!e || !e.position) return;
    var lng = e.position[0];
    var lat = e.position[1];
    if (isNaN(lat) || isNaN(lng)) return;

    if (paradas.length >= 8) { setMsg('Maximo 8 puntos (origen + 6 paradas + destino).'); return; }

    var nombre = await geocodificar(lat, lng);
    paradas.push({ lat: lat, lng: lng, nombre: nombre, tipo: 'parada', estancia: 5 });

    // Reasignar tipos
    paradas.forEach(function(p, i) {
        if (i === 0) p.tipo = 'origen';
        else if (i === paradas.length - 1) p.tipo = 'destino';
        else p.tipo = 'parada';
    });

    renderizarParadas();
    if (paradas.length >= 2) calcularRuta();
}

function renderizarParadas() {
    dsParadas.clear();
    paradas.forEach(function(p) {
        dsParadas.add(new atlas.data.Feature(
            new atlas.data.Point([p.lng, p.lat]),
            { color: COLORES_PIN[p.tipo] || '#06b6d4' }
        ));
    });

    // Actualizar lista HTML - sin template literals
    var html = '';
    paradas.forEach(function(p, i) {
        var color = COLORES_PIN[p.tipo] || '#06b6d4';
        html += '<div class="parada-item">';
        html += '<div class="parada-tipo" style="background:' + color + '"></div>';
        html += '<div style="flex:1;font-size:14px">';
        html += '<div style="font-weight:500">' + (i+1) + '. ' + p.nombre + '</div>';
        html += '<div style="font-size:12px;color:var(--texto2)">' + p.tipo + '</div>';
        html += '</div>';
        if (p.tipo === 'parada') {
            html += '<input type="number" min="1" max="60" value="' + p.estancia + '"'
                  + ' onchange="paradas[' + i + '].estancia=parseInt(this.value)||5"'
                  + ' style="width:60px;text-align:center" title="Minutos de estancia">';
        }
        html += '<button type="button" onclick="quitarParada(' + i + ')"'
              + ' style="background:none;border:none;color:#ef4444;cursor:pointer;font-size:16px">x</button>';
        html += '</div>';
    });
    document.getElementById('listaParadas').innerHTML = html;

    // Resumen
    document.getElementById('resOrigenNombre').textContent =
        paradas.length > 0 ? paradas[0].nombre : 'Sin origen';
    document.getElementById('resDestinoNombre').textContent =
        paradas.length > 1 ? paradas[paradas.length-1].nombre : 'Sin destino';
    document.getElementById('resParadas').textContent =
        (paradas.length > 2) ? (paradas.length - 2) + ' parada(s) intermedia(s)' : '0 paradas intermedias';

    generarCamposOcultos();
}

function quitarParada(idx) {
    paradas.splice(idx, 1);
    paradas.forEach(function(p, i) {
        if (i === 0) p.tipo = 'origen';
        else if (i === paradas.length - 1) p.tipo = 'destino';
        else p.tipo = 'parada';
    });
    renderizarParadas();
    if (paradas.length >= 2) calcularRuta();
    else { if(dsRuta) dsRuta.clear(); validarFormulario(); }
}

async function calcularRuta() {
    if (paradas.length < 2 || !AZURE_KEY) return;
    var query = paradas.map(function(p){ return p.lat + ',' + p.lng; }).join(':');
    // Sin template literals - concatenacion directa
    var url = 'https://atlas.microsoft.com/route/directions/json'
            + '?api-version=1.0'
            + '&subscription-key=' + AZURE_KEY
            + '&query=' + query
            + '&routeType=fastest';
    try {
        var res  = await fetch(url);
        var data = await res.json();
        if (!data.routes || !data.routes.length) return;

        var ruta  = data.routes[0];
        var km    = parseFloat((ruta.summary.lengthInMeters  / 1000).toFixed(2));
        var horas = parseFloat((ruta.summary.travelTimeInSeconds / 3600).toFixed(2));
        var costo = (km * TARIFA_KM + horas * TARIFA_HORA).toFixed(2);

        document.getElementById('resKm').textContent       = km + ' km';
        document.getElementById('resCosto').textContent    = '$' + costo;
        document.getElementById('kmTotales').value         = km;
        document.getElementById('duracionHoras').value     = horas;

        var coords = [];
        ruta.legs.forEach(function(l){ l.points.forEach(function(p){ coords.push([p.longitude, p.latitude]); }); });
        dsRuta.clear();
        dsRuta.add(new atlas.data.Feature(new atlas.data.LineString(coords)));
        mapaObj.setCamera({ bounds: atlas.data.BoundingBox.fromPositions(coords), padding: 50 });

        validarFormulario();
    } catch(e) { console.error('calcularRuta:', e); }
}

function generarCamposOcultos() {
    var html = '';
    paradas.forEach(function(p) {
        html += '<input type="hidden" name="paradaTipo"     value="' + p.tipo     + '">';
        html += '<input type="hidden" name="paradaLat"      value="' + p.lat      + '">';
        html += '<input type="hidden" name="paradaLng"      value="' + p.lng      + '">';
        html += '<input type="hidden" name="paradaNombre"   value="' + p.nombre   + '">';
        html += '<input type="hidden" name="paradaEstancia" value="' + p.estancia + '">';
    });
    document.getElementById('camposOcultos').innerHTML = html;
}

function actualizarVehiculo(sel) {
    var opt = sel.options[sel.selectedIndex];
    if (!opt.value) { document.getElementById('infoVehiculo').style.display='none'; return; }
    document.getElementById('modeloVehiculo').value        = opt.getAttribute('data-modelo');
    document.getElementById('operadorId').value            = opt.getAttribute('data-operador');
    document.getElementById('lblOperador').textContent     = opt.getAttribute('data-operador-nombre');
    document.getElementById('infoVehiculo').style.display  = 'block';
    validarFormulario();
}

function validarFormulario() {
    var ok = paradas.length >= 2
          && document.getElementById('selVehiculo').value
          && document.getElementById('fechaInicio').value;
    document.getElementById('btnCrear').disabled = !ok;
    if (ok) setMsg('Todo listo. Haz clic en Crear ruta.');
}

function setMsg(t) { document.getElementById('msgEstado').textContent = t; }

async function geocodificar(lat, lng) {
    try {
        // Sin template literals
        var url = 'https://atlas.microsoft.com/search/address/reverse/json'
                + '?api-version=1.0'
                + '&subscription-key=' + AZURE_KEY
                + '&query=' + lat + ',' + lng
                + '&language=es-MX';
        var res  = await fetch(url);
        var data = await res.json();
        var addr = data.addresses && data.addresses[0] && data.addresses[0].address;
        if (!addr) return lat.toFixed(4) + ',' + lng.toFixed(4);
        return addr.freeformAddress || addr.streetNameAndNumber || (lat.toFixed(4) + ',' + lng.toFixed(4));
    } catch(err) {
        return lat.toFixed(4) + ',' + lng.toFixed(4);
    }
}
</script>
</body>
</html>
