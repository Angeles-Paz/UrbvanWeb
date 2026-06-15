<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Empleados</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#39207c;
        --role-dark:#2C1862;
        --role-light:#F2EEFF;
        --role-subtle:rgba(57,32,124,.1);
    }
    </style>
    <style>.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}.modal-overlay.visible{display:flex}.modal{background:var(--surface);border-radius:16px;padding:28px;max-width:440px;width:90%}</style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard">Panel</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/empleados" class="activo">Empleados</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/crear-ruta">+ Nueva ruta</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px">
        <div><div class="page-title">Empleados de la empresa</div><div class="page-sub">Usuarios con acceso al módulo B2B</div></div>
        <button onclick="document.getElementById('mAgregar').classList.add('visible')" class="btn btn-primary">+ Agregar empleado</button>
    </div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <div class="card">
        <c:choose>
            <c:when test="${empty empleados}"><div class="empty">Sin empleados registrados.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>Nombre</th><th>Email</th><th>Rol</th><th>Acciones</th></tr>
                    <c:forEach var="emp" items="${empleados}">
                        <tr>
                            <td style="font-weight:500">${emp.nombre}</td>
                            <td style="color:var(--texto2)">${emp.email}</td>
                            <td><span class="badge badge-morado">${emp.rol}</span></td>
                            <td>
                                <c:if test="${emp.rol == 'empleado'}">
                                    <form method="post" action="${pageContext.request.contextPath}/b2b/empresa/empleados" style="display:inline">
                                        <input type="hidden" name="accion" value="baja">
                                        <input type="hidden" name="usuarioId" value="${emp.id}">
                                        <button type="submit" class="btn btn-danger btn-sm">Dar de baja</button>
                                    </form>
                                </c:if>
                            </td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
<div class="modal-overlay" id="mAgregar" onclick="if(event.target===this)this.classList.remove('visible')">
    <div class="modal">
        <div style="font-size:18px;font-weight:700;margin-bottom:16px">Agregar empleado</div>
        <p style="color:var(--texto2);font-size:13px;margin-bottom:16px">Selecciona un usuario ya registrado en Urbvan para añadirlo como empleado.</p>
        <form method="post" action="${pageContext.request.contextPath}/b2b/empresa/empleados">
            <input type="hidden" name="accion" value="agregar">
            <div class="form-group">
                <label class="form-label">Usuario registrado</label>
                <select name="usuarioId" required>
                    <option value="">- Selecciona -</option>
                    <c:forEach var="u" items="${pasajerosSinEmpresa}">
                        <option value="${u.id}">${u.nombre} - ${u.email}</option>
                    </c:forEach>
                </select>
            </div>
            <div style="display:flex;gap:10px;margin-top:8px">
                <button type="button" onclick="document.getElementById('mAgregar').classList.remove('visible')" class="btn btn-ghost">Cancelar</button>
                <button type="submit" class="btn btn-primary">Agregar</button>
            </div>
        </form>
    </div>
</div>
</body>
</html>
