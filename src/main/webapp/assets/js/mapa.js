// ============================================================
//  mapa.js — lógica de Azure Maps para solicitar-viaje.jsp
//  Ubicación: src/main/webapp/assets/js/mapa.js
// ============================================================

// AZURE_KEY y CTX_PATH se inyectan desde el JSP como variables globales

const CDMX_BOUNDS = {
    norte: 19.593, sur: 19.185,
    este: -98.940, oeste: -99.365
};

let origen  = null;
let destino = null;
let mapa, marcadorOrigen, marcadorDestino, lineaRuta;

window.addEventListener('load', function () {
    mapa = new atlas.Map('mapa', {
        center: [-99.1332, 19.4326],
        zoom: 11,
        language: 'es-MX',
        authOptions: {
            authType: 'subscriptionKey',
            subscriptionKey: AZURE_KEY
        }
    });

    mapa.events.add('ready', function () {
        mapa.events.add('click', onMapClick);
        document.getElementById('input-destino')
            .addEventListener('keydown', function (e) {
                if (e.key === 'Enter') buscarDireccion(e.target.value);
            });
    });
});

function onMapClick(e) {
    var pos = e.position;
    var lat = pos[1], lng = pos[0];

    if (!dentroDeCDMX(lat, lng)) {
        mostrarError('El punto seleccionado está fuera de la Ciudad de México.');
        return;
    }

    ocultarError();
    geocodificacionInversa(lat, lng, function (direccion) {
        if (!origen) {
            origen = { lat: lat, lng: lng, direccion: direccion };
            document.getElementById('input-origen').value = direccion;
            ponerMarcador('origen', lat, lng);
        } else {
            destino = { lat: lat, lng: lng, direccion: direccion };
            document.getElementById('input-destino').value = direccion;
            ponerMarcador('destino', lat, lng);
            calcularRuta();
        }
    });
}

function ponerMarcador(tipo, lat, lng) {
    var color = tipo === 'origen' ? '#1D9E75' : '#D85A30';
    var pos   = [lng, lat];

    if (tipo === 'origen') {
        if (marcadorOrigen) mapa.markers.remove(marcadorOrigen);
        marcadorOrigen = new atlas.HtmlMarker({ color: color, position: pos });
        mapa.markers.add(marcadorOrigen);
    } else {
        if (marcadorDestino) mapa.markers.remove(marcadorDestino);
        marcadorDestino = new atlas.HtmlMarker({ color: color, position: pos });
        mapa.markers.add(marcadorDestino);
    }
}

function calcularRuta() {
    if (!origen || !destino) return;

    var url = 'https://atlas.microsoft.com/route/directions/json' +
        '?api-version=1.0' +
        '&query=' + origen.lat + ',' + origen.lng + ':' + destino.lat + ',' + destino.lng +
        '&travelMode=car&language=es-MX' +
        '&subscription-key=' + AZURE_KEY;

    fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var ruta    = data.routes[0];
            var sumario = ruta.summary;
            var distKm  = (sumario.lengthInMeters / 1000).toFixed(2);
            var etaMin  = Math.ceil(sumario.travelTimeInSeconds / 60);
            var precio  = 15.0 + (parseFloat(distKm) * 8.5) + 3.0;

            document.getElementById('r-distancia').textContent = distKm + ' km';
            document.getElementById('r-eta').textContent       = etaMin + ' min';
            document.getElementById('r-costo-km').textContent  = '$' + (parseFloat(distKm) * 8.5).toFixed(2);
            document.getElementById('r-total').textContent     = '$' + precio.toFixed(2);

            document.getElementById('resumen').classList.add('visible');
            document.getElementById('btn-confirmar').classList.add('visible');

            document.getElementById('f-origen-lat').value  = origen.lat;
            document.getElementById('f-origen-lng').value  = origen.lng;
            document.getElementById('f-origen-dir').value  = origen.direccion;
            document.getElementById('f-destino-lat').value = destino.lat;
            document.getElementById('f-destino-lng').value = destino.lng;
            document.getElementById('f-destino-dir').value = destino.direccion;
            document.getElementById('f-distancia').value   = distKm;
            document.getElementById('f-eta').value         = etaMin;

            dibujarRuta(ruta.legs[0].points);
        })
        .catch(function () {
            mostrarError('Error al calcular la ruta. Verifica tu clave de Azure Maps.');
        });
}

