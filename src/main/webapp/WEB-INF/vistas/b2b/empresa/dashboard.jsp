<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Panel Corporativo</title>
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
    <style>
        .ruta-card{background:var(--surface2);border-radius:12px;padding:18px;margin-bottom:12px;border-left:4px solid var(--borde);transition:border-color .2s}
        .ruta-card:hover{border-left-color:#06b6d4}
        .ruta-info{display:flex;gap:16px;font-size:13px;color:var(--texto2);flex-wrap:wrap;margin-top:8px}
        .modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}
        .modal-overlay.visible{display:flex}
        .modal{background:var(--surface);border-radius:16px;padding:28px;max-width:400px;width:90%;text-align:center}
        .notif-item{padding:10px 0;border-bottom:1px solid var(--borde);font-size:14px;display:flex;gap:10px}
        .notif-item:last-child{border-bottom:none}
        .tab-header{display:flex;gap:4px;margin-bottom:16px;border-bottom:2px solid var(--borde)}
        .tab-btn{padding:10px 18px;background:none;border:none;border-bottom:2px solid transparent;font-family:'DM Sans',sans-serif;font-size:14px;font-weight:500;color:var(--texto2);cursor:pointer;margin-bottom:-2px}
        .tab-btn.activo{color:var(--role);border-bottom-color:var(--role)}
        .tab-content{display:none}.tab-content.activo{display:block}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard" class="activo">Panel</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/empleados">Empleados</a>
        <a href="${pageContext.request.contextPath}/b2b/empresa/crear-ruta">+ Nueva ruta</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">

    <c:if test="${mostrarAvisoPrimerLogin}">
        <div class="alerta-ok" style="margin-bottom:20px">
            Bienvenido. Esta es tu primera sesion. Considera actualizar tu contrasena.
        </div>
    </c:if>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${param.calificado == 'ok'}"><div class="alerta-ok">Calificacion enviada correctamente.</div></c:if>

    <%-- Notificaciones --%>
    <c:if test="${not empty notificaciones}">
        <div class="card" style="margin-bottom:20px">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
                <span class="card-title" style="margin:0">Notificaciones (${numNotif})</span>
                <form method="post" action="${pageContext.request.contextPath}/notificaciones">
                    <input type="hidden" name="id" value="all">
                    <button type="submit" class="btn btn-ghost btn-sm">Marcar leidas</button>
                </form>
            </div>
            <c:forEach var="n" items="${notificaciones}">
                <div class="notif-item">
                    <span style="font-size:18px"><c:choose><c:when test="${n.tipo == 'ruta_cancelada'}">&#10005;</c:when><c:when test="${n.tipo == 'empresa_inhabilitada'}">&#9888;</c:when><c:otherwise><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg></c:otherwise></c:choose></span>
                    <span>${n.mensaje}</span>
                </div>
            </c:forEach>
        </div>
    </c:if>

    <%-- Stats --%>
    <div class="grid-stats" style="margin-bottom:24px">
        <div class="stat-card"><div class="stat-num" style="color:#06b6d4">${empresa.score}</div><div class="stat-label">Score corporativo</div></div>
        <div class="stat-card"><div class="stat-num" style="color:#10b981">${empresa.empleadosActivos}</div><div class="stat-label">Empleados</div></div>
        <div class="stat-card"><div class="stat-num" style="color:#8b5cf6">${empresa.rutasCompletadas}</div><div class="stat-label">Rutas completadas</div></div>
        <div class="stat-card"><div class="stat-num" style="color:#f97316">${empresa.rutasEnCurso}</div><div class="stat-label">En curso</div></div>
    </div>

    <%-- Tabs: Rutas de la empresa / Mis asientos --%>
    <div class="card">
        <div class="tab-header">
            <button class="tab-btn activo" onclick="switchTab('tabRutas', this)">
                Rutas corporativas
            </button>
            <c:if test="${not empty rutasPropias}">
                <button class="tab-btn" onclick="switchTab('tabMias', this)">
                    Mis asientos asignados (${rutasPropias.size()})
                </button>
            </c:if>
        </div>

        <%-- Tab 1: Rutas de la empresa --%>
        <div id="tabRutas" class="tab-content activo">
            <div style="display:flex;justify-content:flex-end;margin-bottom:12px">
                <a href="${pageContext.request.contextPath}/b2b/empresa/crear-ruta" class="btn btn-primary btn-sm">+ Nueva ruta</a>
            </div>
            <c:choose>
                <c:when test="${empty rutas}">
                    <div class="empty" style="padding:32px">
                        <div style="font-size:36px;margin-bottom:8px">&#x1F68C;</div>
                        No hay rutas registradas.
                    </div>
                </c:when>
                <c:otherwise>
                    <c:forEach var="r" items="${rutas}">
                        <div class="ruta-card">
                            <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px">
                                <div>
                                    <span style="font-weight:700">Ruta #${r.id}</span>
                                    <span class="badge ${r.estadoClase}" style="margin-left:8px">${r.estadoTexto}</span>
                                    <c:if test="${not r.asignacionCompleta && r.estadoNombre == 'PENDIENTE'}">
                                        <span class="badge badge-naranja" style="margin-left:4px">Sin asientos</span>
                                    </c:if>
                                </div>
                                <div style="font-size:13px;color:var(--texto2)">${r.vehiculoModelo} - ${r.vehiculoPlaca}</div>
                            </div>
                            <div class="ruta-info">
                                <span>&#128197; ${r.fechaInicio}</span>
                                <span>&#128100; ${r.operadorNombre}</span>
                                <span>&#x1FA91; ${r.asientosOcupados}/${r.vehiculoCapacidad}</span>
                                <span>&#x1F4B0; $${r.costoTotal}</span>
                            </div>
                            <div style="display:flex;gap:8px;margin-top:12px;flex-wrap:wrap">
                                <a href="${pageContext.request.contextPath}/b2b/ruta/detalle?rutaId=${r.id}" class="btn btn-ghost btn-sm">Ver detalles</a>
                                <c:if test="${r.estadoNombre == 'PENDIENTE'}">
                                    <a href="${pageContext.request.contextPath}/b2b/empresa/asignar-asientos?rutaId=${r.id}" class="btn btn-primary btn-sm">Asignar asientos</a>
                                </c:if>
                                <c:if test="${r.estadoNombre == 'COMPLETADA'}">
                                    <a href="${pageContext.request.contextPath}/b2b/empresa/calificar-operador?rutaId=${r.id}" class="btn btn-naranja btn-sm">Calificar operador</a>
                                </c:if>
                                <c:if test="${r.estadoNombre == 'PENDIENTE' || r.estadoNombre == 'ACTIVA'}">
                                    <button onclick="confirmarCancelar(${r.id})" class="btn btn-danger btn-sm">Cancelar</button>
                                </c:if>
                            </div>
                        </div>
                    </c:forEach>
                </c:otherwise>
            </c:choose>
        </div>

        <%-- Tab 2: Asientos propios del admin (si tiene alguno asignado) --%>
        <c:if test="${not empty rutasPropias}">
        <div id="tabMias" class="tab-content">
            <c:forEach var="r" items="${rutasPropias}">
                <div class="ruta-card" style="border-left-color:#8b5cf6">
                    <div style="display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px">
                        <span style="font-weight:700">Ruta #${r.id}</span>
                        <span class="badge ${r.estadoClase}">${r.estadoTexto}</span>
                    </div>
                    <div class="ruta-info">
                        <span>&#128197; ${r.fechaInicio}</span>
                        <span>&#128100; Operador: ${r.operadorNombre}</span>
                        <span>${r.vehiculoModelo}</span>
                    </div>
                    <c:if test="${r.estadoNombre == 'COMPLETADA'}">
                        <div style="margin-top:10px">
                            <a href="${pageContext.request.contextPath}/b2b/empresa/calificar-operador?rutaId=${r.id}"
                               class="btn btn-naranja btn-sm">Calificar operador</a>
                        </div>
                    </c:if>
                </div>
            </c:forEach>
        </div>
        </c:if>
    </div>
