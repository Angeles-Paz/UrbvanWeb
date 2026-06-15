<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Pasajeros</title>
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
        <a href="${pageContext.request.contextPath}/admin/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios" class="activo">Pasajeros</a>
        <a href="${pageContext.request.contextPath}/admin/operadores">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos">Vehículos</a>
        <a href="${pageContext.request.contextPath}/admin/empresas">Empresas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Gestión de pasajeros</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <div class="card">
        <c:choose>
            <c:when test="${empty usuarios}"><div class="empty">Sin pasajeros registrados.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>#</th><th>Nombre</th><th>Email</th><th>Puntuación</th><th>Estado</th><th>Acciones</th></tr>
                    <c:forEach var="u" items="${usuarios}">
                        <tr>
                            <td style="color:var(--texto2)">${u.id}</td>
                            <td style="font-weight:500">${u.nombre}</td>
                            <td style="color:var(--texto2)">${u.email}</td>
                            <td><span class="score">${u.calificacionPromedio}</span></td>
                            <td><c:choose><c:when test="${u.activo}"><span class="badge badge-verde">Activo</span></c:when><c:otherwise><span class="badge badge-rojo">Inactivo</span></c:otherwise></c:choose></td>
                            <td>
                                <form method="post" action="${pageContext.request.contextPath}/admin/usuarios" style="display:inline">
                                    <input type="hidden" name="accion" value="toggleActivo">
                                    <input type="hidden" name="id" value="${u.id}">
                                    <button type="submit" class="btn btn-ghost btn-sm">${u.activo ? 'Inhabilitar' : 'Habilitar'}</button>
                                </form>
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
