<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Historial</title>
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
        <a href="${pageContext.request.contextPath}/pasajero/solicitar">Nuevo viaje</a>
        <a href="${pageContext.request.contextPath}/pasajero/perfil">Perfil</a>
        <a href="${pageContext.request.contextPath}/pasajero/historial" class="activo">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Mis viajes</div>
    <div class="page-sub">Registro completo de tus viajes en Urbvan</div>
    <c:if test="${param.calificado == 'ok'}"><div class="alerta-ok">¡Calificación enviada correctamente!</div></c:if>
    <div class="card">
        <c:choose>
            <c:when test="${empty viajes}">
                <div class="empty">Aún no tienes viajes registrados.</div>
            </c:when>
            <c:otherwise>
                <table>
                    <tr><th>Origen</th><th>Destino</th><th>Distancia</th><th>Costo</th><th>Estado</th><th>Operador</th><th></th></tr>
                    <c:forEach var="v" items="${viajes}">
                        <tr>
                            <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${v.origenNombre}</td>
                            <td style="max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${v.destinoNombre}</td>
                            <td>${v.distanciaKm} km</td>
                            <td>$${v.costo}</td>
                            <td>
                                <c:choose>
                                    <c:when test="${v.estado == 'COMPLETADO'}"><span class="badge badge-verde">Completado</span></c:when>
                                    <c:when test="${v.estado == 'CANCELADO'}"><span class="badge badge-rojo">Cancelado</span></c:when>
                                    <c:otherwise><span class="badge badge-naranja">En curso</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td>${empty v.operadorNombre ? '-' : v.operadorNombre}</td>
                            <td>
                                <c:if test="${v.estado == 'COMPLETADO' && v.calificacionDada < 0}">
                                    <a href="${pageContext.request.contextPath}/pasajero/calificar?viajeId=${v.id}" class="btn btn-primary btn-sm">Calificar</a>
                                </c:if>
                                <c:if test="${v.calificacionDada >= 0}">
                                    <span style="color:#f59e0b;font-size:13px">★ ${v.calificacionDada}/100</span>
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
