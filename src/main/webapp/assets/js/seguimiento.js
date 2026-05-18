// ============================================================
//  seguimiento.js — polling y mapa de seguimiento del viaje
//  Ubicación: src/main/webapp/assets/js/seguimiento.js
// ============================================================

var mapa, marcadorPasajero, marcadorOperador, lineaRuta;
var intervalPolling = null;
var ultimoEstado = null;

// Inyectados desde el JSP
// AZURE_KEY, CTX_PATH, ID_VIAJE, ORIGEN_LAT, ORIGEN_LNG, DESTINO_LAT, DESTINO_LNG

window.addEventListener('load', function () {
    iniciarMapa();
    iniciarPolling();
});

// ── Inicializar mapa ───────────────────────────────────────
function iniciarMapa() {
    mapa = new atlas.Map('mapa-seguimiento', {
        center: [ORIGEN_LNG, ORIGEN_LAT],
        zoom: 13,
        language: 'es-MX',
        authOptions: {
            authType: 'subscriptionKey',
            subscriptionKey: AZURE_KEY
        }
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
        var marcadorDestino = new atlas.HtmlMarker({
            color: '#D85A30',
            position: [DESTINO_LNG, DESTINO_LAT]
        });
        mapa.markers.add(marcadorDestino);
    });
}

// ── Polling — consulta el estado cada 5 segundos ──────────
function iniciarPolling() {
    consultarEstado();
    intervalPolling = setInterval(consultarEstado, 5000);
}

function consultarEstado() {
    fetch(CTX_PATH + '/pasajero/estado-viaje', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'id_viaje=' + ID_VIAJE
    })
    .then(function (r) { return r.json(); })
    .then(function (data) {
        if (data.error) return;
        procesarEstado(data);
    })
    .catch(function () {
        // Error de red — reintentará en el siguiente ciclo
    });
}

// ── Procesar respuesta del servidor ───────────────────────
function procesarEstado(data) {
    var estado = data.estado;

    // Actualizar ETA si cambió
    actualizarETA(data.eta_operador, data.eta_viaje, estado);

    // Actualizar marcador del operador si tiene posición
    if (data.op_lat && data.op_lng && data.op_lat !== 0) {
        actualizarMarcadorOperador(data.op_lat, data.op_lng);

        // Dibujar ruta del operador al pasajero si está en camino
        if (estado === 'ACEPTADO' || estado === 'OPERADOR_EN_CAMINO') {
            dibujarRutaOperador(data.op_lat, data.op_lng, ORIGEN_LAT, ORIGEN_LNG);
        }

        // Dibujar ruta del viaje si ya inició
        if (estado === 'VIAJE_INICIADO') {
            dibujarRutaViaje(data.op_lat, data.op_lng, DESTINO_LAT, DESTINO_LNG);
        }
    }

    // Actualizar UI según el estado
    if (estado !== ultimoEstado) {
        ultimoEstado = estado;
        actualizarUI(estado, data);
    }

    // Si el viaje terminó, detener el polling
    if (estado === 'COMPLETADO' || estado === 'CANCELADO') {
        clearInterval(intervalPolling);
        if (estado === 'COMPLETADO') {
            setTimeout(function () {
                window.location.href = CTX_PATH + '/pasajero/dashboard?viaje=completado';
            }, 3000);
        }
    }
}

// ── Actualizar marcador del operador ──────────────────────
function actualizarMarcadorOperador(lat, lng) {
    if (!mapa) return;
    var pos = [lng, lat];
    if (!marcadorOperador) {
        marcadorOperador = new atlas.HtmlMarker({
            color: '#534AB7',
            position: pos,
            text: 'O'
        });
        mapa.markers.add(marcadorOperador);
    } else {
        marcadorOperador.setOptions({ position: pos });
    }
}

