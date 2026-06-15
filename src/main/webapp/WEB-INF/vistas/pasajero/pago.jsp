<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Confirmar pago</title>
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
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/pasajero/dashboard">Inicio</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main" style="max-width:520px">
    <div class="page-title">Confirmar viaje</div>
    <div class="page-sub">Revisa los detalles antes de confirmar</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${not empty viaje}">
        <div class="card" style="margin-bottom:20px">
            <div class="card-title">Detalles del viaje</div>
            <div style="display:flex;flex-direction:column;gap:12px">
                <div style="display:flex;gap:12px;align-items:flex-start">
                    <span style="color:#10b981;font-size:18px">●</span>
                    <div><div style="font-size:12px;color:var(--texto2)">ORIGEN</div><div style="font-weight:500">${viaje.origenNombre}</div></div>
                </div>
                <div style="display:flex;gap:12px;align-items:flex-start">
                    <span style="color:#ef4444;font-size:18px">●</span>
                    <div><div style="font-size:12px;color:var(--texto2)">DESTINO</div><div style="font-weight:500">${viaje.destinoNombre}</div></div>
                </div>
            </div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:20px">
                <div style="background:var(--surface2);border-radius:10px;padding:14px;text-align:center">
                    <div style="color:var(--texto2);font-size:12px">DISTANCIA</div>
                    <div style="font-weight:700;font-size:18px">${viaje.distanciaKm} km</div>
                </div>
                <div style="background:var(--surface2);border-radius:10px;padding:14px;text-align:center">
                    <div style="color:var(--texto2);font-size:12px">TIEMPO EST.</div>
                    <div style="font-weight:700;font-size:18px">${viaje.duracionMin} min</div>
                </div>
            </div>
            <div style="background:var(--role);border-radius:10px;padding:16px;text-align:center;margin-top:12px">
                <div style="color:rgba(255,255,255,.8);font-size:12px">TOTAL A PAGAR</div>
                <div style="color:#fff;font-weight:700;font-size:28px">$${viaje.costo}</div>
                <div style="color:rgba(255,255,255,.8);font-size:12px">${viaje.metodoPago == 'tarjeta' ? 'Tarjeta (simulado)' : 'Efectivo'}</div>
            </div>
        </div>
        <form method="post" action="${pageContext.request.contextPath}/pasajero/pago">
            <button type="submit" class="btn btn-primary" style="width:100%;justify-content:center;padding:16px;font-size:16px">
                ✓ Confirmar y buscar operador
            </button>
        </form>
        <a href="${pageContext.request.contextPath}/pasajero/modificar-viaje" style="display:block;text-align:center;margin-top:14px;color:var(--texto2);font-size:14px;text-decoration:none">← Modificar ruta</a>
    </c:if>
</div>
</body>
</html>
