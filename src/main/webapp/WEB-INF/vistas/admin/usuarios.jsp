<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.List, java.sql.Timestamp, java.text.SimpleDateFormat" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan Admin — Usuarios</title>
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
        .nav-link:hover  { background: rgba(255,255,255,.1); color: white; }
        .nav-link.activo { background: rgba(255,255,255,.15); color: white; font-weight: 500; }
        .btn-logout { font-size: 12px; color: rgba(255,255,255,.6); text-decoration: none; padding: 5px 12px; border: 1px solid rgba(255,255,255,.2); border-radius: 20px; margin-left: 8px; }

        .contenedor { max-width: 1100px; margin: 0 auto; padding: 32px 24px; }
        .page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
        .page-titulo { font-size: 22px; font-weight: 600; color: var(--texto); letter-spacing: -0.3px; }
        .page-sub    { font-size: 13px; color: var(--texto-2); margin-top: 3px; }

        /* Barra de búsqueda y botón */
        .barra-acciones { display: flex; gap: 10px; margin-bottom: 20px; }
        .input-busqueda {
            flex: 1; padding: 10px 14px; border: 1.5px solid var(--borde);
            border-radius: 10px; font-family: 'DM Sans', sans-serif;
            font-size: 13px; outline: none; color: var(--texto);
            transition: border-color .15s;
        }
        .input-busqueda:focus { border-color: var(--coral); }
        .btn-buscar {
            padding: 10px 20px; background: var(--fondo); border: 1.5px solid var(--borde);
            border-radius: 10px; font-family: 'DM Sans', sans-serif;
            font-size: 13px; cursor: pointer; color: var(--texto-2);
        }
        .btn-nuevo {
            padding: 10px 20px; background: var(--coral-dark); color: white;
            border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif;
            font-size: 13px; font-weight: 500; cursor: pointer; white-space: nowrap;
        }
        .btn-nuevo:hover { opacity: .9; }

        /* Tabla */
        .tabla-wrap { background: var(--blanco); border: 1px solid var(--borde); border-radius: 16px; overflow: hidden; }
        .tabla { width: 100%; border-collapse: collapse; font-size: 13px; }
        .tabla th { text-align: left; font-weight: 500; color: var(--texto-3); font-size: 11px; letter-spacing: .04em; text-transform: uppercase; padding: 12px 16px; border-bottom: 1px solid var(--borde); background: var(--fondo); }
        .tabla td { padding: 12px 16px; border-bottom: 1px solid var(--borde); color: var(--texto-2); vertical-align: middle; }
        .tabla tr:last-child td { border-bottom: none; }
        .tabla tr:hover td { background: var(--fondo); }

        .avatar { width: 32px; height: 32px; border-radius: 50%; background: var(--coral-light); color: var(--coral); display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; flex-shrink: 0; }
        .usuario-info { display: flex; align-items: center; gap: 10px; }
        .usuario-nombre { font-size: 13px; font-weight: 500; color: var(--texto); }
        .usuario-correo { font-size: 11px; color: var(--texto-3); }

        .badge-activo   { display: inline-block; font-size: 10px; font-weight: 500; padding: 3px 8px; border-radius: 10px; }
        .badge-si       { background: var(--verde-light); color: #0F6E56; }
        .badge-no       { background: var(--error-bg);    color: var(--error); }

        .acciones { display: flex; gap: 6px; }
        .btn-accion {
            padding: 5px 12px; border-radius: 8px; font-family: 'DM Sans', sans-serif;
            font-size: 11px; font-weight: 500; cursor: pointer; border: 1px solid var(--borde);
            background: var(--blanco); color: var(--texto-2); transition: all .15s;
        }
        .btn-accion:hover { background: var(--fondo); }
        .btn-accion.desactivar { color: var(--error); border-color: rgba(216,90,48,.3); }
        .btn-accion.activar    { color: var(--verde); border-color: rgba(29,158,117,.3); }

        .sin-datos { padding: 48px; text-align: center; font-size: 13px; color: var(--texto-3); }

        /* Modal crear usuario */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 100; align-items: center; justify-content: center; }
        .modal-overlay.visible { display: flex; }
        .modal { background: var(--blanco); border-radius: 20px; padding: 28px 32px; width: 100%; max-width: 440px; }
        .modal-titulo { font-size: 18px; font-weight: 600; color: var(--texto); margin-bottom: 6px; }
        .modal-sub    { font-size: 13px; color: var(--texto-2); margin-bottom: 24px; }
        .campo { margin-bottom: 16px; }
        .campo label { display: block; font-size: 12px; font-weight: 500; color: var(--texto-2); margin-bottom: 6px; }
        .campo input, .campo select {
            width: 100%; padding: 10px 14px; border: 1.5px solid var(--borde);
            border-radius: 10px; font-family: 'DM Sans', sans-serif;
            font-size: 13px; color: var(--texto); outline: none;
        }
        .campo input:focus, .campo select:focus { border-color: var(--coral); }
        .fila-campos { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .modal-acciones { display: flex; gap: 10px; margin-top: 24px; }
        .btn-modal-cancelar {
            flex: 1; padding: 12px; border-radius: 10px; border: 1.5px solid var(--borde);
            background: transparent; font-family: 'DM Sans', sans-serif;
            font-size: 14px; color: var(--texto-2); cursor: pointer;
        }
        .btn-modal-guardar {
            flex: 1; padding: 12px; border-radius: 10px; border: none;
            background: var(--coral-dark); color: white;
            font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 500; cursor: pointer;
        }
        .btn-modal-guardar:hover { opacity: .9; }
    </style>
</head>
<body>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    List<Object[]> usuarios = (List<Object[]>) request.getAttribute("usuarios");
    String busqueda = (String) request.getAttribute("busqueda");
%>

<nav>
    <div class="nav-marca">
        <span class="nav-logo">Urbvan</span>
        <span class="nav-badge">Administrador</span>
    </div>
    <div class="nav-links">
        <a href="${pageContext.request.contextPath}/admin/dashboard"  class="nav-link">Dashboard</a>
        <a href="${pageContext.request.contextPath}/admin/usuarios"   class="nav-link activo">Usuarios</a>
        <a href="${pageContext.request.contextPath}/admin/operadores" class="nav-link">Operadores</a>
        <a href="${pageContext.request.contextPath}/admin/vehiculos"  class="nav-link">Vehículos</a>
        <a href="${pageContext.request.contextPath}/logout"           class="btn-logout">Salir</a>
    </div>
</nav>

<div class="contenedor">
    <div class="page-header">
        <div>
            <div class="page-titulo">Gestión de usuarios</div>
            <div class="page-sub">Pasajeros registrados en el sistema</div>
        </div>
    </div>

    <!-- Búsqueda y botón nuevo -->
    <form method="GET" action="${pageContext.request.contextPath}/admin/usuarios">
        <div class="barra-acciones">
            <input type="text" name="q" class="input-busqueda"
                   placeholder="Buscar por nombre, apellido o correo..."
                   value="<%= busqueda != null ? busqueda : "" %>"/>
            <button type="submit" class="btn-buscar">Buscar</button>
            <button type="button" class="btn-nuevo" onclick="abrirModal()">+ Nuevo usuario</button>
        </div>
    </form>

    <!-- Tabla de usuarios -->
    <div class="tabla-wrap">
        <% if (usuarios == null || usuarios.isEmpty()) { %>
        <div class="sin-datos">
            <%= busqueda != null ? "No se encontraron usuarios con ese criterio." : "No hay usuarios registrados." %>
        </div>
        <% } else { %>
        <table class="tabla">
            <tr>
                <th>Usuario</th><th>Teléfono</th><th>Viajes</th>
                <th>Estado</th><th>Registro</th><th>Acciones</th>
            </tr>
            <% for (Object[] u : usuarios) {
                int    idU      = (int) u[0];
                String nombre  = (String) u[1];
                String apellido= (String) u[2];
                String correo  = (String) u[3];
                String tel     = u[4] != null ? (String)u[4] : "—";
                int    activo  = (int) u[5];
                Timestamp reg  = (Timestamp) u[6];
                int    viajes  = (int) u[7];
                String iniciales = "";
                if (nombre != null && !nombre.isEmpty()) iniciales += nombre.charAt(0);
                if (apellido != null && !apellido.isEmpty()) iniciales += apellido.charAt(0);
            %>
            <tr>
                <td>
                    <div class="usuario-info">
                        <div class="avatar"><%= iniciales.toUpperCase() %></div>
                        <div>
                            <div class="usuario-nombre"><%= nombre %> <%= apellido %></div>
                            <div class="usuario-correo"><%= correo %></div>
                        </div>
                    </div>
                </td>
                <td><%= tel %></td>
                <td><%= viajes %></td>
                <td>
                    <span class="badge-activo <%= activo == 1 ? "badge-si" : "badge-no" %>">
                        <%= activo == 1 ? "Activo" : "Inactivo" %>
                    </span>
                </td>
                <td><%= reg != null ? sdf.format(reg) : "—" %></td>
                <td>
                    <div class="acciones">
                        <form method="POST" action="${pageContext.request.contextPath}/admin/usuarios"
                              style="display:inline">
                            <input type="hidden" name="accion" value="toggle_activo">
                            <input type="hidden" name="id"     value="<%= idU %>">
                            <input type="hidden" name="activo" value="<%= activo %>">
                            <button type="submit" class="btn-accion <%= activo == 1 ? "desactivar" : "activar" %>">
                                <%= activo == 1 ? "Desactivar" : "Activar" %>
                            </button>
                        </form>
                    </div>
                </td>
            </tr>
            <% } %>
        </table>
        <% } %>
    </div>
</div>

<!-- Modal crear usuario -->
<div class="modal-overlay" id="modal-crear">
    <div class="modal">
        <div class="modal-titulo">Nuevo usuario</div>
        <div class="modal-sub">Crear cuenta de pasajero</div>
        <form method="POST" action="${pageContext.request.contextPath}/admin/usuarios">
            <input type="hidden" name="accion" value="crear">
            <div class="fila-campos">
                <div class="campo">
                    <label>Nombre *</label>
                    <input type="text" name="nombre" placeholder="Nombre" required/>
                </div>
                <div class="campo">
                    <label>Apellido</label>
                    <input type="text" name="apellido" placeholder="Apellido"/>
                </div>
            </div>
            <div class="campo">
                <label>Correo electrónico *</label>
                <input type="email" name="correo" placeholder="correo@ejemplo.com" required/>
            </div>
            <div class="campo">
                <label>Teléfono</label>
                <input type="tel" name="telefono" placeholder="55 1234 5678"/>
            </div>
            <div class="campo">
                <label>Contraseña inicial *</label>
                <input type="password" name="contrasena" placeholder="Mínimo 6 caracteres" required/>
            </div>
            <div class="modal-acciones">
                <button type="button" class="btn-modal-cancelar" onclick="cerrarModal()">Cancelar</button>
                <button type="submit" class="btn-modal-guardar">Crear usuario</button>
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
