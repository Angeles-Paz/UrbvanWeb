<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
    <title>Urbvan - Vehículos</title>
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
    <style>
        .modal-overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:200;align-items:center;justify-content:center}
        .modal-overlay.visible{display:flex}
        .modal{background:var(--surface);border-radius:16px;padding:32px;max-width:480px;width:90%}
        .modal-title{font-size:18px;font-weight:700;margin-bottom:20px}
        .modal-btns{display:flex;gap:10px;margin-top:20px}
    </style>
</head>
<body>
<nav class="nav">
    <div class="nav-logo"><img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="nav-logo-img"></div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios">Pasajeros</a>
        <a href="${pageContext.request.contextPath}/admin/operadores">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos" class="activo">Vehículos</a>
        <a href="${pageContext.request.contextPath}/admin/empresas">Empresas B2B</a>
        <a href="${pageContext.request.contextPath}/logout" class="logout">Salir</a>
    </div>
</nav>
<div class="main">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:24px">
        <div class="page-title">Gestión de vehículos</div>
        <button onclick="abrirModal('modalNuevo')" class="btn btn-primary">+ Nuevo vehículo</button>
    </div>
    <c:if test="${not empty error}"><div class="alerta-error">${error}</div></c:if>
    <c:if test="${param.ok == 'asignado'}"><div class="alerta-ok">Operador asignado correctamente.</div></c:if>

    <div class="card">
        <c:choose>
            <c:when test="${empty vehiculos}">
                <div class="empty">Sin vehículos registrados.</div>
            </c:when>
            <c:otherwise>
                <table>
                    <tr>
                        <th>Modelo</th><th>Placa</th><th>Capacidad</th>
                        <th>Categoría</th><th>Operador asignado</th><th>Estado</th><th>Acciones</th>
                    </tr>
                    <c:forEach var="vh" items="${vehiculos}">
                        <tr>
                            <td style="font-weight:500">${vh.modelo}</td>
                            <td>${vh.placa}</td>
                            <td>${vh.capacidad} pax</td>
                            <td>
                                <span class="badge ${vh.categoria == 'b2b' ? 'badge-morado' : 'badge-verde'}">
                                    ${vh.categoria == 'b2b' ? 'B2B - Bus' : 'B2C - Auto'}
                                </span>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${empty vh.operadorNombre}">
                                        <span style="color:var(--texto3)">Sin asignar</span>
                                    </c:when>
                                    <c:otherwise>
                                        <span style="font-weight:500">${vh.operadorNombre}</span>
                                    </c:otherwise>
                                </c:choose>
                            </td>
                            <td>
                                <c:choose>
                                    <c:when test="${vh.activo}"><span class="badge badge-verde">Activo</span></c:when>
                                    <c:otherwise><span class="badge badge-rojo">Inactivo</span></c:otherwise>
                                </c:choose>
                            </td>
                            <td style="display:flex;gap:6px;flex-wrap:wrap">
                                <%-- Botón asignar operador --%>
                                <button onclick="abrirAsignar(${vh.id}, '${vh.modelo} ${vh.placa}')"
                                        class="btn btn-ghost btn-sm">
                                    👤 Asignar op.
                                </button>
                                <%-- Habilitar / Inhabilitar --%>
                                <form method="post" action="${pageContext.request.contextPath}/admin/vehiculos">
                                    <input type="hidden" name="accion" value="toggleActivo">
                                    <input type="hidden" name="id" value="${vh.id}">
                                    <button type="submit" class="btn btn-ghost btn-sm">
                                        ${vh.activo ? 'Inhabilitar' : 'Habilitar'}
                                    </button>
                                </form>
                            </td>
                        </tr>
                    </c:forEach>
                </table>
            </c:otherwise>
        </c:choose>
    </div>
</div>