function dibujarRuta(puntos) {
    var coords = puntos.map(function (p) { return [p.longitude, p.latitude]; });

    // Eliminar capa y fuente anteriores si existen
    if (mapa.layers.getLayerById('ruta-layer')) {
        mapa.layers.remove('ruta-layer');
    }
    if (mapa.sources.getById('ruta-source')) {
        mapa.sources.remove('ruta-source');
    }

    var source = new atlas.source.DataSource('ruta-source');
    mapa.sources.add(source);
    source.add(new atlas.data.LineString(coords));

    lineaRuta = new atlas.layer.LineLayer(source, 'ruta-layer', {
        strokeColor: '#1D9E75',
        strokeWidth: 4
    });

    mapa.layers.add(lineaRuta);

    var positions = coords.map(function (c) {
        return new atlas.data.Position(c[0], c[1]);
    });

    mapa.setCamera({
        bounds: atlas.data.BoundingBox.fromPositions(positions),
        padding: 60
    });
}

function geocodificacionInversa(lat, lng, callback) {
    var url = 'https://atlas.microsoft.com/search/address/reverse/json' +
        '?api-version=1.0&query=' + lat + ',' + lng +
        '&language=es-MX&subscription-key=' + AZURE_KEY;

    fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var addr = data.addresses && data.addresses[0] && data.addresses[0].address;
            var dir  = addr
                ? ((addr.streetName || '') + ' ' + (addr.streetNumber || '') +
                   (addr.municipalitySubdivision ? ', ' + addr.municipalitySubdivision : ''))
                : (lat.toFixed(5) + ', ' + lng.toFixed(5));
            callback(dir.trim());
        })
        .catch(function () {
            callback(lat.toFixed(5) + ', ' + lng.toFixed(5));
        });
}

function buscarDireccion(texto) {
    if (!texto.trim()) return;

    var url = 'https://atlas.microsoft.com/search/address/json' +
        '?api-version=1.0&query=' + encodeURIComponent(texto + ' Ciudad de México') +
        '&language=es-MX&countrySet=MX&subscription-key=' + AZURE_KEY;

    fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
            var resultado = data.results && data.results[0];
            if (!resultado) {
                mostrarError('No se encontró esa dirección.');
                return;
            }
            var lat = resultado.position.lat;
            var lng = resultado.position.lon;

            if (!dentroDeCDMX(lat, lng)) {
                mostrarError('La dirección está fuera de la Ciudad de México.');
                return;
            }

            ocultarError();
            destino = { lat: lat, lng: lng, direccion: resultado.address.freeformAddress };
            document.getElementById('input-destino').value = destino.direccion;
            ponerMarcador('destino', lat, lng);
            if (origen) calcularRuta();
            else mapa.setCamera({ center: [lng, lat], zoom: 15 });
        })
        .catch(function () { mostrarError('Error al buscar la dirección.'); });
}

function usarUbicacionActual() {
    if (!navigator.geolocation) {
        mostrarError('Tu navegador no soporta geolocalización.');
        return;
    }

    navigator.geolocation.getCurrentPosition(
        function (pos) {
            var lat = pos.coords.latitude;
            var lng = pos.coords.longitude;

            if (!dentroDeCDMX(lat, lng)) {
                mostrarError('Tu ubicación actual está fuera de la Ciudad de México.');
                return;
            }

            ocultarError();
            geocodificacionInversa(lat, lng, function (direccion) {
                origen = { lat: lat, lng: lng, direccion: direccion };
                document.getElementById('input-origen').value = direccion;
                ponerMarcador('origen', lat, lng);
                mapa.setCamera({ center: [lng, lat], zoom: 15 });
                if (destino) calcularRuta();
            });
        },
        function () {
            mostrarError('No se pudo obtener tu ubicación. Selecciónala en el mapa.');
        }
    );
}

function confirmarViaje() {
    if (!origen || !destino) {
        mostrarError('Selecciona origen y destino antes de continuar.');
        return;
    }
    document.getElementById('form-viaje').submit();
}

function dentroDeCDMX(lat, lng) {
    return lat >= CDMX_BOUNDS.sur  && lat <= CDMX_BOUNDS.norte &&
           lng >= CDMX_BOUNDS.oeste && lng <= CDMX_BOUNDS.este;
}

function mostrarError(msg) {
    var el = document.getElementById('alerta');
    el.textContent = msg;
    el.classList.add('visible');
}

function ocultarError() {
    document.getElementById('alerta').classList.remove('visible');
}
