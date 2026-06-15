<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Asignar asientos</title>
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
        .seat-grid{display:flex;flex-wrap:wrap;gap:6px;max-width:340px}
        .seat{width:54px;height:54px;border-radius:10px;border:2px solid var(--borde);display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;font-size:12px;font-weight:600;transition:all .15s;position:relative}
        .seat:hover:not(.ocupado){border-color:var(--role);background:var(--role-subtle)}
        .seat.disponible{background:var(--surface2);color:var(--texto)}
        .seat.ocupado{background:#d1fae5;border-color:#10b981;color:#065f46;cursor:default}
        .seat.seleccionado{background:var(--role);border-color:var(--role);color:#fff}
        .seat-gap{width:12px;height:54px}
        .layout{display:grid;grid-template-columns:1fr 280px;gap:24px;align-items:start}
        @media(max-width:800px){.layout{grid-template-columns:1fr}}
        .leyenda{display:flex;gap:14px;font-size:12px;margin-bottom:14px;flex-wrap:wrap}
        .leyenda-dot{width:16px;height:16px;border-radius:4px;border:2px solid var(--borde);display:inline-block;vertical-align:middle;margin-right:4px}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard">Panel</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div class="page-title">Asignacion de asientos - Ruta #${ruta.id}</div>
    <div class="page-sub">${ruta.vehiculoModelo} - ${ruta.vehiculoPlaca} - ${ruta.vehiculoCapacidad} plazas</div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>

    <div class="layout">
        <div class="card">
            <div class="card-title">Mapa de asientos</div>
            <div class="leyenda">
                <span><span class="leyenda-dot" style="background:var(--surface2)"></span>Disponible</span>
                <span><span class="leyenda-dot" style="background:#d1fae5;border-color:#10b981"></span>Ocupado</span>
                <span><span class="leyenda-dot" style="background:#06b6d4;border-color:#06b6d4"></span>Seleccionado</span>
            </div>
            <div style="display:flex;justify-content:center">
                <div style="display:flex;flex-direction:column;gap:4px" id="seatContainer"></div>
            </div>
            <p id="msgAsiento" style="text-align:center;color:var(--texto2);font-size:13px;margin-top:12px">
                Selecciona un asiento y luego un empleado.
            </p>
        </div>

        <div>
            <div class="card" style="margin-bottom:16px">
                <div class="card-title">Asignar empleado</div>
                <p style="color:var(--texto2);font-size:13px;margin-bottom:12px">
                    Asiento seleccionado: <strong id="lblAsientoSel">-</strong>
                </p>
                <div class="form-group">
                    <label class="form-label">Empleado</label>
                    <select id="selEmpleado" onchange="actualizarBoton()">
                        <option value="">- Selecciona -</option>
                        <c:forEach var="emp" items="${empleados}">
                            <option value="${emp.id}">${emp.nombre}</option>
                        </c:forEach>
                    </select>
                </div>
                <button id="btnAsignar" onclick="asignar()" class="btn btn-primary" disabled
                        style="width:100%;justify-content:center">Asignar asiento</button>
            </div>

            <div class="card">
                <div class="card-title">Asignados (${ruta.asientosOcupados})</div>
                <c:choose>
                    <c:when test="${empty ruta.asientos}">
                        <div class="empty" style="padding:16px">Sin asignaciones aun.</div>
                    </c:when>
                    <c:otherwise>
                        <c:forEach var="a" items="${ruta.asientos}">
                            <div style="display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid var(--borde);font-size:14px">
                                <div>
                                    <span style="font-weight:600">Asiento ${a.numeroAsiento}</span>
                                    <span style="color:var(--texto2);margin-left:8px">${a.empleadoNombre}</span>
                                </div>
                                <form method="post" action="${pageContext.request.contextPath}/b2b/empresa/asignar-asientos">
                                    <input type="hidden" name="accion" value="remover">
                                    <input type="hidden" name="rutaId" value="${ruta.id}">
                                    <input type="hidden" name="empleadoId" value="${a.empleadoId}">
                                    <button type="submit" class="btn btn-ghost btn-sm">x</button>
                                </form>
                            </div>
                        </c:forEach>
                    </c:otherwise>
                </c:choose>
            </div>
            <a href="${pageContext.request.contextPath}/b2b/empresa/dashboard"
               class="btn btn-ghost" style="width:100%;justify-content:center;margin-top:12px">
               Volver al panel
            </a>
        </div>
    </div>
</div>

<form id="fAsignar" method="post" action="${pageContext.request.contextPath}/b2b/empresa/asignar-asientos">
    <input type="hidden" name="accion" value="asignar">
    <input type="hidden" name="rutaId" value="${ruta.id}">
    <input type="hidden" name="empleadoId"    id="hEmpleadoId">
    <input type="hidden" name="numeroAsiento" id="hNumeroAsiento">
</form>

<script>
// Asientos ocupados pasados desde servidor - sin template literals
var ASIENTOS_OCUPADOS = {};
<c:forEach var="a" items="${ruta.asientos}">
ASIENTOS_OCUPADOS[${a.numeroAsiento}] = '${a.empleadoNombre}';
</c:forEach>
var CAPACIDAD = ${ruta.vehiculoCapacidad};
var asientoSel = null;

function renderSeatMap() {
    var container = document.getElementById('seatContainer');
    container.innerHTML = '';

    // 4 asientos por fila: col1=ventana-izq, col2=pasillo-izq, col3=pasillo-der, col4=ventana-der
    var totalFilas = Math.ceil(CAPACIDAD / 4);
    for (var fila = 0; fila < totalFilas; fila++) {
        var rowDiv = document.createElement('div');
        rowDiv.style.cssText = 'display:flex;gap:6px;align-items:center';

        for (var col = 1; col <= 4; col++) {
            // Pasillo entre col 2 y 3
            if (col === 3) {
                var gap = document.createElement('div');
                gap.className = 'seat-gap';
                rowDiv.appendChild(gap);
            }

            var num = fila * 4 + col;
            if (num > CAPACIDAD) {
                var empty = document.createElement('div');
                empty.style.cssText = 'width:54px;height:54px';
                rowDiv.appendChild(empty);
                continue;
            }

            var filaLetra = String.fromCharCode(65 + fila); // A, B, C...
            var div = document.createElement('div');
            var ocupado = ASIENTOS_OCUPADOS[num];
            div.className = 'seat ' + (ocupado ? 'ocupado' : 'disponible');
            div.title = ocupado ? ('Asiento ' + num + ': ' + ocupado) : ('Asiento ' + num);
            div.textContent = filaLetra + col;
            div.dataset.num = num;

            if (!ocupado) {
                div.onclick = (function(n, el) {
                    return function() { seleccionar(n, el); };
                })(num, div);
            }
            rowDiv.appendChild(div);
        }
        container.appendChild(rowDiv);
    }
}

function seleccionar(num, el) {
    // Deseleccionar anterior
    var prev = document.querySelector('.seat.seleccionado');
    if (prev) prev.className = prev.className.replace('seleccionado', 'disponible');

    el.className = el.className.replace('disponible', 'seleccionado');
    asientoSel = num;
    document.getElementById('lblAsientoSel').textContent = 'Asiento ' + num;
    document.getElementById('hNumeroAsiento').value = num;
    actualizarBoton();
}

function actualizarBoton() {
    var ok = asientoSel && document.getElementById('selEmpleado').value;
    document.getElementById('btnAsignar').disabled = !ok;
}

function asignar() {
    var emp = document.getElementById('selEmpleado').value;
    if (!asientoSel || !emp) return;
    document.getElementById('hEmpleadoId').value = emp;
    document.getElementById('fAsignar').submit();
}

renderSeatMap();
</script>
</body>
</html>