// ── Dibujar ruta en el mapa ────────────────────────────────
function dibujarRuta(origenLat, origenLng, destinoLat, destinoLng, color, idCapa) {
    var url = 'https://atlas.microsoft.com/route/directions/json' +
        '?api-version=1.0' +
        '&query=' + origenLat + ',' + origenLng + ':' + destinoLat + ',' + destinoLng +
        '&travelMode=car&subscription-key=' + AZURE_KEY;

    fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            if (!data.routes || !data.routes[0]) return;
            var puntos = data.routes[0].legs[0].points;
            var coords = puntos.map(function (p) { return [p.longitude, p.latitude]; });

            // Limpiar capa anterior si existe
            try { mapa.layers.remove(idCapa + '-layer'); } catch(e) {}
            try { mapa.sources.remove(idCapa + '-source'); } catch(e) {}

            var source = new atlas.source.DataSource(idCapa + '-source');
            mapa.sources.add(source);
            source.add(new atlas.data.LineString(coords));

            mapa.layers.add(new atlas.layer.LineLayer(source, idCapa + '-layer', {
                strokeColor: color,
                strokeWidth: 3,
                strokeDashArray: idCapa === 'op' ? [2, 2] : [1]
            }));
        });
}

function dibujarRutaOperador(opLat, opLng, pasLat, pasLng) {
    dibujarRuta(opLat, opLng, pasLat, pasLng, '#534AB7', 'op');
}

function dibujarRutaViaje(opLat, opLng, destLat, destLng) {
    dibujarRuta(opLat, opLng, destLat, destLng, '#1D9E75', 'viaje');
}

// ── Actualizar ETA en el panel ────────────────────────────
function actualizarETA(etaOp, etaViaje, estado) {
    var elEta = document.getElementById('eta-valor');
    var elSub = document.getElementById('eta-sub');
    if (!elEta) return;

    if (estado === 'EN_ASIGNACION') {
        elEta.textContent = '...';
        elSub.textContent = 'Buscando operador';
    } else if (estado === 'ACEPTADO' || estado === 'OPERADOR_EN_CAMINO') {
        elEta.textContent = (etaOp || '—') + ' min';
        elSub.textContent = 'El operador llega en';
    } else if (estado === 'VIAJE_INICIADO') {
        elEta.textContent = (etaViaje || '—') + ' min';
        elSub.textContent = 'Tiempo al destino';
    } else if (estado === 'COMPLETADO') {
        elEta.textContent = '¡Llegaste!';
        elSub.textContent = 'Viaje completado';
    }
}

// ── Actualizar la UI según el estado del viaje ────────────
function actualizarUI(estado, data) {
    var steps = document.querySelectorAll('.timeline-step');
    var estadoTexto = document.getElementById('estado-texto');
    var estadoDesc  = document.getElementById('estado-desc');

    var configs = {
        'EN_ASIGNACION':    { paso: 0, texto: 'Buscando operador',      desc: 'Estamos asignando el operador más cercano a tu ubicación.' },
        'ACEPTADO':         { paso: 1, texto: 'Operador asignado',       desc: 'Tu operador ha aceptado el viaje y se dirige hacia ti.' },
        'OPERADOR_EN_CAMINO': { paso: 1, texto: 'Operador en camino',    desc: 'Tu operador está en camino. Prepárate para abordar.' },
        'VIAJE_INICIADO':   { paso: 2, texto: 'Viaje en curso',          desc: 'Estás en camino a tu destino. ¡Buen viaje!' },
        'COMPLETADO':       { paso: 3, texto: '¡Viaje completado!',      desc: 'Has llegado a tu destino. Gracias por viajar con Urbvan.' },
        'CANCELADO':        { paso: 0, texto: 'Viaje cancelado',         desc: 'El viaje fue cancelado.' }
    };

    var cfg = configs[estado] || configs['EN_ASIGNACION'];

    if (estadoTexto) estadoTexto.textContent = cfg.texto;
    if (estadoDesc)  estadoDesc.textContent  = cfg.desc;

    // Marcar pasos completados en la línea de tiempo
    steps.forEach(function (step, i) {
        step.classList.remove('activo', 'hecho');
        if (i < cfg.paso) step.classList.add('hecho');
        if (i === cfg.paso) step.classList.add('activo');
    });

    // Mostrar botón de calificar si está completado
    if (estado === 'COMPLETADO') {
        var btnCal = document.getElementById('btn-calificar');
        if (btnCal) btnCal.style.display = 'block';
    }
}
