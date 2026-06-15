/**
 * seguimiento.js - Urbvan v3.1
 * Tracking B2C/B2B con Azure Maps.
 * - Dibuja la ruta completa del viaje.
 * - Muestra la ubicación actual del operador.
 * - Dibuja en naranja el tramo que el operador debe seguir desde su ubicación actual
 *   hasta el siguiente punto de la ruta.
 */
'use strict';

window.addEventListener('load', function () {
    if (typeof AZURE_KEY === 'undefined' || !AZURE_KEY || AZURE_KEY === 'null') {
        console.warn('[seguimiento.js] AZURE_KEY no definida.');
        return;
    }

    const mapaId = document.getElementById('mapa') ? 'mapa'
                : (document.getElementById('mapa-seguimiento') ? 'mapa-seguimiento' : null);
    if (!mapaId) {
        console.warn('[seguimiento.js] No existe contenedor de mapa.');
        return;
    }

    const origen = obtenerOrigen();
    const destino = obtenerDestino();
    if (!origen || !destino) {
        console.warn('[seguimiento.js] Coordenadas de origen/destino no definidas.');
        return;
    }

    let estadoActual = (typeof ESTADO_VIAJE_INICIAL !== 'undefined' && ESTADO_VIAJE_INICIAL)
        ? String(ESTADO_VIAJE_INICIAL)
        : '';

    const mapa = new atlas.Map(mapaId, {
        center: origen,
        zoom: 12,
        language: 'es-MX',
        style: 'road',
        authOptions: { authType: 'subscriptionKey', subscriptionKey: AZURE_KEY }
    });

    mapa.events.add('ready', async function () {
        const dsPuntos = new atlas.source.DataSource();
        const dsRutaCompleta = new atlas.source.DataSource();
        const dsRutaOperador = new atlas.source.DataSource();
        const dsOperador = new atlas.source.DataSource();
        const dsSiguiente = new atlas.source.DataSource();
        mapa.sources.add([dsRutaCompleta, dsRutaOperador, dsPuntos, dsOperador, dsSiguiente]);

        mapa.layers.add(new atlas.layer.LineLayer(dsRutaCompleta, null, {
            strokeColor: '#10b981', strokeWidth: 4, lineCap: 'round', lineJoin: 'round'
        }));
        mapa.layers.add(new atlas.layer.LineLayer(dsRutaOperador, null, {
            strokeColor: '#f97316', strokeWidth: 5, lineCap: 'round', lineJoin: 'round'
        }));
        mapa.layers.add(new atlas.layer.BubbleLayer(dsPuntos, null, {
            color: ['match', ['get', 'tipo'], 'origen', '#10b981', 'destino', '#ef4444', '#94a3b8'],
            radius: 10,
            strokeColor: '#ffffff', strokeWidth: 3
        }));
        mapa.layers.add(new atlas.layer.BubbleLayer(dsSiguiente, null, {
            color: '#06b6d4', radius: 12, strokeColor: '#ffffff', strokeWidth: 3
        }));
        mapa.layers.add(new atlas.layer.BubbleLayer(dsOperador, null, {
            color: '#f97316', radius: 13, strokeColor: '#ffffff', strokeWidth: 3
        }));

        dsPuntos.add([
            new atlas.data.Feature(new atlas.data.Point(origen), { tipo: 'origen' }),
            new atlas.data.Feature(new atlas.data.Point(destino), { tipo: 'destino' })
        ]);

        await dibujarRutaEntrePuntos(dsRutaCompleta, [origen, destino]);

        function pintarOperador(lat, lng) {
            if (lat === null || lng === null || lat === undefined || lng === undefined || lat === 0 || lng === 0) return null;
            const punto = [parseFloat(lng), parseFloat(lat)];
            if (isNaN(punto[0]) || isNaN(punto[1])) return null;
            dsOperador.clear();
            dsOperador.add(new atlas.data.Feature(new atlas.data.Point(punto), { tipo: 'operador' }));
            return punto;
        }

        function siguientePuntoB2C() {
            const e = estadoActual.toUpperCase();
            if (e === 'EN_CAMINO' || e === 'EN_CURSO' || e === 'En camino al destino'.toUpperCase()) {
                return destino;
            }
            return origen;
        }

        async function actualizarRutaOperador(posOperador) {
            if (!posOperador) return;
            const siguiente = siguientePuntoB2C();
            dsSiguiente.clear();
            dsSiguiente.add(new atlas.data.Feature(new atlas.data.Point(siguiente), { tipo: 'siguiente' }));
            await dibujarRutaEntrePuntos(dsRutaOperador, [posOperador, siguiente], true);
            ajustarCamara(mapa, [posOperador, origen, destino]);
        }

        if (typeof OPERADOR_LAT !== 'undefined' && typeof OPERADOR_LNG !== 'undefined') {
            const pos = pintarOperador(OPERADOR_LAT, OPERADOR_LNG);
            actualizarRutaOperador(pos);
        }

        function refrescarGpsLocalOperador() {
            if (typeof MODO_OPERADOR === 'undefined' || !MODO_OPERADOR || !navigator.geolocation) return;
            navigator.geolocation.getCurrentPosition(function(pos) {
                const punto = pintarOperador(pos.coords.latitude, pos.coords.longitude);
                actualizarRutaOperador(punto);
            }, function(){}, { enableHighAccuracy: true, timeout: 4000 });
        }
        refrescarGpsLocalOperador();
        setInterval(refrescarGpsLocalOperador, 5000);

        async function refrescarTracking() {
            if (typeof TRACKING_URL === 'undefined' || !TRACKING_URL) return;
            try {
                const res = await fetch(TRACKING_URL, { cache: 'no-store' });
                const data = await res.json();
                if (data && data.activo === false) return;

                if (data.estado) {
                    estadoActual = data.estado;
                    actualizarEstadoVisual(data.estado);
                }

                const pos = pintarOperador(data.lat, data.lng);
                await actualizarRutaOperador(pos);
            } catch (e) {
                console.warn('[seguimiento.js] No se pudo refrescar tracking:', e);
            }
        }

        refrescarTracking();
        setInterval(refrescarTracking, 5000);
        ajustarCamara(mapa, [origen, destino]);
    });
});

