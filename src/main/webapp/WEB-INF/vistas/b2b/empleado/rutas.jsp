<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Mis rutas corporativas</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/urbvan.css">
    <style>
    :root{
        --role:#8080ff;
        --role-dark:#5A5AE8;
        --role-light:#F0F0FF;
        --role-subtle:rgba(128,128,255,.1);
    }
    </style>
    <style>
        .ruta-card{background:var(--surface2);border-radius:12px;padding:18px;margin-bottom:12px;border-left:4px solid var(--borde)}
        .ruta-card.pendiente{border-left-color:var(--role)}
        .ruta-card.activa{border-left-color:#10b981}
        .ruta-card.completada{border-left-color:#8b5cf6}
        .ruta-card.cancelada{border-left-color:#ef4444;opacity:.7}
        .horario-item{display:flex;gap:10px;align-items:flex-start;padding:6px 0;font-size:13px;border-bottom:1px solid var(--borde)}
        .horario-item:last-child{border-bottom:none}
        .hora{color:var(--texto2);min-width:60px}
        .modal-cal{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}
        .modal-cal.visible{display:flex}
        .modal-cal-inner{background:var(--surface);border-radius:16px;padding:28px;max-width:480px;width:90%;max-height:90vh;overflow-y:auto}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/pasajero/solicitar">Viajes B2C</a>
        <a href="${pageContext.request.contextPath}/b2b/empleado/rutas" class="activo">Mis rutas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Mis rutas corporativas</div>
    <div class="page-sub">Viajes asignados por tu empresa</div>
    <c:if test="${param.calificado == 'ok'}"><div class="alerta-ok">Calificacion enviada correctamente.</div></c:if>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>

    <c:if test="${not empty notificaciones}">
        <div class="card" style="margin-bottom:20px">
            <div class="card-title">Notificaciones</div>
            <c:forEach var="n" items="${notificaciones}">
                <div style="padding:10px 0;border-bottom:1px solid var(--borde);font-size:14px">${n.mensaje}</div>
            </c:forEach>
            <form method="post" action="${pageContext.request.contextPath}/notificaciones" style="margin-top:12px">
                <input type="hidden" name="id" value="all">
                <button type="submit" class="btn btn-ghost btn-sm">Marcar todas leidas</button>
            </form>
        </div>
    </c:if>

    <c:choose>
        <c:when test="${empty rutas}">
            <div class="card" style="text-align:center;padding:48px">
                <div style="font-size:40px;margin-bottom:12px">&#x1FA91;</div>
                <div style="font-size:16px;font-weight:600;margin-bottom:8px">Sin rutas asignadas</div>
                <div style="color:var(--texto2);font-size:14px">Tu empresa aun no te ha asignado rutas corporativas.</div>
            </div>
        </c:when>
        <c:otherwise>
            <c:forEach var="r" items="${rutas}">
                <div class="ruta-card ${r.estadoNombre == 'PENDIENTE' ? 'pendiente' : r.estadoNombre == 'ACTIVA' ? 'activa' : r.estadoNombre == 'COMPLETADA' ? 'completada' : 'cancelada'}">
                    <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:8px;margin-bottom:12px">
                        <div>
                            <span style="font-weight:700;font-size:16px">Ruta #${r.id}</span>
                            <span class="badge ${r.estadoClase}" style="margin-left:10px">${r.estadoTexto}</span>
                        </div>
                        <a href="${pageContext.request.contextPath}/b2b/ruta/detalle?rutaId=${r.id}" class="btn btn-ghost btn-sm">Ver ruta completa</a>
                        <c:if test="${not empty r.paradas}">
                            <button onclick="verHorario(${r.id})" class="btn btn-ghost btn-sm">Ver horario</button>
                        </c:if>
                    </div>
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;font-size:13px;color:var(--texto2)">
                        <div>Vehiculo: ${r.vehiculoModelo} - ${r.vehiculoPlaca}</div>
                        <div>Operador: ${r.operadorNombre}</div>
                        <div>Inicio: ${r.fechaInicio}</div>
                        <div>Empresa: ${r.empresaNombre}</div>
                    </div>
                    <c:if test="${r.estadoNombre == 'COMPLETADA'}">
                        <div style="margin-top:14px;padding-top:14px;border-top:1px solid var(--borde)">
                            <form method="post" action="${pageContext.request.contextPath}/b2b/empleado/calificar-operador">
                                <input type="hidden" name="rutaId" value="${r.id}">
                                <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">
                                    <label style="color:var(--texto2);font-size:13px;white-space:nowrap">Calificar operador (0-100):</label>
                                    <input type="number" name="puntuacion" min="0" max="100" value="70"
                                           style="width:80px;text-align:center">
                                    <input type="text" name="comentario" placeholder="Comentario opcional" style="flex:1;min-width:120px">
                                    <button type="submit" class="btn btn-primary btn-sm">Enviar</button>
                                </div>
                            </form>
                        </div>
                    </c:if>
                </div>
            </c:forEach>
        </c:otherwise>
    </c:choose>
</div>

<div class="modal-cal" id="mHorario" onclick="if(event.target===this)this.classList.remove('visible')">
    <div class="modal-cal-inner">
        <div style="font-size:18px;font-weight:700;margin-bottom:16px">Horario de paradas</div>
        <div id="horarioContenido"></div>
        <button onclick="document.getElementById('mHorario').classList.remove('visible')"
                class="btn btn-ghost" style="margin-top:16px;width:100%;justify-content:center">Cerrar</button>
    </div>
</div>

<script>
// Datos de paradas por ruta - sin template literals
var RUTAS_PARADAS = {};
<c:forEach var="r" items="${rutas}">
    <a href="${pageContext.request.contextPath}/b2b/ruta/detalle?rutaId=${r.id}" class="btn btn-ghost btn-sm">Ver ruta completa</a>
                        <c:if test="${not empty r.paradas}">
RUTAS_PARADAS[${r.id}] = [
        <c:forEach var="p" items="${r.paradas}" varStatus="s">
    { nombre: '${p.nombreLugar}', tipo: '${p.tipo}', hora: '${p.horaEstimada}', estancia: ${p.tiempoEstancia} }<c:if test="${!s.last}">,</c:if>
        </c:forEach>
];
    </c:if>
</c:forEach>

function verHorario(rutaId) {
    var lista = RUTAS_PARADAS[rutaId];
    var html = '';
    if (!lista || !lista.length) {
        html = '<p style="color:var(--texto2)">Horario no disponible.</p>';
    } else {
        lista.forEach(function(p) {
            var color = p.tipo === 'origen' ? '#10b981' : p.tipo === 'destino' ? '#ef4444' : '#06b6d4';
            html += '<div class="horario-item">';
            html += '<span class="hora">' + (p.hora || '-') + '</span>';
            html += '<span style="color:' + color + ';font-size:16px">&#9679;</span>';
            html += '<div>';
            html += '<div style="font-weight:500">' + p.nombre + '</div>';
            if (p.estancia > 0) {
                html += '<div style="font-size:12px;color:var(--texto2)">Estancia: ' + p.estancia + ' min</div>';
            }
            html += '</div></div>';
        });
    }
    document.getElementById('horarioContenido').innerHTML = html;
    document.getElementById('mHorario').classList.add('visible');
}
</script>
</body>
</html>
