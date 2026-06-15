/**
 * mapa.js - Urbvan v2  |  Azure Maps SDK v3
 *
 * El JSP debe definir ANTES de cargar este script:
 *   const AZURE_KEY = '<%= application.getInitParameter("azure.maps.key") %>';
 *
 * Contenedor del mapa : <div id="mapa">
 *
 * IDs de labels que actualiza (panel derecho):
 *   lblOrigen, lblDestino, lblDistancia, lblDuracion, lblCosto, msgMapa
 *
 * IDs de hidden fields del formulario:
 *   origenLat, origenLng, origenNombre,
 *   destinoLat, destinoLng, destinoNombre,
 *   distanciaKm, duracionMin
 */

'use strict';

// ── Estado del módulo ────────────────────────────────────────────────────────
let _map;
let _dsOrigen, _dsDestino, _dsRuta;
let _origenPos  = null;   // { lat, lng, nombre }
let _destinoPos = null;
let _turno      = 'origen';  // 'origen' | 'destino'

const COSTO_BASE = 35;
const COSTO_KM   = 12;

// ── Punto de entrada: esperar a que el DOM y el SDK estén listos ─────────────
document.addEventListener('DOMContentLoaded', function () {

    // Validar que la key existe
    if (typeof AZURE_KEY === 'undefined' || !AZURE_KEY || AZURE_KEY === 'null') {
        var contenedor = document.getElementById('mapa');
        if (contenedor) {
            contenedor.style.cssText =
                'display:flex;align-items:center;justify-content:center;' +
                'background:#1e293b;color:#ef4444;font-family:sans-serif;font-size:14px';
            contenedor.textContent = '⚠ azure.maps.key no configurada en web.xml';
        }
        return;
    }

    // Inicializar mapa
    _map = new atlas.Map('mapa', {
        center:   [-99.1332, 19.4326],
        zoom:     11,
        language: 'es-MX',
        style:    'road',
        authOptions: {
            authType:        'subscriptionKey',
            subscriptionKey: AZURE_KEY
        }
    });

    _map.events.add('ready', onMapReady);
});

// ── Callback cuando el mapa terminó de cargar ────────────────────────────────
function onMapReady() {

    // Data sources
    _dsOrigen  = new atlas.source.DataSource();
    _dsDestino = new atlas.source.DataSource();
    _dsRuta    = new atlas.source.DataSource();
    _map.sources.add([_dsRuta, _dsOrigen, _dsDestino]);

    // Capa de ruta (línea verde)
    _map.layers.add(new atlas.layer.LineLayer(_dsRuta, null, {
        strokeColor: '#10b981',
        strokeWidth: 4,
        lineCap:     'round',
        lineJoin:    'round'
    }));

    // Pin ORIGEN (verde)
    _map.layers.add(new atlas.layer.BubbleLayer(_dsOrigen, null, {
        color:       '#10b981',
        radius:      10,
        strokeColor: '#ffffff',
        strokeWidth: 3
    }));

    // Pin DESTINO (rojo)
    _map.layers.add(new atlas.layer.BubbleLayer(_dsDestino, null, {
        color:       '#ef4444',
        radius:      10,
        strokeColor: '#ffffff',
        strokeWidth: 3
    }));

    // Registrar el handler de clic
    _map.events.add('click', onMapClick);

    setMensaje('Haz clic en el mapa para colocar el origen 🟢');
}

// ── Handler de clic en el mapa ───────────────────────────────────────────────
async function onMapClick(e) {

    // Guardia: en v3 el clic sobre controles del mapa puede dar e.position null
    if (!e || !e.position) return;

    var lng = e.position[0];  // Azure Maps: [longitude, latitude]
    var lat = e.position[1];

    // Guardia extra: coordenadas deben ser números válidos
    if (typeof lng !== 'number' || typeof lat !== 'number' ||
        isNaN(lng) || isNaN(lat)) return;

    setMensaje('Obteniendo dirección...');
    var nombre = await geocodificarInverso(lat, lng);
    var pos    = [lng, lat];   // formato [lng, lat] para Atlas

    if (_turno === 'origen') {
        _origenPos = { lat: lat, lng: lng, nombre: nombre };
        _dsOrigen.clear();
        _dsOrigen.add(new atlas.data.Feature(new atlas.data.Point(pos)));
        setLabel('lblOrigen', nombre);
        setCampo('origenLat',    lat);
        setCampo('origenLng',    lng);
        setCampo('origenNombre', nombre);
        _turno = 'destino';
        setMensaje('Ahora haz clic para colocar el destino 🔴');

    } else {
        _destinoPos = { lat: lat, lng: lng, nombre: nombre };
        _dsDestino.clear();
        _dsDestino.add(new atlas.data.Feature(new atlas.data.Point(pos)));
        setLabel('lblDestino',   nombre);
        setCampo('destinoLat',    lat);
        setCampo('destinoLng',    lng);
        setCampo('destinoNombre', nombre);
        _turno = 'origen';
        setMensaje('Haz clic para reemplazar el origen 🟢');
    }

    // Calcular ruta cuando ambos puntos están definidos
    if (_origenPos && _destinoPos) {
        setMensaje('Calculando ruta...');
        await calcularRuta();
    }
}

