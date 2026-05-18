<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="mx.urbvan.modelo.Viaje" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Pago</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=DM+Mono:wght@400;500&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --verde: #1D9E75; --verde-dark: #0F6E56; --verde-light: #E1F5EE;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
        }
        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--fondo); min-height: 100vh;
            display: flex; flex-direction: column;
        }
        nav {
            background: var(--blanco); border-bottom: 1px solid var(--borde);
            display: flex; align-items: center; justify-content: space-between;
            padding: 0 32px; height: 56px;
        }
        .nav-logo { font-size: 18px; font-weight: 600; color: var(--verde-dark); }
        .nav-paso  { font-size: 13px; color: var(--texto-3); }

        /* Pasos en la barra */
        .pasos-barra {
            display: flex; align-items: center; gap: 0;
            background: var(--blanco); border-bottom: 1px solid var(--borde);
            padding: 0 32px; height: 44px;
        }
        .paso-item {
            display: flex; align-items: center; gap: 8px;
            font-size: 12px; color: var(--texto-3); padding: 0 16px 0 0;
        }
        .paso-item.activo { color: var(--verde); font-weight: 500; }
        .paso-item.hecho  { color: var(--texto-3); }
        .paso-num {
            width: 20px; height: 20px; border-radius: 50%;
            display: flex; align-items: center; justify-content: center;
            font-size: 10px; font-weight: 600; border: 1.5px solid var(--borde);
            color: var(--texto-3);
        }
        .paso-item.activo .paso-num { background: var(--verde); color: white; border-color: var(--verde); }
        .paso-item.hecho  .paso-num { background: var(--verde-light); color: var(--verde); border-color: var(--verde-light); }
        .paso-sep { color: var(--borde); margin-right: 16px; }

        /* Layout */
        .contenedor {
            flex: 1; display: flex; align-items: flex-start;
            justify-content: center; padding: 40px 24px; gap: 24px;
        }

        /* Panel pago */
        .panel-pago {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 16px; width: 100%; max-width: 480px; overflow: hidden;
        }
        .panel-header { padding: 20px 24px; border-bottom: 1px solid var(--borde); }
        .panel-titulo { font-size: 16px; font-weight: 600; color: var(--texto); }
        .panel-sub    { font-size: 13px; color: var(--texto-2); margin-top: 4px; }
        .panel-body   { padding: 24px; }

        /* Error */
        .alerta-error {
            background: var(--error-bg); border-radius: 10px; padding: 12px 16px;
            font-size: 13px; color: var(--error); margin-bottom: 20px;
            display: flex; align-items: center; gap: 8px;
        }
        .alerta-error svg { width: 16px; height: 16px; flex-shrink: 0; }

        /* Métodos de pago */
        .metodos-titulo {
            font-size: 12px; font-weight: 500; color: var(--texto-2);
            text-transform: uppercase; letter-spacing: .06em; margin-bottom: 12px;
        }
        .metodos-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 24px; }
        .metodo-label { cursor: pointer; display: block; }
        .metodo-label input[type="radio"] { display: none; }
        .metodo-card {
            border: 2px solid var(--borde); border-radius: 12px;
            padding: 16px; text-align: center; transition: border-color .15s, background .15s;
        }
        .metodo-label input:checked + .metodo-card {
            border-color: var(--verde); background: var(--verde-light);
        }
        .metodo-icono { font-size: 28px; margin-bottom: 8px; }
        .metodo-nombre { font-size: 13px; font-weight: 500; color: var(--texto); }
        .metodo-desc   { font-size: 11px; color: var(--texto-3); margin-top: 2px; }

        /* Simulación de tarjeta */
        .tarjeta-sim {
            background: linear-gradient(135deg, #0F6E56, #1D9E75);
            border-radius: 14px; padding: 20px 22px; margin-bottom: 20px;
            color: white; display: none;
        }
        .tarjeta-sim.visible { display: block; }
        .tarjeta-chip { width: 32px; height: 24px; background: rgba(255,255,255,.25); border-radius: 4px; margin-bottom: 16px; }
        .tarjeta-numero { font-family: 'DM Mono', monospace; font-size: 15px; letter-spacing: .15em; margin-bottom: 14px; opacity: .9; }
        .tarjeta-fila { display: flex; justify-content: space-between; font-size: 11px; opacity: .7; margin-bottom: 4px; }
        .tarjeta-datos { display: flex; justify-content: space-between; font-size: 13px; font-weight: 500; }

        /* Campos de tarjeta */
        .campos-tarjeta { display: none; margin-bottom: 20px; }
        .campos-tarjeta.visible { display: block; }
        .campo { margin-bottom: 14px; }
        .campo label { display: block; font-size: 12px; font-weight: 500; color: var(--texto-2); margin-bottom: 6px; }
        .campo input {
            width: 100%; padding: 10px 14px; border: 1.5px solid var(--borde);
            border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 13px;
            color: var(--texto); outline: none; transition: border-color .15s;
        }
        .campo input:focus { border-color: var(--verde); }
        .campo input::placeholder { color: var(--texto-3); }
        .fila-campos { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

        /* Divider */
        .divider { height: 1px; background: var(--borde); margin: 20px 0; }

        /* Botón pagar */
        .btn-pagar {
            width: 100%; padding: 14px; background: var(--verde); color: white;
            border: none; border-radius: 12px; font-family: 'DM Sans', sans-serif;
            font-size: 15px; font-weight: 600; cursor: pointer;
            transition: background .15s, transform .1s; letter-spacing: -0.1px;
        }
        .btn-pagar:hover  { background: var(--verde-dark); }
        .btn-pagar:active { transform: scale(0.99); }
        .btn-pagar:disabled { background: var(--texto-3); cursor: not-allowed; }

        .seguro-badge {
            display: flex; align-items: center; justify-content: center;
            gap: 6px; font-size: 11px; color: var(--texto-3); margin-top: 12px;
        }
        .seguro-badge svg { width: 12px; height: 12px; }

        /* Panel resumen */
        .panel-resumen {
            background: var(--blanco); border: 1px solid var(--borde);
            border-radius: 16px; width: 100%; max-width: 300px;
            padding: 20px 22px; position: sticky; top: 24px;
        }
        .resumen-titulo { font-size: 13px; font-weight: 600; color: var(--texto); margin-bottom: 16px; }
        .resumen-fila {
            display: flex; justify-content: space-between;
            font-size: 13px; color: var(--texto-2); margin-bottom: 10px;
        }
        .resumen-fila.total {
            border-top: 1px solid var(--borde); padding-top: 12px;
            margin-top: 4px; font-size: 16px; font-weight: 600; color: var(--texto);
        }
        .ruta-item { font-size: 12px; color: var(--texto-2); line-height: 1.5; margin-bottom: 14px; padding-bottom: 14px; border-bottom: 1px solid var(--borde); }
        .ruta-punto { display: flex; align-items: flex-start; gap: 8px; margin-bottom: 6px; }
        .ruta-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; margin-top: 4px; }
        .dot-origen  { background: var(--verde); }
        .dot-destino { background: var(--error); }

        @media (max-width: 780px) {
            .contenedor { flex-direction: column; align-items: center; }
            .panel-resumen { max-width: 480px; position: static; }
        }
    </style>
</head>
<body>

<%
    Viaje viaje = (Viaje) request.getAttribute("viaje");
    if (viaje == null) { response.sendRedirect(request.getContextPath() + "/pasajero/dashboard"); return; }
    String origenCorto = viaje.getOrigenDireccion() != null ? viaje.getOrigenDireccion() : "Origen";
    String destCorto   = viaje.getDestinoDireccion() != null ? viaje.getDestinoDireccion() : "Destino";
    if (origenCorto.length() > 45) origenCorto = origenCorto.substring(0,45) + "…";
    if (destCorto.length()   > 45) destCorto   = destCorto.substring(0,45)   + "…";
    double tarifa  = 15.00;
    double porKm   = viaje.getDistanciaKm() * 8.5;
    double cargo   = 3.00;
%>

<nav>
    <span class="nav-logo">Urbvan</span>
    <span class="nav-paso">Viaje #<%= viaje.getIdViaje() %></span>
</nav>

<!-- Barra de pasos -->
<div class="pasos-barra">
    <div class="paso-item hecho">
        <div class="paso-num">✓</div> Ruta
    </div>
    <span class="paso-sep">›</span>
    <div class="paso-item activo">
        <div class="paso-num">2</div> Pago
    </div>
    <span class="paso-sep">›</span>
    <div class="paso-item">
        <div class="paso-num">3</div> Seguimiento
    </div>
</div>

<div class="contenedor">

    <!-- Panel de pago -->
    <div class="panel-pago">
        <div class="panel-header">
            <div class="panel-titulo">Elige cómo pagar</div>
            <div class="panel-sub">Pago 100% seguro y simulado para esta demostración</div>
        </div>
        <div class="panel-body">

            <% if (request.getAttribute("error") != null) { %>
            <div class="alerta-error">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <%= request.getAttribute("error") %>
            </div>
            <% } %>

            <form method="POST" action="${pageContext.request.contextPath}/pasajero/pago"
                  id="form-pago" onsubmit="return validarPago()">
                <input type="hidden" name="id_viaje" value="<%= viaje.getIdViaje() %>">
                <input type="hidden" name="metodo_pago" id="metodo-hidden" value="">

                <div class="metodos-titulo">Método de pago</div>

                <div class="metodos-grid">
                    <label class="metodo-label">
                        <input type="radio" name="metodo" value="TARJETA"
                               onchange="seleccionarMetodo('TARJETA')">
                        <div class="metodo-card">
                            <div class="metodo-icono">💳</div>
                            <div class="metodo-nombre">Tarjeta</div>
                            <div class="metodo-desc">Crédito o débito</div>
                        </div>
                    </label>
                    <label class="metodo-label">
                        <input type="radio" name="metodo" value="EFECTIVO"
                               onchange="seleccionarMetodo('EFECTIVO')">
                        <div class="metodo-card">
                            <div class="metodo-icono">💵</div>
                            <div class="metodo-nombre">Efectivo</div>
                            <div class="metodo-desc">Paga al operador</div>
                        </div>
                    </label>
                </div>

                <!-- Tarjeta simulada -->
                <div class="tarjeta-sim" id="tarjeta-visual">
                    <div class="tarjeta-chip"></div>
                    <div class="tarjeta-numero" id="num-visual">•••• •••• •••• ••••</div>
                    <div class="tarjeta-fila">
                        <span>TITULAR</span><span>VENCE</span>
                    </div>
                    <div class="tarjeta-datos">
                        <span id="nombre-visual">NOMBRE APELLIDO</span>
                        <span id="fecha-visual">MM/AA</span>
                    </div>
                </div>

                <!-- Campos de tarjeta simulados -->
                <div class="campos-tarjeta" id="campos-tarjeta">
                    <div class="campo">
                        <label>Número de tarjeta</label>
                        <input type="text" id="num-tarjeta" placeholder="1234 5678 9012 3456"
                               maxlength="19" oninput="formatearTarjeta(this)"/>
                    </div>
                    <div class="campo">
                        <label>Nombre del titular</label>
                        <input type="text" id="nombre-tarjeta" placeholder="Como aparece en la tarjeta"
                               oninput="actualizarNombre(this.value)"/>
                    </div>
                    <div class="fila-campos">
                        <div class="campo">
                            <label>Vencimiento</label>
                            <input type="text" id="fecha-tarjeta" placeholder="MM/AA"
                                   maxlength="5" oninput="formatearFecha(this)"/>
                        </div>
                        <div class="campo">
                            <label>CVV</label>
                            <input type="text" id="cvv-tarjeta" placeholder="123" maxlength="3"/>
                        </div>
                    </div>
                    <div style="font-size:11px;color:var(--texto-3);margin-top:-6px">
                        Datos de prueba — ningún cargo real será efectuado.
                    </div>
                </div>

                <div class="divider"></div>

                <button type="submit" class="btn-pagar" id="btn-pagar" disabled>
                    Pagar $<%= String.format("%.2f", viaje.getPrecioTotal()) %> MXN
                </button>

                <div class="seguro-badge">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                    </svg>
                    Pago simulado · Ningún cargo real
                </div>

            </form>
        </div>
    </div>

    <!-- Resumen del viaje -->
    <div class="panel-resumen">
        <div class="resumen-titulo">Resumen del viaje</div>
        <div class="ruta-item">
            <div class="ruta-punto">
                <span class="ruta-dot dot-origen"></span>
                <span><%= origenCorto %></span>
            </div>
            <div class="ruta-punto">
                <span class="ruta-dot dot-destino"></span>
                <span><%= destCorto %></span>
            </div>
        </div>
        <div class="resumen-fila">
            <span>Distancia</span>
            <span><%= String.format("%.2f", viaje.getDistanciaKm()) %> km</span>
        </div>
        <div class="resumen-fila">
            <span>Tiempo estimado</span>
            <span><%= viaje.getEtaViajeMin() %> min</span>
        </div>
        <div class="divider"></div>
        <div class="resumen-fila">
            <span>Tarifa base</span>
            <span>$<%= String.format("%.2f", tarifa) %></span>
        </div>
        <div class="resumen-fila">
            <span>Costo por km</span>
            <span>$<%= String.format("%.2f", porKm) %></span>
        </div>
        <div class="resumen-fila">
            <span>Cargo de servicio</span>
            <span>$<%= String.format("%.2f", cargo) %></span>
        </div>
        <div class="resumen-fila total">
            <span>Total</span>
            <span>$<%= String.format("%.2f", viaje.getPrecioTotal()) %></span>
        </div>
    </div>

</div>

<script>
function seleccionarMetodo(metodo) {
    document.getElementById('metodo-hidden').value = metodo;
    document.getElementById('btn-pagar').disabled = false;

    var campos   = document.getElementById('campos-tarjeta');
    var tarjeta  = document.getElementById('tarjeta-visual');

    if (metodo === 'TARJETA') {
        campos.classList.add('visible');
        tarjeta.classList.add('visible');
    } else {
        campos.classList.remove('visible');
        tarjeta.classList.remove('visible');
    }
}

function formatearTarjeta(input) {
    var val = input.value.replace(/\D/g, '').substring(0, 16);
    input.value = val.replace(/(.{4})/g, '$1 ').trim();
    document.getElementById('num-visual').textContent =
        (val + '················').substring(0,16).replace(/(.{4})/g,'$1 ').trim();
}

function formatearFecha(input) {
    var val = input.value.replace(/\D/g,'').substring(0,4);
    if (val.length >= 2) val = val.substring(0,2) + '/' + val.substring(2);
    input.value = val;
    document.getElementById('fecha-visual').textContent = val || 'MM/AA';
}

function actualizarNombre(val) {
    document.getElementById('nombre-visual').textContent =
        val.toUpperCase() || 'NOMBRE APELLIDO';
}

function validarPago() {
    var metodo = document.getElementById('metodo-hidden').value;
    if (!metodo) { alert('Selecciona un método de pago.'); return false; }

    var btn = document.getElementById('btn-pagar');
    btn.disabled = true;
    btn.textContent = 'Procesando pago…';
    return true;
}
</script>

</body>
</html>
