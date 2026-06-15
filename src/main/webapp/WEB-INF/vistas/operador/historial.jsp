<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Historial operador</title>
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
        <a href="${pageContext.request.contextPath}/operador/rutas-b2b">Rutas B2B</a>
        <a href="${pageContext.request.contextPath}/operador/historial" class="activo">Historial</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Historial del operador</div>
    <div class="page-sub">Consulta tus viajes normales y tus rutas corporativas asignadas.</div>

    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>

    <div class="card" style="margin-bottom:20px">
        <div class="card-title">Viajes B2C</div>
        <c:choose>
            <c:when test="${empty viajes}">
                <div class="empty">Aún no tienes viajes B2C registrados.</div>
            </c:when>
            <c:otherwise>
                <table>
                    <tr><th>#</th><th>Pasajero</th><th>Origen</th><th>Destino</th><th>Costo</th><th>Estado</th></tr>
                    <c:forEach var="v" items="${viajes}">
                        <tr>
                            <td style="color:var(--texto2)">#${v.id}</td>
                            <td>${v.pasajeroNombre}</td>
                            <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${v.origenNombre}</td>
                            <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${v.destinoNombre}</td>
                            <td>$${v.costo}</td>
                            <td><span class="badge ${v.estadoClase}">${v.estadoTexto}</span></td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>

    <div class="card">
        <div class="card-title">Rutas B2B corporativas</div>
        <c:choose>
            <c:when test="${empty rutasB2B}">
                <div class="empty">Aún no tienes rutas B2B registradas.</div>
            </c:when>
            <c:otherwise>
                <table>
                    <tr><th>#</th><th>Empresa</th><th>Fecha inicio</th><th>Unidad</th><th>Pasajeros</th><th>Estado</th><th></th></tr>
                    <c:forEach var="r" items="${rutasB2B}">
                        <tr>
                            <td style="color:var(--texto2)">#${r.id}</td>
                            <td style="font-weight:500">${r.empresaNombre}</td>
                            <td>${r.fechaInicio}</td>
                            <td>${r.vehiculoModelo} · ${r.vehiculoPlaca}</td>
                            <td>${r.asientosOcupados}/${r.vehiculoCapacidad}</td>
                            <td><span class="badge ${r.estadoClase}">${r.estadoTexto}</span></td>
                            <td><a href="${pageContext.request.contextPath}/b2b/ruta/detalle?rutaId=${r.id}" class="btn btn-ghost btn-sm">Ver detalle</a></td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
</body>
</html>
