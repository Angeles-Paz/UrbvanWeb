<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Solicitar viaje</title>
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
        #mapa{width:100%;height:460px;border-radius:12px;overflow:hidden;border:1px solid var(--borde)}
        .panel-lateral{background:var(--surface);border:1px solid var(--borde);border-radius:14px;padding:22px}
        .info-row{display:flex;justify-content:space-between;padding:10px 0;border-bottom:1px solid var(--borde);font-size:14px}
        .info-row:last-child{border-bottom:none}
        .info-label{color:var(--texto2)} .info-val{font-weight:600}
        .layout{display:grid;grid-template-columns:1fr 340px;gap:20px;align-items:start}
        .instruccion{color:var(--texto2);font-size:13px;margin-bottom:12px;background:var(--surface2);padding:10px 14px;border-radius:8px}
        .unidad-card{border:1px solid var(--borde);border-radius:12px;padding:12px;margin:10px 0;background:var(--surface2)}
        .unidad-card strong{display:block;color:var(--texto);margin-bottom:3px}
        .unidad-card small{color:var(--texto2)}
        @media(max-width:768px){.layout{grid-template-columns:1fr}}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" height="200"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/pasajero/dashboard">Inicio</a>
        <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="activo">Nuevo viaje</a>
        <a href="${pageContext.request.contextPath}/pasajero/historial">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Solicitar viaje</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <div class="layout">
        <div>
            <p class="instruccion">
                📍 Primer clic → <strong style="color:#10b981">origen</strong> &nbsp;|&nbsp;
                Segundo clic → <strong style="color:#ef4444">destino</strong>.
                Puedes hacer clic de nuevo para reposicionar.
            </p>
            <%-- id="mapa" - corregido de "map" --%>
            <div id="mapa"></div>
        </div>
        <div class="panel-lateral">
            <div class="card-title">Resumen del viaje</div>
            <div class="info-row"><span class="info-label">Origen</span><span class="info-val" id="lblOrigen" style="max-width:160px;text-align:right;font-size:13px">-</span></div>
            <div class="info-row"><span class="info-label">Destino</span><span class="info-val" id="lblDestino" style="max-width:160px;text-align:right;font-size:13px">-</span></div>
            <div class="info-row"><span class="info-label">Distancia</span><span class="info-val" id="lblDistancia">-</span></div>
            <div class="info-row"><span class="info-label">Tiempo est.</span><span class="info-val" id="lblDuracion">-</span></div>
            <div class="info-row">
                <span class="info-label">Costo est.</span>
                <span class="info-val" id="lblCosto" style="color:#10b981;font-size:20px">-</span>
            </div>

            <div class="form-group" style="margin-top:16px">
                <label class="form-label">Unidad y capacidad</label>
                <select id="vehiculoId" name="vehiculoId" form="formViaje" required>
                    <option value="">Selecciona una unidad</option>
                    <c:forEach var="unidad" items="${vehiculosB2C}">
                        <option value="${unidad.id}">
                            ${unidad.modelo} · ${unidad.capacidad} pasajeros · ${unidad.placa}
                        </option>
                    </c:forEach>
                </select>
                <c:if test="${empty vehiculosB2C}">
                    <p style="color:#ef4444;font-size:12px;margin-top:6px">
                        No hay unidades B2C disponibles. Revisa vehículos activos en el panel de administrador.
                    </p>
                </c:if>
            </div>
            <div class="form-group" style="margin-top:16px">
                <label class="form-label">Método de pago</label>
                <select id="metodoPago" onchange="document.getElementById('fMetodoPago').value=this.value">
                    <option value="efectivo">💵 Efectivo</option>
                    <option value="tarjeta">💳 Tarjeta (simulado)</option>
                </select>
            </div>
            <form id="formViaje" method="post" action="${pageContext.request.contextPath}/pasajero/solicitar">
                <input type="hidden" id="origenLat"    name="origenLat">
                <input type="hidden" id="origenLng"    name="origenLng">
                <input type="hidden" id="origenNombre" name="origenNombre">
                <input type="hidden" id="destinoLat"   name="destinoLat">
                <input type="hidden" id="destinoLng"   name="destinoLng">
                <input type="hidden" id="destinoNombre"name="destinoNombre">
                <input type="hidden" id="distanciaKm"  name="distanciaKm">
                <input type="hidden" id="duracionMin"  name="duracionMin">
                <input type="hidden" id="costoBase"    name="costoBase" value="35">
                <input type="hidden" id="costoPorKm"   name="costoPorKm" value="12">
                <input type="hidden" id="fMetodoPago"  name="metodoPago" value="efectivo">
                <button type="submit" id="btnSolicitar"
                        class="btn btn-primary"
                        style="width:100%;margin-top:8px;justify-content:center;padding:14px"
                        disabled>
                    Continuar al pago →
                </button>
            </form>
            <p id="msgMapa" style="color:var(--texto2);font-size:12px;text-align:center;margin-top:8px">
                Haz clic en el mapa para colocar el origen 🟢
            </p>
        </div>
    </div>
</div>

<%-- AZURE_KEY inyectada desde context-param de web.xml ANTES del SDK --%>
<script>
    const AZURE_KEY = '<%= application.getInitParameter("azure.maps.key") %>';
</script>
<%-- SDK v3 (el proyecto original usa v3) --%>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/mapa.js?v=5"></script>
</body>
</html>
