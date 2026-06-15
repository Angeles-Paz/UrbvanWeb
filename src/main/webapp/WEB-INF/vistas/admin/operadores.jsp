<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Operadores</title>
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
    <style>.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}.modal-overlay.visible{display:flex}.modal{background:var(--surface);border-radius:16px;padding:32px;max-width:440px;width:90%}</style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios">Pasajeros</a>
        <a href="${pageContext.request.contextPath}/admin/operadores" class="activo">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos">Vehículos</a>
        <a href="${pageContext.request.contextPath}/admin/empresas">Empresas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px">
        <div><div class="page-title">Gestión de operadores</div></div>
        <button onclick="document.getElementById('modalNuevo').classList.add('visible')" class="btn btn-primary">+ Nuevo operador</button>
    </div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <div class="card">
        <c:choose>
            <c:when test="${empty operadores}"><div class="empty">Sin operadores registrados.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>Nombre</th><th>Email</th><th>Puntuación</th><th>Estado</th><th>Acciones</th></tr>
                    <c:forEach var="op" items="${operadores}">
                        <tr>
                            <td style="font-weight:500">${op.nombre}</td>
                            <td style="color:var(--texto2)">${op.email}</td>
                            <td><span class="score">${op.calificacionPromedio}</span></td>
                            <td><c:choose><c:when test="${op.activo}"><span class="badge badge-verde">Activo</span></c:when><c:otherwise><span class="badge badge-rojo">Inactivo</span></c:otherwise></c:choose></td>
                            <td>
                                <form method="post" action="${pageContext.request.contextPath}/admin/operadores" style="display:inline">
                                    <input type="hidden" name="accion" value="toggleActivo">
                                    <input type="hidden" name="id" value="${op.id}">
                                    <button type="submit" class="btn btn-ghost btn-sm">${op.activo ? 'Inhabilitar' : 'Habilitar'}</button>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
<div class="modal-overlay" id="modalNuevo">
    <div class="modal">
        <div style="font-size:18px;font-weight:700;margin-bottom:20px">Nuevo operador</div>
        <form method="post" action="${pageContext.request.contextPath}/admin/operadores">
            <input type="hidden" name="accion" value="crear">
            <div class="form-group"><label class="form-label">Nombre</label><input type="text" name="nombre" required></div>
            <div class="form-group"><label class="form-label">Email</label><input type="email" name="email" required></div>
            <div class="form-group"><label class="form-label">Contraseña inicial</label><input type="password" name="contrasena" required></div>
            <div style="display:flex;gap:10px;margin-top:8px">
                <button type="button" onclick="document.getElementById('modalNuevo').classList.remove('visible')" class="btn btn-ghost">Cancelar</button>
                <button type="submit" class="btn btn-primary">Crear operador</button>
            </div>
        </form>
    </div>
</div>
</body>
</html>