</div>

<div class="modal-overlay" id="mCancelar" onclick="if(event.target===this)this.classList.remove('visible')">
    <div class="modal">
        <div style="font-size:22px;margin-bottom:8px">&#9888;&#65039;</div>
        <h3 style="font-size:18px;margin-bottom:10px">Cancelar esta ruta?</h3>
        <p style="color:var(--texto2);font-size:14px;margin-bottom:20px">Si faltan menos de 24h se aplicara penalizacion de 10 puntos al score.</p>
        <div style="display:flex;gap:12px;justify-content:center">
            <button onclick="document.getElementById('mCancelar').classList.remove('visible')" class="btn btn-ghost">No, mantener</button>
            <form id="fCancelar" method="post" action="${pageContext.request.contextPath}/b2b/empresa/cancelar-ruta">
                <input type="hidden" name="rutaId" id="inputRutaIdCancelar">
                <button type="submit" class="btn btn-danger">Si, cancelar</button>
            </form>
        </div>
    </div>
</div>

<script>
function confirmarCancelar(rutaId) {
    document.getElementById('inputRutaIdCancelar').value = rutaId;
    document.getElementById('mCancelar').classList.add('visible');
}
function switchTab(tabId, btn) {
    document.querySelectorAll('.tab-content').forEach(function(t){ t.classList.remove('activo'); });
    document.querySelectorAll('.tab-btn').forEach(function(b){ b.classList.remove('activo'); });
    document.getElementById(tabId).classList.add('activo');
    btn.classList.add('activo');
}
</script>
</body>
</html>
