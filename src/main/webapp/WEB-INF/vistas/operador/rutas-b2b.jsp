<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Mis rutas B2B</title>
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
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/operador/panel">Viajes B2C</a>
        <a href="${pageContext.request.contextPath}/operador/rutas-b2b" class="activo">Rutas B2B</a>
        <a href="${pageContext.request.contextPath}/operador/historial">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Mis rutas corporativas</div>
    <div class="page-sub">Rutas B2B asignadas a tu vehículo</div>
    <c:if test="${param.calificado == 'ok'}"><div class="alerta-ok">✓ Calificación enviada.</div></c:if>

    <c:if test="${not empty notificaciones}">
        <div class="card" style="margin-bottom:20px">
            <div class="card-title"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg> Notificaciones</div>
            <c:forEach var="n" items="${notificaciones}">
                <div style="padding:10px 0;border-bottom:1px solid var(--borde);font-size:14px">${n.mensaje}</div>
            </c:forEach>
            <form method="post" action="${pageContext.request.contextPath}/notificaciones" style="margin-top:12px">
                <input type="hidden" name="id" value="all">
                <button type="submit" class="btn btn-ghost btn-sm">Marcar todas leídas</button>
            </form>
        </div>
    </c:if>

    <div class="card">
        <c:choose>
            <c:when test="${empty rutas}"><div class="empty">Sin rutas B2B asignadas.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>#</th><th>Empresa</th><th>Fecha inicio</th><th>Pasajeros</th><th>Estado</th><th>Acciones</th></tr>
                    <c:forEach var="r" items="${rutas}">
                        <tr>
                            <td style="color:var(--texto2)">#${r.id}</td>
                            <td style="font-weight:500">${r.empresaNombre}</td>
                            <td>${r.fechaInicio}</td>
                            <td>${r.asientosOcupados}/${r.vehiculoCapacidad}</td>
                            <td><span class="badge ${r.estadoClase}">${r.estadoTexto}</span></td>
                            <td>
                                <a href="${pageContext.request.contextPath}/b2b/ruta/detalle?rutaId=${r.id}" class="btn btn-ghost btn-sm">Ver detalles</a>
                                <c:if test="${r.estadoNombre == 'COMPLETADA'}">
                                    <a href="${pageContext.request.contextPath}/operador/calificar-empresa?rutaId=${r.id}" class="btn btn-naranja btn-sm">Calificar empresa</a>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
</body>
</html>
