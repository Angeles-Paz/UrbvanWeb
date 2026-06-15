<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Calificar operador</title>
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
    <style>.score-slider{-webkit-appearance:none;height:8px;border-radius:4px;background:var(--borde);width:100%;outline:none}.score-slider::-webkit-slider-thumb{-webkit-appearance:none;width:24px;height:24px;border-radius:50%;background:#10b981;cursor:pointer}.score-display{font-size:56px;font-weight:700;color:#10b981;text-align:center}</style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard">Panel</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main" style="max-width:500px">
    <div class="page-title">Calificar operador</div>
    <div class="page-sub">Ruta #${ruta.id} · ${ruta.fechaInicio}</div>
    <c:if test="${not empty ruta}">
        <div class="card">
            <div style="text-align:center;margin-bottom:24px">
                <div style="font-size:40px;margin-bottom:8px"><svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg></div>
                <div style="font-size:20px;font-weight:600">${ruta.operadorNombre}</div>
                <div style="color:var(--texto2);font-size:13px">${ruta.vehiculoModelo} · ${ruta.vehiculoPlaca}</div>
            </div>
            <form method="post" action="${pageContext.request.contextPath}/b2b/empresa/calificar-operador">
                <input type="hidden" name="rutaId" value="${ruta.id}">
                <div class="form-group">
                    <label class="form-label" style="text-align:center;display:block;margin-bottom:8px">Puntuación</label>
                    <div class="score-display" id="scoreDisplay">70</div>
                    <input type="range" class="score-slider" name="puntuacion" min="0" max="100" value="70"
                           oninput="document.getElementById('scoreDisplay').textContent=this.value">
                    <div style="display:flex;justify-content:space-between;color:var(--texto2);font-size:12px;margin-top:4px">
                        <span>0 - Problemático</span><span>100 - Excelente</span>
                    </div>
                </div>
                <div class="form-group" style="margin-top:16px">
                    <label class="form-label">Comentario (opcional)</label>
                    <textarea name="comentario" rows="3" placeholder="¿Cómo fue el servicio del operador?"></textarea>
                </div>
                <button type="submit" class="btn btn-primary" style="width:100%;justify-content:center">Enviar calificación</button>
            </form>
        </div>
    </c:if>
</div>
</body>
</html>
