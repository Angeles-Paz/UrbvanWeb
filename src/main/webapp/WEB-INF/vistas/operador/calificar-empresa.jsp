<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Calificar empresa</title>
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
    <style>.score-slider{-webkit-appearance:none;height:8px;border-radius:4px;background:var(--borde);width:100%;outline:none}.score-slider::-webkit-slider-thumb{-webkit-appearance:none;width:24px;height:24px;border-radius:50%;background:#f97316;cursor:pointer}.score-display{font-size:56px;font-weight:700;color:#f97316;text-align:center}</style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/operador/rutas-b2b">Rutas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main" style="max-width:500px">
    <div class="page-title">Calificar empresa</div>
    <div class="page-sub">Ruta #${ruta.id} · ${ruta.empresaNombre}</div>
    <c:if test="${not empty ruta}">
        <div class="card">
            <div style="text-align:center;margin-bottom:24px">
                <div style="font-size:40px;margin-bottom:8px"><svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" style="color:var(--role)"><rect x="4" y="5" width="16" height="15" rx="1"/><path d="M9 20V13h6v7M8 9h.01M8 13h.01M16 9h.01M16 13h.01M12 9h.01M12 13h.01"/></svg></div>
                <div style="font-size:20px;font-weight:600">${ruta.empresaNombre}</div>
                <div style="color:var(--texto2);font-size:13px">Score actual: ${ruta.empresaScore}</div>
            </div>
            <form method="post" action="${pageContext.request.contextPath}/operador/calificar-empresa">
                <input type="hidden" name="rutaId" value="${ruta.id}">
                <div class="form-group">
                    <label class="form-label" style="text-align:center;display:block;margin-bottom:8px">Puntuación al comportamiento corporativo</label>
                    <div class="score-display" id="scoreDisplay">70</div>
                    <input type="range" class="score-slider" name="puntuacion" min="0" max="100" value="70"
                           oninput="document.getElementById('scoreDisplay').textContent=this.value">
                    <div style="display:flex;justify-content:space-between;color:var(--texto2);font-size:12px;margin-top:4px">
                        <span>0 - Problemática</span><span>100 - Excelente</span>
                    </div>
                </div>
                <div class="form-group" style="margin-top:16px">
                    <label class="form-label">Comentario (opcional)</label>
                    <textarea name="comentario" rows="3" placeholder="¿Cómo fue tu experiencia con esta empresa?"></textarea>
                </div>
                <button type="submit" class="btn btn-naranja" style="width:100%;justify-content:center">Enviar calificación</button>
            </form>
        </div>
    </c:if>
</div>
</body>
</html>
