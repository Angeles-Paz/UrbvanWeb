<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Detalle de ruta #${ruta.id}</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#ff7050;
        --role-dark:#E04A30;
        --role-light:#FFF3F0;
        --role-subtle:rgba(255,112,80,.1);
    }
    </style>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css">
    <script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
    <style>
        #mapa-ruta{width:100%;height:420px;border-radius:14px;overflow:hidden;border:1px solid var(--borde)}
        .layout-detalle{display:grid;grid-template-columns:1fr 340px;gap:20px;align-items:start}
        @media(max-width:900px){.layout-detalle{grid-template-columns:1fr}}
        .parada-timeline{position:relative;padding-left:28px}
        .parada-line{position:absolute;left:9px;top:0;bottom:0;width:2px;background:var(--borde)}
        .parada-row{position:relative;padding:10px 0 10px 16px;border-bottom:1px solid var(--borde)}
        .parada-row:last-child{border-bottom:none}
        .parada-dot{position:absolute;left:-22px;top:14px;width:14px;height:14px;border-radius:50%;border:2px solid #fff}
        .parada-dot.origen{background:#10b981}
        .parada-dot.parada{background:#06b6d4}
        .parada-dot.destino{background:#ef4444}
        .parada-hora{font-size:12px;color:var(--texto2);font-weight:600;margin-bottom:2px}
        .parada-nombre{font-size:14px;font-weight:500}
        .parada-estancia{font-size:12px;color:var(--texto2);margin-top:2px}
        .asiento-chip{display:inline-flex;align-items:center;gap:6px;background:var(--surface2);
                      border-radius:8px;padding:6px 12px;font-size:13px;margin:4px}
        .asiento-num{background:#06b6d4;color:#fff;border-radius:6px;
                     padding:2px 8px;font-weight:700;font-size:12px}
        .info-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:16px}
        .info-cell{background:var(--surface2);border-radius:10px;padding:12px}
        .info-cell-label{font-size:11px;color:var(--texto2);font-weight:600;margin-bottom:4px}
        .info-cell-val{font-size:15px;font-weight:600}
        .tracking-card{background:linear-gradient(135deg,#ecfeff,#f8fafc);border:1px solid var(--borde)}
        .evento-row{display:flex;gap:10px;padding:10px 0;border-bottom:1px solid var(--borde);font-size:13px}
        .evento-row:last-child{border-bottom:none}
        .evento-dot{width:10px;height:10px;border-radius:50%;background:#06b6d4;margin-top:5px;flex-shrink:0}
        .tracking-live{display:flex;align-items:center;gap:8px;color:#0f766e;font-size:13px;font-weight:600;margin-top:8px}
        .tracking-live span{width:8px;height:8px;border-radius:50%;background:#10b981;display:inline-block;animation:pulseB2B 1.3s infinite}
        @keyframes pulseB2B{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.35;transform:scale(.75)}}
        .acciones-operador{display:flex;flex-direction:column;gap:10px;margin-top:12px}
        .acciones-operador form{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
        .acciones-operador select{flex:1;min-width:160px;padding:9px 11px;border:1px solid var(--borde);border-radius:9px;background:var(--surface)}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${urlBack}">&#8592; Volver</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${param.estado == 'ok'}"><div class="alerta-ok">✓ Estado operativo actualizado correctamente.</div></c:if>
    <c:if test="${param.estado == 'error'}"><div class="alerta-error">No se pudo actualizar el estado de la ruta.</div></c:if>

    <c:if test="${not empty ruta}">
        <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:12px;margin-bottom:24px">
            <div>
                <div class="page-title">Ruta #${ruta.id}</div>
                <div class="page-sub">${ruta.empresaNombre} &#183; ${ruta.vehiculoModelo} &#183; ${ruta.vehiculoPlaca}</div>
            </div>
            <span class="badge ${ruta.estadoClase}" style="font-size:14px;padding:8px 16px">${ruta.estadoTexto}</span>
        </div>

        <div class="layout-detalle">
            <%-- Columna izquierda: mapa + asientos --%>
            <div>
                <div class="card" style="margin-bottom:20px;padding:0;overflow:hidden">
                    <div id="mapa-ruta"></div>
                </div>

                <div class="card">
                    <div class="card-title">Asientos asignados (${ruta.asientosOcupados}/${ruta.vehiculoCapacidad})</div>
                    <c:choose>
                        <c:when test="${empty ruta.asientos}">
                            <div class="empty" style="padding:16px">Sin asientos asignados.</div>
                        </c:when>
                        <c:otherwise>
                            <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:8px">
                                <c:forEach var="a" items="${ruta.asientos}">
                                    <div class="asiento-chip">
                                        <span class="asiento-num">${a.numeroAsiento}</span>
                                        <span>${a.empleadoNombre}</span>
                                    </div>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>

            <%-- Columna derecha: info + horario --%>
            <div>
                <%-- Info general --%>
                <div class="card" style="margin-bottom:16px">
                    <div class="card-title">Informacion del viaje</div>
                    <div class="info-grid">
                        <div class="info-cell">
                            <div class="info-cell-label">INICIO</div>
                            <div class="info-cell-val" style="font-size:13px">${ruta.fechaInicio}</div>
                        </div>
                        <div class="info-cell">
                            <div class="info-cell-label">FIN EST.</div>
                            <div class="info-cell-val" style="font-size:13px">${ruta.fechaFinEst}</div>
                        </div>
                        <div class="info-cell">
                            <div class="info-cell-label">DISTANCIA</div>
                            <div class="info-cell-val">${ruta.kmTotales} km</div>
                        </div>
                        <div class="info-cell">
                            <div class="info-cell-label">COSTO</div>
                            <div class="info-cell-val" style="color:#10b981">$${ruta.costoTotal}</div>
                        </div>
                    </div>
                    <div style="background:var(--surface2);border-radius:10px;padding:12px;font-size:14px">
                        <div style="color:var(--texto2);font-size:11px;font-weight:600;margin-bottom:4px">OPERADOR</div>
                        <div style="font-weight:600">${ruta.operadorNombre}</div>
                        <div style="color:var(--texto2);font-size:12px">Score: &#9733; ${ruta.operadorScore}</div>
                    </div>
                </div>

                <div class="card tracking-card" style="margin-bottom:16px">
                    <div class="card-title">Tracking en vivo del operador</div>
                    <div style="font-size:13px;color:var(--texto2);line-height:1.5">
                        Posición actual: <strong id="op-pos-text">esperando señal GPS...</strong><br>
                        Último evento: <strong id="ultimo-evento-text">sin eventos registrados</strong>
                    </div>
                    <div class="tracking-live"><span></span> Actualización automática cada 5 segundos</div>

                    <c:if test="${rolActual == 'OPERADOR' && ruta.estadoNombre != 'COMPLETADA' && ruta.estadoNombre != 'CANCELADA'}">
                        <div class="acciones-operador">
                            <form method="post" action="${pageContext.request.contextPath}/operador/b2b/cambiar-estado" class="form-estado-b2b">
                                <input type="hidden" name="rutaId" value="${ruta.id}">
                                <input type="hidden" name="accion" value="iniciar">
                                <input type="hidden" name="lat" class="lat-input">
                                <input type="hidden" name="lng" class="lng-input">
                                <button type="submit" class="btn btn-verde btn-sm">▶ Iniciar viaje</button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/operador/b2b/cambiar-estado" class="form-estado-b2b">
                                <input type="hidden" name="rutaId" value="${ruta.id}">
                                <input type="hidden" name="accion" value="llegar_parada">
                                <input type="hidden" name="lat" class="lat-input">
                                <input type="hidden" name="lng" class="lng-input">
                                <select name="paradaId" required>
                                    <option value="">Selecciona parada de llegada</option>
                                    <c:forEach var="p" items="${ruta.paradas}">
                                        <option value="${p.id}">${p.orden} - ${p.nombreLugar}</option>
                                    </c:forEach>
                                </select>
                                <button type="submit" class="btn btn-naranja btn-sm">Llegué a parada</button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/operador/b2b/cambiar-estado" class="form-estado-b2b">
                                <input type="hidden" name="rutaId" value="${ruta.id}">
                                <input type="hidden" name="accion" value="salir_parada">
                                <input type="hidden" name="lat" class="lat-input">
                                <input type="hidden" name="lng" class="lng-input">
                                <select name="paradaId" required>
                                    <option value="">Selecciona parada de salida</option>
                                    <c:forEach var="p" items="${ruta.paradas}">
                                        <option value="${p.id}">${p.orden} - ${p.nombreLugar}</option>
                                    </c:forEach>
                                </select>
                                <button type="submit" class="btn btn-ghost btn-sm">En camino al siguiente punto</button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/operador/b2b/cambiar-estado" class="form-estado-b2b">
                                <input type="hidden" name="rutaId" value="${ruta.id}">
                                <input type="hidden" name="accion" value="terminar">
                                <input type="hidden" name="lat" class="lat-input">
                                <input type="hidden" name="lng" class="lng-input">
                                <button type="submit" class="btn btn-danger btn-sm">✓ Terminar ruta</button>
                            </form>
                        </div>
                    </c:if>
                </div>

                <div class="card" style="margin-bottom:16px">
                    <div class="card-title">Historial operativo</div>
                    <c:choose>
                        <c:when test="${empty eventos}"><div class="empty" style="padding:12px">Aún no hay eventos de ruta.</div></c:when>
                        <c:otherwise>
                            <c:forEach var="ev" items="${eventos}">
                                <div class="evento-row">
                                    <div class="evento-dot"></div>
                                    <div>
                                        <div style="font-weight:600">${ev.tipoTexto}</div>
                                        <div style="color:var(--texto2)">${ev.paradaNombre} · ${ev.creadoEn}</div>
                                    </div>
                                </div>
                            </c:forEach>
                        </c:otherwise>
                    </c:choose>
                </div>

                <%-- Horario de paradas --%>
                <div class="card">
                    <div class="card-title">Horario de paradas</div>
                    <c:choose>
                        <c:when test="${empty ruta.paradas}">
                            <div class="empty" style="padding:16px">Sin paradas registradas.</div>
                        </c:when>
                        <c:otherwise>
                            <div class="parada-timeline">
                                <div class="parada-line"></div>
                                <c:forEach var="p" items="${ruta.paradas}">
                                    <div class="parada-row">
                                        <div class="parada-dot ${p.tipoNombre}"></div>
                                        <div class="parada-hora">
                                            <c:choose>
                                                <c:when test="${not empty p.horaEstimada}">${p.horaEstimada}</c:when>
                                                <c:otherwise>- : -</c:otherwise>
                                            </c:choose>
                                        </div>
                                        <div class="parada-nombre">${p.nombreLugar}</div>
                                        <c:if test="${p.tiempoEstancia > 0}">
                                            <div class="parada-estancia">Estancia: ${p.tiempoEstancia} min</div>
                                        </c:if>
                                        <div style="font-size:11px;color:var(--texto3);margin-top:2px;text-transform:uppercase">${p.tipoTexto}</div>
                                    </div>
                                </c:forEach>
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </c:if>
</div>

<%-- Variables para el mapa - sin template literals --%>
<script>
var AZURE_KEY = '<%= application.getInitParameter("azure.maps.key") %>';

// Paradas como array JS generado por JSTL - sin template literals
var PARADAS_RUTA = [];
var OPERADOR_INICIAL = { lat: ${empty ruta.operadorLat ? 'null' : ruta.operadorLat}, lng: ${empty ruta.operadorLng ? 'null' : ruta.operadorLng} };
var TRACKING_B2B_URL = '${pageContext.request.contextPath}/b2b/ruta/tracking-data?rutaId=${ruta.id}';
<c:forEach var="p" items="${ruta.paradas}">
PARADAS_RUTA.push({
    lat:      ${p.latitud},
    lng:      ${p.longitud},
    nombre:   '${p.nombreLugar}',
    tipo:     '${p.tipoNombre}',
    estancia: ${p.tiempoEstancia}
});
</c:forEach>

var COLORES = { origen: '#10b981', parada: '#06b6d4', destino: '#ef4444' };

document.addEventListener('DOMContentLoaded', function() {
    if (!AZURE_KEY || AZURE_KEY === 'null' || PARADAS_RUTA.length < 2) {
        var div = document.getElementById('mapa-ruta');
        if (div) {
            div.style.cssText = 'display:flex;align-items:center;justify-content:center;' +
                'height:200px;background:var(--surface2);color:var(--texto2);font-size:14px';
            div.textContent = PARADAS_RUTA.length < 2
                ? 'Sin coordenadas de ruta disponibles.'
                : 'Azure Maps key no configurada.';
        }
        return;
    }

    // Centrar el mapa en el punto medio de la ruta
    var centroLng = 0, centroLat = 0;
    PARADAS_RUTA.forEach(function(p) { centroLng += p.lng; centroLat += p.lat; });
    centroLng /= PARADAS_RUTA.length;
    centroLat /= PARADAS_RUTA.length;

    var mapa = new atlas.Map('mapa-ruta', {
        center:   [centroLng, centroLat],
        zoom:     11,
        language: 'es-MX',
        authOptions: { authType: 'subscriptionKey', subscriptionKey: AZURE_KEY }
    });

    mapa.events.add('ready', function() {
        var dsPins  = new atlas.source.DataSource();
        var dsRuta  = new atlas.source.DataSource();
        var dsRutaOperador = new atlas.source.DataSource();
        var dsOperador = new atlas.source.DataSource();
        var dsSiguiente = new atlas.source.DataSource();
        mapa.sources.add([dsRuta, dsRutaOperador, dsPins, dsOperador, dsSiguiente]);

        // Capa de ruta
        mapa.layers.add(new atlas.layer.LineLayer(dsRuta, null, {
            strokeColor: '#06b6d4', strokeWidth: 4, lineCap: 'round', lineJoin: 'round'
        }));

        // Tramo en vivo: operador -> siguiente punto
        mapa.layers.add(new atlas.layer.LineLayer(dsRutaOperador, null, {
            strokeColor: '#f97316', strokeWidth: 5, lineCap: 'round', lineJoin: 'round'
        }));

        // Capa de pines
        mapa.layers.add(new atlas.layer.BubbleLayer(dsPins, null, {
            color:       ['get', 'color'],
            radius:      10,
            strokeColor: '#ffffff',
            strokeWidth: 3
        }));

        mapa.layers.add(new atlas.layer.BubbleLayer(dsOperador, null, {
            color: '#f97316', radius: 13, strokeColor: '#ffffff', strokeWidth: 3
        }));

        mapa.layers.add(new atlas.layer.BubbleLayer(dsSiguiente, null, {
            color: '#06b6d4', radius: 12, strokeColor: '#ffffff', strokeWidth: 3
        }));

        function pintarOperador(lat, lng) {
            if (lat == null || lng == null) return null;
            var punto = [parseFloat(lng), parseFloat(lat)];
            if (isNaN(punto[0]) || isNaN(punto[1])) return null;
            dsOperador.clear();
            dsOperador.add(new atlas.data.Feature(
                new atlas.data.Point(punto),
                { nombre: 'Operador' }
            ));
            var txt = document.getElementById('op-pos-text');
            if (txt) txt.textContent = Number(lat).toFixed(5) + ', ' + Number(lng).toFixed(5);
            return punto;
        }

        function obtenerSiguientePunto(data) {
            if (!PARADAS_RUTA.length) return null;
            if (data && data.ultimoEvento && data.ultimoEvento.tipo && data.ultimoEvento.tipo.toLowerCase().indexOf('fin') >= 0) {
                return null;
            }
            var idx = -1;
            if (data && data.ultimoEvento && data.ultimoEvento.parada) {
                for (var i = 0; i < PARADAS_RUTA.length; i++) {
                    if (PARADAS_RUTA[i].nombre === data.ultimoEvento.parada) { idx = i; break; }
                }
            }
            var targetIndex = idx >= 0 ? Math.min(idx + 1, PARADAS_RUTA.length - 1) : 0;
            return PARADAS_RUTA[targetIndex];
        }

        async function dibujarRutaOperador(posOperador, data) {
            if (!posOperador) return;
            var sig = obtenerSiguientePunto(data);
            dsRutaOperador.clear();
            dsSiguiente.clear();
            if (!sig) return;
            dsSiguiente.add(new atlas.data.Feature(
                new atlas.data.Point([sig.lng, sig.lat]),
                { nombre: 'Siguiente punto' }
            ));
            var query = posOperador[1] + ',' + posOperador[0] + ':' + sig.lat + ',' + sig.lng;
            var url = 'https://atlas.microsoft.com/route/directions/json'
                    + '?api-version=1.0'
                    + '&subscription-key=' + AZURE_KEY
                    + '&query=' + query
                    + '&routeType=fastest&traffic=true&language=es-MX';
            try {
                var r = await fetch(url);
                var json = await r.json();
                if (!json.routes || !json.routes.length) return;
                var coords = [];
                json.routes[0].legs.forEach(function(leg) {
                    leg.points.forEach(function(p) { coords.push([p.longitude, p.latitude]); });
                });
                dsRutaOperador.add(new atlas.data.Feature(new atlas.data.LineString(coords)));
            } catch(e) { console.warn('ruta operador B2B:', e); }
        }

        var posInicial = pintarOperador(OPERADOR_INICIAL.lat, OPERADOR_INICIAL.lng);
        dibujarRutaOperador(posInicial, null);

        async function refrescarTrackingB2B() {
            try {
                var r = await fetch(TRACKING_B2B_URL, { cache: 'no-store' });
                var data = await r.json();
                var pos = null;
                if (data.operador) pos = pintarOperador(data.operador.lat, data.operador.lng);
                await dibujarRutaOperador(pos, data);
                var ev = document.getElementById('ultimo-evento-text');
                if (ev && data.ultimoEvento) {
                    ev.textContent = data.ultimoEvento.tipo + (data.ultimoEvento.parada ? ' · ' + data.ultimoEvento.parada : '');
                }
            } catch(e) { console.warn('tracking B2B:', e); }
        }
        refrescarTrackingB2B();
        setInterval(refrescarTrackingB2B, 5000);

        // Agregar pines de cada parada
        PARADAS_RUTA.forEach(function(p) {
            dsPins.add(new atlas.data.Feature(
                new atlas.data.Point([p.lng, p.lat]),
                { color: COLORES[p.tipo] || '#06b6d4', nombre: p.nombre }
            ));
        });

        // Llamar a Azure Maps Route API para dibujar la ruta exacta entre todas las paradas
        var query = PARADAS_RUTA.map(function(p) { return p.lat + ',' + p.lng; }).join(':');
        var urlRuta = 'https://atlas.microsoft.com/route/directions/json'
                    + '?api-version=1.0'
                    + '&subscription-key=' + AZURE_KEY
                    + '&query=' + query
                    + '&routeType=fastest';

        fetch(urlRuta)
            .then(function(r) { return r.json(); })
            .then(function(data) {
                if (!data.routes || !data.routes.length) return;
                var coords = [];
                data.routes[0].legs.forEach(function(l) {
                    l.points.forEach(function(p) { coords.push([p.longitude, p.latitude]); });
                });
                dsRuta.add(new atlas.data.Feature(new atlas.data.LineString(coords)));
                mapa.setCamera({
                    bounds:  atlas.data.BoundingBox.fromPositions(coords),
                    padding: 60
                });
            })
            .catch(function(err) {
                // Si la API falla, al menos mostrar los pines con un bounding box aproximado
                var positions = PARADAS_RUTA.map(function(p) { return [p.lng, p.lat]; });
                mapa.setCamera({
                    bounds:  atlas.data.BoundingBox.fromPositions(positions),
                    padding: 80
                });
                console.warn('Route API error:', err);
            });
    });
});


// Mientras el operador tenga abierta la ruta B2B, su GPS se envía al servidor
// para que empresa/empleados vean el tracking en vivo.
<c:if test="${rolActual == 'OPERADOR'}">
function enviarGpsOperadorB2B() {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(function(pos) {
        fetch('${pageContext.request.contextPath}/operador/actualizar-posicion', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'lat=' + encodeURIComponent(pos.coords.latitude) + '&lng=' + encodeURIComponent(pos.coords.longitude)
        });
    }, function(){}, { enableHighAccuracy: true, timeout: 4000 });
}
enviarGpsOperadorB2B();
setInterval(enviarGpsOperadorB2B, 10000);
</c:if>

// Captura GPS del operador antes de enviar cualquier cambio de estado.
document.querySelectorAll('.form-estado-b2b').forEach(function(form) {
    form.addEventListener('submit', function(ev) {
        if (!navigator.geolocation || form.dataset.gpsListo === '1') return;
        ev.preventDefault();
        navigator.geolocation.getCurrentPosition(function(pos) {
            form.querySelector('.lat-input').value = pos.coords.latitude;
            form.querySelector('.lng-input').value = pos.coords.longitude;
            form.dataset.gpsListo = '1';
            form.submit();
        }, function() {
            form.dataset.gpsListo = '1';
            form.submit();
        }, { enableHighAccuracy: true, timeout: 3500 });
    });
});
</script>
</body>
</html>
