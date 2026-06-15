<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Panel operador</title>
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
    <style>
        .solicitud-card{background:var(--surface);border:1px solid var(--borde);border-radius:14px;padding:20px;margin-bottom:16px;transition:border-color .2s}
        .solicitud-card:hover{border-color:#f97316}
        .ruta-visual{display:flex;flex-direction:column;gap:6px;padding:12px 0}
        .ruta-punto{display:flex;gap:10px;align-items:flex-start;font-size:14px}
        .dot{width:10px;height:10px;border-radius:50%;margin-top:4px;flex-shrink:0}
        .dot-verde{background:#10b981}.dot-rojo{background:#ef4444}
        .btn-group{display:flex;gap:10px;margin-top:16px}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/operador/panel" class="activo">Panel</a>
        <a href="${pageContext.request.contextPath}/operador/rutas-b2b">Rutas B2B</a>
        <a href="${pageContext.request.contextPath}/operador/historial">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Hola, ${sessionScope.nombre}</div>
    <div class="page-sub">Solicitudes de viaje pendientes para ti</div>

    <c:choose>
        <c:when test="${empty solicitudes}">
            <div class="card" style="text-align:center;padding:60px 24px">
                <div style="font-size:48px;margin-bottom:16px"><svg width="42" height="42" viewBox="0 0 24 24" fill="none" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="8" fill="#D1FAE5"/><circle cx="12" cy="12" r="4" fill="#10b981"/></svg></div>
                <div style="font-size:18px;font-weight:600;margin-bottom:8px">Sin solicitudes activas</div>
                <div style="color:var(--texto2);font-size:14px">La página se actualiza automáticamente cuando llegue una solicitud.</div>
            </div>
        </c:when>
        <c:otherwise>
            <c:forEach var="s" items="${solicitudes}">
                <div class="solicitud-card">
                    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px">
                        <span style="font-weight:600">Viaje #${s.id}</span>
                        <span style="color:var(--texto2);font-size:13px">$${s.costo}</span>
                    </div>
                    <div class="ruta-visual">
                        <div class="ruta-punto"><div class="dot dot-verde"></div><span>${s.origenNombre}</span></div>
                        <div style="padding-left:14px;color:var(--texto3);font-size:12px">↓ ${s.distanciaKm} km</div>
                        <div class="ruta-punto"><div class="dot dot-rojo"></div><span>${s.destinoNombre}</span></div>
                    </div>
                    <div style="color:var(--texto2);font-size:13px">Pasajero: ${s.pasajeroNombre}</div>
                    <div class="btn-group">
                        <form method="post" action="${pageContext.request.contextPath}/operador/responder-solicitud" style="display:inline">
                            <input type="hidden" name="viajeId" value="${s.id}">
                            <input type="hidden" name="respuesta" value="aceptar">
                            <button type="submit" class="btn btn-primary">✓ Aceptar</button>
                        </form>
                        <form method="post" action="${pageContext.request.contextPath}/operador/responder-solicitud" style="display:inline">
                            <input type="hidden" name="viajeId" value="${s.id}">
                            <input type="hidden" name="respuesta" value="rechazar">
                            <button type="submit" class="btn btn-ghost">✗ Rechazar</button>
                        </form>
                    </div>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>
</div>
<script>
  // Polling: recarga si no hay viaje activo para detectar nuevas solicitudes
  setTimeout(function(){location.reload()}, 5000);
</script>
</body>
</html>