// ── Geocodificación inversa (lat,lng → nombre legible) ───────────────────────
async function geocodificarInverso(lat, lng) {
    try {
        var url = 'https://atlas.microsoft.com/search/address/reverse/json' +
                  '?api-version=1.0' +
                  '&subscription-key=' + AZURE_KEY +
                  '&query=' + lat + ',' + lng +
                  '&language=es-MX';

        var res  = await fetch(url);
        var data = await res.json();
        var addr = data.addresses && data.addresses[0] && data.addresses[0].address;

        if (!addr) return lat.toFixed(5) + ', ' + lng.toFixed(5);

        return addr.streetNameAndNumber
            || addr.streetName
            || addr.freeformAddress
            || (lat.toFixed(5) + ', ' + lng.toFixed(5));
    } catch (err) {
        console.warn('[mapa.js] geocodificarInverso error:', err);
        return lat.toFixed(5) + ', ' + lng.toFixed(5);
    }
}

// ── Cálculo de ruta (REST API - compatible v2 y v3) ──────────────────────────
async function calcularRuta() {
    try {
        var url = 'https://atlas.microsoft.com/route/directions/json' +
                  '?api-version=1.0' +
                  '&subscription-key=' + AZURE_KEY +
                  '&query=' + _origenPos.lat  + ',' + _origenPos.lng  +
                  ':'       + _destinoPos.lat + ',' + _destinoPos.lng +
                  '&routeType=fastest&traffic=true&language=es-MX';

        var res  = await fetch(url);
        var data = await res.json();

        if (!data.routes || data.routes.length === 0) {
            setMensaje('⚠ No se encontró ruta entre esos puntos. Intenta otras ubicaciones.');
            return;
        }

        var ruta    = data.routes[0];
        var distKm  = parseFloat((ruta.summary.lengthInMeters  / 1000).toFixed(2));
        var durMin  = Math.round(ruta.summary.travelTimeInSeconds / 60);
        var costo   = (COSTO_BASE + distKm * COSTO_KM).toFixed(2);

        // Actualizar panel lateral
        setLabel('lblDistancia', distKm + ' km');
        setLabel('lblDuracion',  durMin + ' min');
        setLabel('lblCosto',     '$' + costo + ' MXN');

        // Llenar hidden fields del formulario
        setCampo('distanciaKm', distKm);
        setCampo('duracionMin', durMin);

        // Dibujar polyline
        var coords = ruta.legs[0].points.map(function(p) {
            return [p.longitude, p.latitude];
        });
        _dsRuta.clear();
        _dsRuta.add(new atlas.data.Feature(new atlas.data.LineString(coords)));

        // Encuadrar la cámara en la ruta completa
        _map.setCamera({
            bounds:  atlas.data.BoundingBox.fromPositions(coords),
            padding: 60
        });

        // Habilitar botón de submit
        var btn = document.getElementById('btnSolicitar');
        if (btn) btn.disabled = false;

        setMensaje('✓ Ruta lista. Revisa el resumen y confirma.');

    } catch (err) {
        console.error('[mapa.js] calcularRuta error:', err);
        setMensaje('⚠ Error al calcular la ruta. Intenta de nuevo.');
    }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/** Actualiza el texto de un label por id (sin lanzar error si no existe). */
function setLabel(id, texto) {
    var el = document.getElementById(id);
    if (el) el.textContent = texto;
}

/** Actualiza el value de un input oculto por id. */
function setCampo(id, valor) {
    var el = document.getElementById(id);
    if (el) el.value = valor;
}

/** Muestra un mensaje de estado debajo del botón. */
function setMensaje(texto) {
    var el = document.getElementById('msgMapa');
    if (el) el.textContent = texto;
}
