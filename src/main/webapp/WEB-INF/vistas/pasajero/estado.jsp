<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Estado del viaje</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#00C896;
        --role-dark:#00A07A;
        --role-light:#EDFFF9;
        --role-subtle:rgba(0,200,150,.1);
    }
    </style>
    <%-- SDK v3 --%>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css">
    <style>
        #mapa{width:100%;height:380px;border-radius:12px;overflow:hidden;border:1px solid var(--borde)}
        .estado-pill{display:inline-flex;align-items:center;gap:8px;padding:10px 20px;border-radius:30px;font-weight:600;font-size:15px}
        .operador-card{background:var(--surface2);border-radius:12px;padding:16px;display:flex;align-items:center;gap:14px;margin:16px 0}
        .avatar{width:44px;height:44px;background:var(--role);border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:20px}
        .modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}
        .modal-overlay.visible{display:flex}
        .modal{background:var(--surface);border-radius:16px;padding:32px;max-width:400px;width:90%;text-align:center}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/pasajero/dashboard">Inicio</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main" style="max-width:680px">
    <c:choose>
        <c:when test="${not empty viaje}">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px;flex-wrap:wrap;gap:12px">
                <div>
                    <div class="page-title">Viaje #${viaje.id}</div>
                    <div class="page-sub">${viaje.origenNombre} → ${viaje.destinoNombre}</div>
                </div>
                <c:choose>
                    <c:when test="${viaje.estado == 'SOLICITADO'}"><span class="estado-pill" style="background:#fef9c3;color:#854d0e">Buscando operador...</span></c:when>
                    <c:when test="${viaje.estado == 'ASIGNADO'}"><span class="estado-pill" style="background:#dbeafe;color:#1e40af">Esperando aceptación</span></c:when>
                    <c:when test="${viaje.estado == 'ACEPTADO'}"><span class="estado-pill" style="background:#d1fae5;color:#065f46">Operador en camino</span></c:when>
                    <c:when test="${viaje.estado == 'EN_CAMINO'}"><span class="estado-pill" style="background:#d1fae5;color:#065f46">En camino al destino</span></c:when>
                    <c:when test="${viaje.estado == 'EN_CURSO'}"><span class="estado-pill" style="background:#ede9fe;color:#4c1d95">Viaje en curso</span></c:when>
                    <c:when test="${viaje.estado == 'COMPLETADO'}"><span class="estado-pill" style="background:#d1fae5;color:#065f46">Completado</span></c:when>
                    <c:when test="${viaje.estado == 'CANCELADO'}"><span class="estado-pill" style="background:#fee2e2;color:#991b1b">Cancelado</span></c:when>
                </c:choose>
            </div>

            <c:if test="${viaje.operadorId > 0}">
                <div class="operador-card">
                    <div class="avatar"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg></div>
                    <div>
                        <div style="font-weight:600">${viaje.operadorNombre}</div>
                        <div style="color:var(--texto2);font-size:13px">
                            Operador · <span class="score">${viaje.operadorScore}</span>
                            · ${viaje.vehiculoModelo} ${viaje.vehiculoPlaca}
                        </div>
                    </div>
                </div>
            </c:if>

            <%-- Contenedor del mapa - id="mapa" (corregido de "map") --%>
            <div id="mapa" style="margin-bottom:20px"></div>

            <div style="display:flex;gap:12px;flex-wrap:wrap">
                <c:if test="${viaje.estado != 'COMPLETADO' && viaje.estado != 'CANCELADO' && viaje.estado != 'EN_CAMINO' && viaje.estado != 'EN_CURSO'}">
                    <button onclick="document.getElementById('modalCancelar').classList.add('visible')" class="btn btn-danger">Cancelar viaje</button>
                </c:if>
                <c:if test="${viaje.estado == 'COMPLETADO' && viaje.calificacionDada < 0}">
                    <a href="${pageContext.request.contextPath}/pasajero/calificar?viajeId=${viaje.id}" class="btn btn-primary">⭐ Calificar operador</a>
                </c:if>
                <c:if test="${viaje.estado == 'COMPLETADO' || viaje.estado == 'CANCELADO'}">
                    <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="btn btn-ghost">Nuevo viaje</a>
                </c:if>
            </div>
        </c:when>
        <c:otherwise>
            <div class="empty" style="padding:80px 0">
                <div style="font-size:48px;margin-bottom:16px"><svg width="44" height="44" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="color:var(--role)"><path d="M8 6v6M15 6v6M2 12h19.6M18 18h2a1 1 0 001-1V9a1 1 0 00-1-1H4a1 1 0 00-1 1v8a1 1 0 001 1h2"/><circle cx="7" cy="18" r="2"/><circle cx="15" cy="18" r="2"/></svg></div>
                <div style="font-size:18px;margin-bottom:8px">Sin viaje activo</div>
                <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="btn btn-primary" style="margin-top:16px">Solicitar viaje</a>
            </div>
        </c:otherwise>
    </c:choose>
</div>

<div class="modal-overlay" id="modalCancelar">
    <div class="modal">
        <h3 style="font-size:20px;margin-bottom:12px">¿Cancelar el viaje?</h3>
        <p style="color:var(--texto2);font-size:14px;margin-bottom:24px">Esta acción no se puede deshacer.</p>
        <div style="display:flex;gap:12px;justify-content:center">
            <button onclick="document.getElementById('modalCancelar').classList.remove('visible')" class="btn btn-ghost">No, mantener</button>
            <form method="post" action="${pageContext.request.contextPath}/pasajero/cancelar-viaje" style="display:inline">
                <button type="submit" class="btn btn-danger">Sí, cancelar</button>
            </form>
        </div>
    </div>
</div>

<%-- Inyectar variables para seguimiento.js ANTES de cargar el script --%>
<c:if test="${not empty viaje}">
<script>
    const AZURE_KEY     = '<%= application.getInitParameter("azure.maps.key") %>';
    // Azure Maps usa [longitude, latitude] - orden inverso al de Java
    const VIAJE_ORIGEN  = [${viaje.origenLng},  ${viaje.origenLat}];
    const VIAJE_DESTINO = [${viaje.destinoLng}, ${viaje.destinoLat}];
    var ORIGEN_LNG = VIAJE_ORIGEN[0];
    var ORIGEN_LAT = VIAJE_ORIGEN[1];
    var DESTINO_LNG = VIAJE_DESTINO[0];
    var DESTINO_LAT = VIAJE_DESTINO[1];
    <c:if test="${viaje.operadorId > 0}">
    const OPERADOR_LAT  = 0;
    const OPERADOR_LNG  = 0;
    const TRACKING_URL  = '${pageContext.request.contextPath}/pasajero/tracking-data';
    </c:if>
</script>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/seguimiento.js?v=5"></script>
</c:if>

<%-- El mapa se actualiza en vivo con /pasajero/tracking-data sin recargar toda la página. --%>
</body>
</html>