function obtenerOrigen() {
    if (typeof VIAJE_ORIGEN !== 'undefined') return VIAJE_ORIGEN;
    if (typeof ORIGEN_LNG !== 'undefined' && typeof ORIGEN_LAT !== 'undefined') return [ORIGEN_LNG, ORIGEN_LAT];
    return null;
}

function obtenerDestino() {
    if (typeof VIAJE_DESTINO !== 'undefined') return VIAJE_DESTINO;
    if (typeof DESTINO_LNG !== 'undefined' && typeof DESTINO_LAT !== 'undefined') return [DESTINO_LNG, DESTINO_LAT];
    return null;
}

async function dibujarRutaEntrePuntos(ds, puntos, limpiar) {
    try {
        if (limpiar) ds.clear();
        if (!puntos || puntos.length < 2) return;
        const query = puntos.map(function (p) { return p[1] + ',' + p[0]; }).join(':');
        const url = 'https://atlas.microsoft.com/route/directions/json'
            + '?api-version=1.0&subscription-key=' + AZURE_KEY
            + '&query=' + query
            + '&routeType=fastest&traffic=true&language=es-MX';
        const res = await fetch(url);
        const data = await res.json();
        if (!data.routes || !data.routes.length) return;
        const coords = [];
        data.routes[0].legs.forEach(function (leg) {
            leg.points.forEach(function (p) { coords.push([p.longitude, p.latitude]); });
        });
        if (limpiar) ds.clear();
        ds.add(new atlas.data.Feature(new atlas.data.LineString(coords)));
    } catch (e) {
        console.error('[seguimiento.js] Error al dibujar ruta:', e);
    }
}

function ajustarCamara(mapa, puntos) {
    const validos = (puntos || []).filter(function (p) {
        return p && typeof p[0] === 'number' && typeof p[1] === 'number' && !isNaN(p[0]) && !isNaN(p[1]);
    });
    if (!validos.length) return;
    mapa.setCamera({
        bounds: atlas.data.BoundingBox.fromPositions(validos),
        padding: 80
    });
}

function actualizarEstadoVisual(estado) {
    const estadoTexto = document.getElementById('estado-texto');
    const estadoDesc = document.getElementById('estado-desc');
    const etaSub = document.getElementById('eta-sub');
    if (!estadoTexto) return;
    estadoTexto.textContent = estado;
    if (etaSub) etaSub.textContent = estado;
    if (estadoDesc) {
        const e = String(estado).toLowerCase();
        if (e.indexOf('destino') >= 0 || e.indexOf('curso') >= 0 || e.indexOf('camino') >= 0) {
            estadoDesc.textContent = 'El operador avanza hacia el siguiente punto marcado en el mapa.';
        } else {
            estadoDesc.textContent = 'El operador se dirige hacia tu punto de origen.';
        }
    }
}
