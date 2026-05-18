<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan Admin — Vehículos</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --coral: #993C1D; --coral-dark: #712B13; --coral-light: #FAECE7;
            --verde: #1D9E75; --verde-light: #E1F5EE;
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
        .page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
        .page-titulo { font-size: 22px; font-weight: 600; color: var(--texto); }
        .page-sub    { font-size: 13px; color: var(--texto-2); margin-top: 3px; }
        .btn-nuevo   { padding: 10px 20px; background: var(--coral-dark); color: white; border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; font-weight: 500; cursor: pointer; }

        /* Grid de tarjetas */
        .veh-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px,1fr)); gap: 14px; }
        .veh-card { background: var(--blanco); border: 1px solid var(--borde); border-radius: 14px; overflow: hidden; }
        .veh-card-header {
            padding: 16px 18px; display: flex; align-items: center;
            gap: 12px; border-bottom: 1px solid var(--borde);
        }
        .veh-icono {
            width: 44px; height: 44px; border-radius: 12px; flex-shrink: 0;
            background: var(--coral-light); display: flex; align-items: center;
            justify-content: center; font-size: 22px;
        }
        .veh-placa { font-size: 15px; font-weight: 600; color: var(--texto); font-family: monospace; }
        .veh-marca { font-size: 12px; color: var(--texto-3); margin-top: 2px; }
        .veh-card-body { padding: 14px 18px; }
        .veh-fila { display: flex; justify-content: space-between; font-size: 12px; color: var(--texto-2); margin-bottom: 8px; }
        .veh-fila:last-child { margin-bottom: 0; }
        .veh-fila strong { color: var(--texto); font-weight: 500; }
        .veh-card-footer { padding: 12px 18px; border-top: 1px solid var(--borde); display: flex; gap: 8px; }

        .badge-activo { display: inline-block; font-size: 10px; font-weight: 500; padding: 3px 8px; border-radius: 10px; }
        .badge-si   { background: var(--verde-light); color: #0F6E56; }
        .badge-no   { background: var(--error-bg);    color: var(--error); }

        .btn-card { padding: 6px 12px; border-radius: 8px; font-family: 'DM Sans', sans-serif; font-size: 11px; font-weight: 500; cursor: pointer; border: 1px solid var(--borde); background: var(--blanco); color: var(--texto-2); }
        .btn-card.desactivar { color: var(--error); border-color: rgba(216,90,48,.3); }
        .btn-card.activar    { color: var(--verde); border-color: rgba(29,158,117,.3); }

        .sin-datos { padding: 48px; text-align: center; font-size: 13px; color: var(--texto-3); background: var(--blanco); border: 1px solid var(--borde); border-radius: 14px; }

        /* Modal */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 100; align-items: center; justify-content: center; }
        .modal-overlay.visible { display: flex; }
        .modal { background: var(--blanco); border-radius: 20px; padding: 28px 32px; width: 100%; max-width: 440px; }
        .modal-titulo { font-size: 18px; font-weight: 600; color: var(--texto); margin-bottom: 4px; }
        .modal-sub    { font-size: 13px; color: var(--texto-2); margin-bottom: 24px; }
        .campo { margin-bottom: 14px; }
        .campo label { display: block; font-size: 12px; font-weight: 500; color: var(--texto-2); margin-bottom: 6px; }
        .campo input, .campo select { width: 100%; padding: 10px 14px; border: 1.5px solid var(--borde); border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px; color: var(--texto); outline: none; }
        .campo input:focus { border-color: var(--coral); }
        .fila-campos { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .modal-acciones { display: flex; gap: 10px; margin-top: 20px; }
        .btn-modal-cancelar { flex: 1; padding: 12px; border-radius: 10px; border: 1.5px solid var(--borde); background: transparent; font-family: 'DM Sans', sans-serif; font-size: 14px; color: var(--texto-2); cursor: pointer; }
        .btn-modal-guardar  { flex: 1; padding: 12px; border-radius: 10px; border: none; background: var(--coral-dark); color: white; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500; cursor: pointer; }
    </style>
</head>
<body>

<%
    List<Object[]> vehiculos = (List<Object[]>) request.getAttribute("vehiculos");
%>

<nav>
    <div class="nav-marca">
        <span class="nav-logo">Urbvan</span>
        <span class="nav-badge">Administrador</span>
    </div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard"  class="nav-link">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios"   class="nav-link">Usuarios</a>
        <a href="${pageContext.request.contextPath}/admin/operadores" class="nav-link">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos"  class="nav-link activo">Vehículos</a>
        <a href="${pageContext.request.contextPath}/logout"           class="btn-logout">Salir</a>
    </div>
</nav>

<div class="contenedor">
    <div class="page-header">
        <div>
            <div class="page-titulo">Gestión de vehículos</div>
            <div class="page-sub">Unidades registradas en el sistema</div>
        </div>
        <button class="btn-nuevo" onclick="abrirModal()">+ Nuevo vehículo</button>
    </div>

    <% if (vehiculos == null || vehiculos.isEmpty()) { %>
    <div class="sin-datos">No hay vehículos registrados.</div>
    <% } else { %>
    <div class="veh-grid">
        <% for (Object[] v : vehiculos) {
            int    idV     = (int) v[0];
            String placa   = (String) v[1];
            String marca   = (String) v[2];
            String modelo  = (String) v[3];
            int    anio    = (int) v[4];
            String color   = v[5] != null ? (String)v[5] : "—";
            int    cap     = (int) v[6];
            int    activo  = (int) v[7];
            String opAsig  = v[8] != null ? (String)v[8] : "Sin operador";
        %>
        <div class="veh-card">
            <div class="veh-card-header">
                <div class="veh-icono">🚐</div>
                <div>
                    <div class="veh-placa"><%= placa %></div>
                    <div class="veh-marca"><%= marca %> <%= modelo %></div>
                </div>
            </div>
            <div class="veh-card-body">
                <div class="veh-fila"><span>Año</span><strong><%= anio %></strong></div>
                <div class="veh-fila"><span>Color</span><strong><%= color %></strong></div>
                <div class="veh-fila"><span>Capacidad</span><strong><%= cap %> pasajeros</strong></div>
                <div class="veh-fila"><span>Operador</span><strong style="font-size:11px"><%= opAsig %></strong></div>
                <div class="veh-fila"><span>Estado</span>
                    <span class="badge-activo <%= activo == 1 ? "badge-si" : "badge-no" %>">
                        <%= activo == 1 ? "Activo" : "Inactivo" %>
                    </span>
                </div>
            </div>
            <div class="veh-card-footer">
                <form method="POST" action="${pageContext.request.contextPath}/admin/vehiculos" style="display:inline">
                    <input type="hidden" name="accion" value="toggle_activo">
                    <input type="hidden" name="id"     value="<%= idV %>">
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

<!-- Modal nuevo vehículo -->
<div class="modal-overlay" id="modal-crear">
    <div class="modal">
        <div class="modal-titulo">Nuevo vehículo</div>
        <div class="modal-sub">Registrar una unidad en el sistema</div>
        <form method="POST" action="${pageContext.request.contextPath}/admin/vehiculos">
            <input type="hidden" name="accion" value="crear">
            <div class="fila-campos">
                <div class="campo"><label>Marca *</label><input type="text" name="marca" placeholder="Toyota" required/></div>
                <div class="campo"><label>Modelo *</label><input type="text" name="modelo" placeholder="Hiace" required/></div>
            </div>
            <div class="fila-campos">
                <div class="campo"><label>Placa *</label><input type="text" name="placa" placeholder="ABC-123" required/></div>
                <div class="campo"><label>Año</label><input type="number" name="anio" placeholder="2024" min="2000" max="2030"/></div>
            </div>
            <div class="fila-campos">
                <div class="campo"><label>Color</label><input type="text" name="color" placeholder="Blanco"/></div>
                <div class="campo"><label>Capacidad</label><input type="number" name="capacidad" placeholder="8" min="1" max="20"/></div>
            </div>
            <div class="modal-acciones">
                <button type="button" class="btn-modal-cancelar" onclick="cerrarModal()">Cancelar</button>
                <button type="submit" class="btn-modal-guardar">Registrar vehículo</button>
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
