<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Mi cuenta</title>
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
        <a href="${pageContext.request.contextPath}/pasajero/dashboard" class="activo">Inicio</a>
        <a href="${pageContext.request.contextPath}/pasajero/solicitar">Nuevo viaje</a>
        <a href="${pageContext.request.contextPath}/pasajero/perfil">Perfil</a>
        <a href="${pageContext.request.contextPath}/pasajero/historial">Historial</a>
        <c:if test="${sessionScope.esEmpleado}">
            <a href="${pageContext.request.contextPath}/b2b/empleado/rutas" style="color:#06b6d4;font-weight:600">Mis rutas B2B</a>
        </c:if>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Hola, ${sessionScope.nombre}</div>
    <div class="page-sub">${usuario.email}</div>

    <%-- Banner B2B para empleados --%>
    <c:if test="${sessionScope.esEmpleado}">
        <div class="card" style="margin-bottom:20px;border-color:#06b6d4;background:linear-gradient(135deg,var(--surface) 0%,rgba(6,182,212,.08) 100%)">
            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:12px">
                <div>
                    <div style="font-weight:700;font-size:16px;margin-bottom:4px">&#x1F3E2; Acceso corporativo activo</div>
                    <div style="color:var(--texto2);font-size:13px">Tu empresa te ha agregado como empleado B2B.</div>
                </div>
                <a href="${pageContext.request.contextPath}/b2b/empleado/rutas" class="btn" style="background:var(--role);color:#fff">
                    Ver mis rutas B2B
                </a>
            </div>
        </div>
    </c:if>

    <%-- Viaje activo --%>
    <c:if test="${not empty viajeActivo}">
        <div class="card" style="margin-bottom:20px;border-color:#10b981">
            <div class="card-title" style="color:#10b981">&#x1F697; Viaje en curso</div>
            <p style="color:var(--texto2);font-size:14px;margin-bottom:16px">
                ${viajeActivo.origenNombre} &#8594; ${viajeActivo.destinoNombre}
            </p>
            <a href="${pageContext.request.contextPath}/pasajero/estado-viaje" class="btn btn-primary">Ver estado del viaje</a>
        </div>
    </c:if>

    <c:if test="${empty viajeActivo}">
        <div class="card" style="margin-bottom:20px;text-align:center;padding:36px">
            <div style="font-size:40px;margin-bottom:12px">&#x1F5FA;&#xFE0F;</div>
            <div class="card-title">A donde vamos?</div>
            <p style="color:var(--texto2);font-size:14px;margin-bottom:20px">Solicita un viaje y te asignamos un operador.</p>
            <a href="${pageContext.request.contextPath}/pasajero/solicitar" class="btn btn-primary">Solicitar viaje</a>
        </div>
    </c:if>

    <%-- Historial reciente --%>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
            <span class="card-title" style="margin:0">Viajes recientes</span>
            <a href="${pageContext.request.contextPath}/pasajero/perfil">Perfil</a>
        <a href="${pageContext.request.contextPath}/pasajero/historial" style="color:#10b981;font-size:13px;text-decoration:none">Ver todos (${totalViajes})</a>
        </div>
        <c:choose>
            <c:when test="${empty historial}">
                <div class="empty">Aun no tienes viajes registrados.</div>
            </c:when>
            <c:otherwise>
                <table>
                    <tr><th>Destino</th><th>Costo</th><th>Estado</th><th></th></tr>
                    <c:forEach var="v" items="${historial}">
                        <tr>
                            <td>${v.destinoNombre}</td>
                            <td>$${v.costo}</td>
                            <td>
                                <c:choose>
                                    <c:when test="${v.estado == 'COMPLETADO'}"><span class="badge badge-verde">Completado</span></c:when>
                                    <c:when test="${v.estado == 'CANCELADO'}"><span class="badge badge-rojo">Cancelado</span></c:when>
                                    <c:otherwise><span class="badge badge-naranja">En curso</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <c:if test="${v.estado == 'COMPLETADO' && v.calificacionDada < 0}">
                                    <a href="${pageContext.request.contextPath}/pasajero/calificar?viajeId=${v.id}" class="btn btn-ghost btn-sm">Calificar</a>
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
