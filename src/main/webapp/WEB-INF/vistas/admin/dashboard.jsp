<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#FF637E;
        --role-dark:#C94D60;
        --role-light:#FFF0F3;
        --role-subtle:rgba(255,99,126,.1);
    }
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard" class="activo">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios">Pasajeros</a>
        <a href="${pageContext.request.contextPath}/admin/operadores">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos">Vehículos</a>
        <a href="${pageContext.request.contextPath}/admin/empresas">Empresas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Panel de administración</div>
    <div class="page-sub">Resumen general del sistema Urbvan</div>
    <div class="grid-stats">
        <div class="stat-card"><div class="stat-num" style="color:var(--role)">${totalPasajeros}</div><div class="stat-label">Pasajeros</div></div>
        <div class="stat-card"><div class="stat-num" style="color:var(--naranja)">${totalOperadores}</div><div class="stat-label">Operadores</div></div>
        <div class="stat-card"><div class="stat-num" style="color:var(--morado)">${totalVehiculos}</div><div class="stat-label">Vehículos</div></div>
        <div class="stat-card"><div class="stat-num" style="color:#3B82F6">${totalEmpresas}</div><div class="stat-label">Empresas B2B</div></div>
        <div class="stat-card"><div class="stat-num" style="color:var(--naranja)">${viajesActivos}</div><div class="stat-label">Viajes activos</div></div>
        <div class="stat-card"><div class="stat-num" style="color:var(--role)">${viajesCompletados}</div><div class="stat-label">Completados</div></div>
    </div>
    <div class="card">
        <div class="card-title">Últimos viajes</div>
        <c:choose>
            <c:when test="${empty ultimosViajes}"><div class="empty">Sin viajes registrados.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>#</th><th>Pasajero</th><th>Operador</th><th>Origen → Destino</th><th>Costo</th><th>Estado</th></tr>
                    <c:forEach var="v" items="${ultimosViajes}" varStatus="s">
                        <c:if test="${s.index < 20}">
                        <tr>
                            <td style="color:var(--texto2)">#${v.id}</td>
                            <td>${v.pasajeroNombre}</td>
                            <td>${empty v.operadorNombre ? '-' : v.operadorNombre}</td>
                            <td style="font-size:13px;max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${v.origenNombre} → ${v.destinoNombre}</td>
                            <td>$${v.costo}</td>
                            <td>
                                <c:choose>
                                    <c:when test="${v.estado == 'COMPLETADO'}"><span class="badge badge-verde">Completado</span></c:when>
                                    <c:when test="${v.estado == 'CANCELADO'}"><span class="badge badge-rojo">Cancelado</span></c:when>
                                    <c:when test="${v.estado == 'SOLICITADO'}"><span class="badge badge-gris">Buscando op.</span></c:when>
                                    <c:otherwise><span class="badge badge-naranja">En curso</span></c:otherwise>
                                </c:choose>
                            </td>
                        </tr>
                        </c:if>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
</body>
</html>
