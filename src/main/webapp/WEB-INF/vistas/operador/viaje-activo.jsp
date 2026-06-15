<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Viaje activo</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#d98b25;
        --role-dark:#B87020;
        --role-light:#FFF8EE;
        --role-subtle:rgba(217,139,37,.1);
    }
    </style>
    <%-- SDK v3 --%>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css">
    <style>
        #mapa{width:100%;height:400px;border-radius:12px;overflow:hidden;border:1px solid var(--borde);margin-bottom:20px}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/operador/panel">Panel</a>
        <a href="${pageContext.request.contextPath}/operador/rutas-b2b">Rutas B2B</a>
        <a href="${pageContext.request.contextPath}/operador/historial">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main" style="max-width:680px">
    <div class="page-title">Viaje #${viaje.id} en curso</div>
    <div class="page-sub">Pasajero: ${viaje.pasajeroNombre} · $${viaje.costo}</div>

    <%-- id="mapa" - corregido de "map" --%>
    <div id="mapa"></div>

    <div class="card" style="margin-bottom:16px">
        <div class="card-title">Ruta</div>
        <div style="display:flex;flex-direction:column;gap:10px">
            <div style="display:flex;gap:10px">
                <span style="color:#10b981;font-size:18px">●</span>
                <div><div style="font-size:11px;color:var(--texto2)">ORIGEN</div><div style="font-weight:500">${viaje.origenNombre}</div></div>
            </div>
            <div style="display:flex;gap:10px">
                <span style="color:#ef4444;font-size:18px">●</span>
                <div><div style="font-size:11px;color:var(--texto2)">DESTINO</div><div style="font-weight:500">${viaje.destinoNombre}</div></div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-title">Cambiar estado del viaje</div>
        <div style="display:flex;flex-wrap:wrap;gap:10px">
            <c:if test="${viaje.estado == 'ACEPTADO'}">
                <form method="post" action="${pageContext.request.contextPath}/operador/cambiar-estado">
                    <input type="hidden" name="viajeId" value="${viaje.id}">
                    <input type="hidden" name="accion" value="en_camino">
                    <button type="submit" class="btn btn-naranja">Pasajero a bordo</button>
                </form>
            </c:if>
            <c:if test="${viaje.estado == 'ACEPTADO' || viaje.estado == 'EN_CAMINO'}">
                <form method="post" action="${pageContext.request.contextPath}/operador/cambiar-estado">
                    <input type="hidden" name="viajeId" value="${viaje.id}">
                    <input type="hidden" name="accion" value="completar">
                    <button type="submit" class="btn btn-primary">✓ Completar viaje</button>
                </form>
                <form method="post" action="${pageContext.request.contextPath}/operador/cambiar-estado">
                    <input type="hidden" name="viajeId" value="${viaje.id}">
                    <input type="hidden" name="accion" value="cancelar">
                    <button type="submit" class="btn btn-danger">✗ Cancelar</button>
                </form>
            </c:if>
        </div>
    </div>
</div>

<%-- Variables para seguimiento.js - ANTES de cargar el SDK --%>
<script>
    const AZURE_KEY     = '<%= application.getInitParameter("azure.maps.key") %>';
    const VIAJE_ORIGEN  = [${viaje.origenLng},  ${viaje.origenLat}];
    const VIAJE_DESTINO = [${viaje.destinoLng}, ${viaje.destinoLat}];
    var ORIGEN_LNG = VIAJE_ORIGEN[0];
    var ORIGEN_LAT = VIAJE_ORIGEN[1];
    var DESTINO_LNG = VIAJE_DESTINO[0];
    var DESTINO_LAT = VIAJE_DESTINO[1];
    const ESTADO_VIAJE_INICIAL = '${viaje.estadoNombre}';
    const MODO_OPERADOR = true;
</script>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/seguimiento.js?v=5"></script>

<script>
    // Actualizar posición GPS del operador cada 10 segundos
    function actualizarPosicion() {
        if (!navigator.geolocation) return;
        navigator.geolocation.getCurrentPosition(function (pos) {
            fetch('${pageContext.request.contextPath}/operador/actualizar-posicion', {
                method:  'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body:    'lat=' + pos.coords.latitude + '&lng=' + pos.coords.longitude
            });
        });
    }
    actualizarPosicion();
    setInterval(actualizarPosicion, 10000);
</script>
</body>
</html>