<!-- ── Modal: Nuevo vehículo ─────────────────────────────────────────────── -->
<div class="modal-overlay" id="modalNuevo">
    <div class="modal">
        <div class="modal-title">Registrar nuevo vehículo</div>
        <form method="post" action="${pageContext.request.contextPath}/admin/vehiculos">
            <input type="hidden" name="accion" value="crear">
            <div class="form-group">
                <label class="form-label">Categoría de servicio</label>
                <select name="categoria" id="selCat" onchange="actualizarModelos(this.value)">
                    <option value="b2c">B2C - Transporte individual</option>
                    <option value="b2b">B2B - Bus corporativo</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Modelo</label>
                <select name="modelo" id="selModelo">
                    <option value="Sedan">Sedan</option>
                    <option value="SUV">SUV</option>
                    <option value="Minivan">Minivan</option>
                </select>
            </div>
            <div class="form-group">
                <label class="form-label">Capacidad (pasajeros)</label>
                <input type="number" name="capacidad" id="inputCapacidad" min="1" max="70" required placeholder="Ej: 4">
            </div>
            <div class="form-group">
                <label class="form-label">Placa</label>
                <input type="text" name="placa" required placeholder="Ej: ABC-123-CDMX">
            </div>
            <div class="form-group">
                <label class="form-label">Color</label>
                <input type="text" name="color" placeholder="Ej: Blanco">
            </div>
            <div class="modal-btns">
                <button type="button" onclick="cerrarModal('modalNuevo')" class="btn btn-ghost">Cancelar</button>
                <button type="submit" class="btn btn-primary">Registrar vehículo</button>
            </div>
        </form>
    </div>
</div>

<!-- ── Modal: Asignar operador ───────────────────────────────────────────── -->
<div class="modal-overlay" id="modalAsignar">
    <div class="modal">
        <div class="modal-title">Asignar operador a <span id="lblVehiculo"></span></div>
        <form method="post" action="${pageContext.request.contextPath}/admin/vehiculos">
            <input type="hidden" name="accion" value="asignar">
            <input type="hidden" name="vehiculoId" id="inputVehiculoId">
            <div class="form-group">
                <label class="form-label">Selecciona un operador sin vehículo</label>
                <select name="operadorId" id="selOperador">
                    <c:choose>
                        <c:when test="${empty operadoresDisponibles}">
                            <option value="" disabled>Sin operadores disponibles</option>
                        </c:when>
                        <c:otherwise>
                            <c:forEach var="op" items="${operadoresDisponibles}">
                                <option value="${op.id}">${op.nombre}</option>
                            </c:forEach>
                        </c:otherwise>
                    </c:choose>
                </select>
                <p style="color:var(--texto2);font-size:12px;margin-top:6px">
                    Solo aparecen operadores que aún no tienen vehículo asignado.
                </p>
            </div>
            <div class="modal-btns">
                <button type="button" onclick="cerrarModal('modalAsignar')" class="btn btn-ghost">Cancelar</button>
                <button type="submit" class="btn btn-primary"
                        ${empty operadoresDisponibles ? 'disabled' : ''}>
                    Asignar
                </button>
            </div>
        </form>
    </div>
</div>

<script>
// Modelos por categoría con capacidades por defecto
const DATOS = {
    b2c: [{m:'Sedan',c:4},{m:'SUV',c:6},{m:'Minivan',c:8}],
    b2b: [
        {m:'Irizar_i8',c:47},{m:'Busstar_DD',c:66},{m:'Marcopolo_G7',c:44},
        {m:'Volvo_9800',c:44},{m:'Irizar_i6',c:50},{m:'Torino',c:43}
    ]
};

function actualizarModelos(cat) {
    const lista = DATOS[cat] || DATOS.b2c;
    const sel   = document.getElementById('selModelo');
    const cap   = document.getElementById('inputCapacidad');
    sel.innerHTML = lista.map(d =>
        `<option value="${d.m}">${d.m.replace('_',' ')}</option>`
    ).join('');
    cap.value = lista[0].c; // precargar capacidad del primer modelo
    sel.onchange = () => {
        const found = lista.find(d => d.m === sel.value);
        if (found) cap.value = found.c;
    };
}

// Actualizar capacidad al cambiar modelo (inicialización)
document.getElementById('selModelo').onchange = function() {
    const cat   = document.getElementById('selCat').value;
    const lista = DATOS[cat] || DATOS.b2c;
    const found = lista.find(d => d.m === this.value);
    if (found) document.getElementById('inputCapacidad').value = found.c;
};

function abrirModal(id) {
    document.getElementById(id).classList.add('visible');
}
function cerrarModal(id) {
    document.getElementById(id).classList.remove('visible');
}
function abrirAsignar(vehiculoId, label) {
    document.getElementById('inputVehiculoId').value = vehiculoId;
    document.getElementById('lblVehiculo').textContent = label;
    abrirModal('modalAsignar');
}
// Cerrar modales al hacer clic fuera
document.querySelectorAll('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', function(e) {
        if (e.target === this) this.classList.remove('visible');
    });
});
</script>
</body>
</html>
