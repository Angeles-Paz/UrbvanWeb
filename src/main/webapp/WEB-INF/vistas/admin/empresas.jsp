<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Empresas B2B</title>
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
    <style>.modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}.modal-overlay.visible{display:flex}.modal{background:var(--surface);border-radius:16px;padding:32px;max-width:500px;width:90%}</style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios">Pasajeros</a>
        <a href="${pageContext.request.contextPath}/admin/operadores">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos">Vehículos</a>
        <a href="${pageContext.request.contextPath}/admin/empresas" class="activo">Empresas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px">
        <div><div class="page-title">Empresas B2B</div><div class="page-sub">Clientes corporativos de la plataforma</div></div>
        <button onclick="document.getElementById('mNueva').classList.add('visible')" class="btn btn-primary">+ Nueva empresa</button>
    </div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <div class="card">
        <c:choose>
            <c:when test="${empty empresas}"><div class="empty">Sin empresas registradas.</div></c:when>
            <c:otherwise>
                <table>
                    <tr><th>Empresa</th><th>Score</th><th>Empleados</th><th>Rutas OK</th><th>En curso</th><th>Estado</th><th>Acciones</th></tr>
                    <c:forEach var="e" items="${empresas}">
                        <tr>
                            <td style="font-weight:600">${e.nombre}</td>
                            <td><span class="badge ${e.claseScore}">★ ${e.score}</span></td>
                            <td>${e.empleadosActivos}</td>
                            <td>${e.rutasCompletadas}</td>
                            <td>${e.rutasEnCurso}</td>
                            <td><c:choose><c:when test="${e.activa}"><span class="badge badge-verde">Activa</span></c:when><c:otherwise><span class="badge badge-rojo">Inhabilitada</span></c:otherwise></c:choose></td>
                            <td>
                                <form method="post" action="${pageContext.request.contextPath}/admin/empresas" style="display:inline">
                                    <input type="hidden" name="id" value="${e.id}">
                                    <c:choose>
                                        <c:when test="${e.activa}"><input type="hidden" name="accion" value="inhabilitar"><button type="submit" class="btn btn-danger btn-sm">Inhabilitar</button></c:when>
                                        <c:otherwise><input type="hidden" name="accion" value="habilitar"><button type="submit" class="btn btn-ghost btn-sm">Habilitar</button></c:otherwise>
                                    </c:choose>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>
<div class="modal-overlay" id="mNueva" onclick="if(event.target===this)this.classList.remove('visible')">
    <div class="modal">
        <div style="font-size:18px;font-weight:700;margin-bottom:16px">Registrar nueva empresa</div>
        <form method="post" action="${pageContext.request.contextPath}/admin/empresas">
            <input type="hidden" name="accion" value="crear">
            <p style="color:var(--texto2);font-size:13px;margin-bottom:16px">Se crea la empresa y la cuenta de Admin Empresa en una sola operación.</p>
            <div class="form-group"><label class="form-label">Nombre de la empresa</label><input type="text" name="nombreEmpresa" required placeholder="Corporativo XYZ S.A."></div>
            <div style="border-top:1px solid var(--borde);padding-top:16px;margin-bottom:16px">
                <div style="font-weight:600;font-size:14px;margin-bottom:12px">Datos del Admin Empresa</div>
                <div class="form-group"><label class="form-label">Nombre completo</label><input type="text" name="adminNombre" required></div>
                <div class="form-group"><label class="form-label">Correo electrónico</label><input type="email" name="adminEmail" required></div>
                <div class="form-group"><label class="form-label">Contraseña temporal</label><input type="text" name="passwordTemporal" value="Urbvan2026" required></div>
            </div>
            <div style="display:flex;gap:10px">
                <button type="button" onclick="document.getElementById('mNueva').classList.remove('visible')" class="btn btn-ghost">Cancelar</button>
                <button type="submit" class="btn btn-primary">Crear empresa</button>
            </div>
        </form>
    </div>
</div>
</body>
</html>
