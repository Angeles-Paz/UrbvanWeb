<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.sql.Timestamp, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan Admin — Operadores</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --coral: #993C1D; --coral-dark: #712B13; --coral-light: #FAECE7;
            --verde: #1D9E75; --verde-light: #E1F5EE;
            --purple: #534AB7; --purple-light: #EEEDFE;
            --amber: #BA7517; --amber-light: #FAEEDA;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
        }
        body { font-family: 'DM Sans', sans-serif; background: var(--fondo); min-height: 100vh; }
        nav { background: var(--coral-dark); height: 56px; display: flex; align-items: center; justify-content: space-between; padding: 0 32px; position: sticky; top: 0; z-index: 10; }
        .nav-marca { display: flex; align-items: center; gap: 10px; }
        .nav-logo  { font-size: 18px; font-weight: 600; color: white; }
        .nav-badge { font-size: 11px; background: rgba(255,255,255,.15); color: white; padding: 3px 10px; border-radius: 20px; }
        .nav-links { display: flex; align-items: center; gap: 4px; }
        .nav-link  { font-size: 13px; color: rgba(255,255,255,.7); text-decoration: none; padding: 6px 14px; border-radius: 20px; }
        .nav-link:hover { background: rgba(255,255,255,.1); color: white; }
        .nav-link.activo { background: rgba(255,255,255,.15); color: white; font-weight: 500; }
        .btn-logout { font-size: 12px; color: rgba(255,255,255,.6); text-decoration: none; padding: 5px 12px; border: 1px solid rgba(255,255,255,.2); border-radius: 20px; margin-left: 8px; }

        .contenedor { max-width: 1100px; margin: 0 auto; padding: 32px 24px; }
        .page-header { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 24px; }
        .page-titulo { font-size: 22px; font-weight: 600; color: var(--texto); letter-spacing: -0.3px; }
        .page-sub    { font-size: 13px; color: var(--texto-2); margin-top: 3px; }

        .barra-acciones { display: flex; gap: 10px; margin-bottom: 20px; }
        .input-busqueda { flex: 1; padding: 10px 14px; border: 1.5px solid var(--borde); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; outline: none; color: var(--texto); }
        .input-busqueda:focus { border-color: var(--coral); }
        .btn-buscar { padding: 10px 20px; background: var(--fondo); border: 1.5px solid var(--borde); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; cursor: pointer; color: var(--texto-2); }
        .btn-nuevo  { padding: 10px 20px; background: var(--coral-dark); color: white; border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; cursor: pointer; white-space: nowrap; }

        /* Grid de tarjetas */
        .op-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px,1fr)); gap: 14px; }
        .op-card { background: var(--blanco); border: 1px solid var(--borde); border-radius: 14px; overflow: hidden; }
        .op-card-header { padding: 16px 18px; display: flex; align-items: center; gap: 12px; border-bottom: 1px solid var(--borde); }
        .op-avatar { width: 44px; height: 44px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; font-weight: 600; flex-shrink: 0; }
        .av-activo   { background: var(--purple-light); color: var(--purple); }
        .av-inactivo { background: #F1EFE8; color: var(--texto-3); }
        .op-nombre  { font-size: 14px; font-weight: 600; color: var(--texto); }
        .op-correo  { font-size: 11px; color: var(--texto-3); margin-top: 2px; }
        .op-card-body { padding: 14px 18px; }
        .op-fila { display: flex; justify-content: space-between; font-size: 12px; color: var(--texto-2); margin-bottom: 8px; }
        .op-fila:last-child { margin-bottom: 0; }
        .op-fila strong { color: var(--texto); font-weight: 500; }
        .op-card-footer { padding: 12px 18px; border-top: 1px solid var(--borde); display: flex; gap: 8px; flex-wrap: wrap; }
        .badge-disp { font-size: 10px; font-weight: 500; padding: 3px 8px; border-radius: 10px; }
        .bd-disponible { background: var(--verde-light);  color: #0F6E56; }
        .bd-ocupado    { background: var(--purple-light); color: var(--purple); }
        .bd-inactivo   { background: #F1EFE8; color: var(--texto-3); }
        .btn-card { padding: 6px 12px; border-radius: 8px; font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500; cursor: pointer; border: 1px solid var(--borde); background: var(--blanco); color: var(--texto-2); }
        .btn-card.desactivar { color: var(--error); border-color: rgba(216,90,48,.3); }
        .btn-card.activar    { color: var(--verde); border-color: rgba(29,158,117,.3); }
        .sin-datos { padding: 48px; text-align: center; font-size: 13px; color: var(--texto-3); background: var(--blanco); border: 1px solid var(--borde); border-radius: 14px; }

        /* Modal */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 100; align-items: center; justify-content: center; }
        .modal-overlay.visible { display: flex; }
        .modal { background: var(--blanco); border-radius: 20px; padding: 28px 32px; width: 100%; max-width: 460px; max-height: 90vh; overflow-y: auto; }
        .modal-titulo { font-size: 18px; font-weight: 600; color: var(--texto); margin-bottom: 4px; }
        .modal-sub    { font-size: 13px; color: var(--texto-2); margin-bottom: 24px; }
        .campo { margin-bottom: 14px; }
        .campo label { display: block; font-size: 12px; font-weight: 500; color: var(--texto-2); margin-bottom: 6px; }
        .campo input, .campo select { width: 100%; padding: 10px 14px; border: 1.5px solid var(--borde); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--texto); outline: none; }
        .campo input:focus, .campo select:focus { border-color: var(--coral); }
        .fila-campos { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .modal-acciones { display: flex; gap: 10px; margin-top: 20px; }
        .btn-modal-cancelar { flex: 1; padding: 12px; border-radius: 10px; border: 1.5px solid var(--borde); background: transparent; font-family: 'DM Sans', sans-serif; font-size: 14px; color: var(--texto-2); cursor: pointer; }
        .btn-modal-guardar  { flex: 1; padding: 12px; border-radius: 10px; border: none; background: var(--coral-dark); color: white; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500; cursor: pointer; }
    </style>
</head>
<body>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    List<Object[]> operadores = (List<Object[]>) request.getAttribute("operadores");
    List<Object[]> vehiculos  = (List<Object[]>) request.getAttribute("vehiculos");
    String busqueda = (String) request.getAttribute("busqueda");
%>

<nav>
    <div class="nav-marca">
        <span class="nav-logo">Urbvan</span>
        <span class="nav-badge">Administrador</span>
    </div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard"  class="nav-link">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios"   class="nav-link">Usuarios</a>
        <a href="${pageContext.request.contextPath}/admin/operadores" class="nav-link activo">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos"  class="nav-link">Vehículos</a>
        <a href="${pageContext.request.contextPath}/logout"           class="btn-logout">Salir</a>
    </div>
</nav>

<div class="contenedor">
    <div class="page-header">
        <div>
            <div class="page-titulo">Gestión de operadores</div>
            <div class="page-sub">Conductores registrados en el sistema</div>
        </div>
    </div>

    <form method="GET" action="${pageContext.request.contextPath}/admin/operadores">
        <div class="barra-acciones">
            <input type="text" name="q" class="input-busqueda"
                   placeholder="Buscar operador..."
                   value="<%= busqueda != null ? busqueda : "" %>"/>
            <button type="submit" class="btn-buscar">Buscar</button>
            <button type="button" class="btn-nuevo" onclick="abrirModal()">+ Nuevo operador</button>
        </div>
    </form>

    <% if (operadores == null || operadores.isEmpty()) { %>
    <div class="sin-datos">No hay operadores registrados.</div>
    <% } else { %>
    <div class="op-grid">
        <% for (Object[] op : operadores) {
            int    idOp      = (int) op[0];
            String nombre    = op[1] + " " + op[2];
            String correo    = (String) op[3];
            String tel       = op[4] != null ? (String)op[4] : "—";
            int    disponible= (int) op[5];
            int    activo    = (int) op[6];
            double cal       = (double) op[7];
            String vehiculo  = op[9] != null ? (String)op[9] : "Sin vehículo";
            int    totalVj   = (int) op[11];
            String iniciales = "";
            if (op[1] != null && !op[1].toString().isEmpty()) iniciales += op[1].toString().charAt(0);
            if (op[2] != null && !op[2].toString().isEmpty()) iniciales += op[2].toString().charAt(0);
            String dispLabel = activo == 0 ? "Inactivo" : disponible == 1 ? "Disponible" : "Ocupado";
            String dispClass = activo == 0 ? "bd-inactivo" : disponible == 1 ? "bd-disponible" : "bd-ocupado";
        %>
        <div class="op-card">
            <div class="op-card-header">
                <div class="op-avatar <%= activo == 1 ? "av-activo" : "av-inactivo" %>">
                    <%= iniciales.toUpperCase() %>
                </div>
                <div style="flex:1;min-width:0">
                    <div class="op-nombre"><%= nombre %></div>
                    <div class="op-correo"><%= correo %></div>
                </div>
                <span class="badge-disp <%= dispClass %>"><%= dispLabel %></span>
            </div>
            <div class="op-card-body">
                <div class="op-fila"><span>Teléfono</span><strong><%= tel %></strong></div>
                <div class="op-fila"><span>Vehículo</span><strong style="font-size:11px"><%= vehiculo %></strong></div>
                <div class="op-fila"><span>Viajes completados</span><strong><%= totalVj %></strong></div>
                <div class="op-fila"><span>Calificación</span><strong style="color:#BA7517">★ <%= String.format("%.1f", cal) %></strong></div>
            </div>
            <div class="op-card-footer">
                <form method="POST" action="${pageContext.request.contextPath}/admin/operadores" style="display:inline">
                    <input type="hidden" name="accion" value="toggle_activo">
                    <input type="hidden" name="id"     value="<%= idOp %>">
                    <input type="hidden" name="activo" value="<%= activo %>">
                    <button type="submit" class="btn-card <%= activo == 1 ? "desactivar" : "activar" %>">
                        <%= activo == 1 ? "Desactivar" : "Activar" %>
                    </button>
                </form>
            </div>
        </div>
        <% } %>
    </div>
    <% } %>
</div>

<!-- Modal crear operador -->
<div class="modal-overlay" id="modal-crear">
    <div class="modal">
        <div class="modal-titulo">Nuevo operador</div>
        <div class="modal-sub">Las credenciales serán asignadas por el administrador</div>
        <form method="POST" action="${pageContext.request.contextPath}/admin/operadores">
            <input type="hidden" name="accion" value="crear">
            <div class="fila-campos">
                <div class="campo"><label>Nombre *</label><input type="text" name="nombre" required/></div>
                <div class="campo"><label>Apellido</label><input type="text" name="apellido"/></div>
            </div>
            <div class="campo"><label>Correo *</label><input type="email" name="correo" required/></div>
            <div class="campo"><label>Teléfono</label><input type="tel" name="telefono" placeholder="55 1234 5678"/></div>
            <div class="campo"><label>Contraseña inicial *</label><input type="password" name="contrasena" required/></div>
            <div class="campo">
                <label>Vehículo asignado</label>
                <select name="id_vehiculo">
                    <option value="">— Sin asignar —</option>
                    <% if (vehiculos != null) { for (Object[] v : vehiculos) { %>
                    <option value="<%= v[0] %>"><%= v[1] %></option>
                    <% } } %>
                </select>
            </div>
            <div class="modal-acciones">
                <button type="button" class="btn-modal-cancelar" onclick="cerrarModal()">Cancelar</button>
                <button type="submit" class="btn-modal-guardar">Crear operador</button>
            </div>
        </form>
    </div>
</div>

<script>
function abrirModal()  { document.getElementById('modal-crear').classList.add('visible'); }
function cerrarModal() { document.getElementById('modal-crear').classList.remove('visible'); }
document.getElementById('modal-crear').addEventListener('click', function(e) {
    if (e.target === this) cerrarModal();
});
</script>
</body>
</html>
