<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Perfil</title>
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
        <a href="${pageContext.request.contextPath}/pasajero/historial">Historial</a>
        <a href="${pageContext.request.contextPath}/pasajero/perfil" class="activo">Perfil</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Mi perfil</div>
    <div class="page-sub">Actualiza tus datos de contacto.</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${param.actualizado == 'ok'}"><div class="alerta-ok">Perfil actualizado correctamente.</div></c:if>
    <div class="card" style="max-width:760px">
        <form method="post" action="${pageContext.request.contextPath}/pasajero/perfil">
            <div class="form-grid">
                <div class="form-group">
                    <label class="form-label">Nombre</label>
                    <input type="text" name="nombre" value="${perfil[1]}" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Apellido</label>
                    <input type="text" name="apellido" value="${perfil[2]}">
                </div>
                <div class="form-group">
                    <label class="form-label">Correo</label>
                    <input type="email" value="${perfil[3]}" readonly>
                </div>
                <div class="form-group">
                    <label class="form-label">Teléfono</label>
                    <input type="text" name="telefono" value="${perfil[4]}">
                </div>
            </div>
            <button type="submit" class="btn btn-primary" style="margin-top:18px">Guardar cambios</button>
        </form>
    </div>
</div>
</body>
</html>
