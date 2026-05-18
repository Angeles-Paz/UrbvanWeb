<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Solicitar viaje</title>
    <link rel="stylesheet" href="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css"/>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        :root {
            --verde: #1D9E75; --verde-dark: #0F6E56; --verde-light: #E1F5EE;
            --texto: #1a1a1a; --texto-2: #5a5a5a; --texto-3: #9a9a9a;
            --borde: #e4e4e4; --fondo: #f7f7f5; --blanco: #ffffff;
            --error: #D85A30; --error-bg: #FAECE7;
        }
        body {
            font-family: 'DM Sans', sans-serif; background: var(--fondo);
            height: 100vh; display: grid;
            grid-template-rows: 56px 1fr;
            grid-template-columns: 380px 1fr;
            grid-template-areas: "nav nav" "panel mapa";
        }
        nav {
            grid-area: nav; background: var(--blanco);
            border-bottom: 1px solid var(--borde);
            display: flex; align-items: center;
            justify-content: space-between; padding: 0 24px;
        }
        .nav-logo { font-size: 18px; font-weight: 600; color: var(--verde-dark); }
        .nav-usuario { display: flex; align-items: center; gap: 16px; font-size: 13px; color: var(--texto-2); }
        .nav-usuario strong { color: var(--texto); font-weight: 500; }
        .btn-logout {
            font-size: 12px; color: var(--texto-3); text-decoration: none;
            padding: 5px 12px; border: 1px solid var(--borde); border-radius: 20px;
        }
        .btn-logout:hover { color: var(--error); border-color: var(--error); }
        .panel {
            grid-area: panel; background: var(--blanco);
            border-right: 1px solid var(--borde);
            display: flex; flex-direction: column; overflow-y: auto;
        }
        .panel-header { padding: 20px 24px 16px; border-bottom: 1px solid var(--borde); }
        .panel-titulo { font-size: 16px; font-weight: 600; color: var(--texto); margin-bottom: 4px; }
        .panel-sub { font-size: 12px; color: var(--texto-3); }
        .panel-body { padding: 20px 24px; flex: 1; }
        .campo-busqueda { margin-bottom: 16px; }
        .campo-busqueda label {
            display: flex; align-items: center; gap: 6px;
            font-size: 12px; font-weight: 500; color: var(--texto-2); margin-bottom: 6px;
        }
        .punto { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
        .punto-origen { background: var(--verde); }
        .punto-destino { background: var(--error); }
        .input-busqueda {
            width: 100%; padding: 10px 12px;
            border: 1.5px solid var(--borde); border-radius: 10px;
            font-family: 'DM Sans', sans-serif; font-size: 13px;
            color: var(--texto); outline: none; transition: border-color .15s;
        }
        .input-busqueda:focus { border-color: var(--verde); }
        .input-busqueda::placeholder { color: var(--texto-3); }
        .btn-ubicacion {
            width: 100%; padding: 8px; margin-top: 6px;
            background: var(--verde-light); color: var(--verde-dark);
            border: none; border-radius: 8px;
            font-family: 'DM Sans', sans-serif; font-size: 12px; font-weight: 500;
            cursor: pointer;
        }
        .btn-ubicacion:hover { background: #c8ede2; }
        .divisor-ruta { margin: 4px 0 4px 4px; color: var(--borde); font-size: 18px; }
        .resumen { background: var(--fondo); border-radius: 12px; padding: 16px; margin-top: 20px; display: none; }
        .resumen.visible { display: block; }
        .resumen-titulo { font-size: 11px; font-weight: 500; letter-spacing: .06em; text-transform: uppercase; color: var(--texto-3); margin-bottom: 14px; }
        .resumen-fila { display: flex; justify-content: space-between; font-size: 13px; color: var(--texto-2); margin-bottom: 8px; }
        .resumen-fila.total { border-top: 1px solid var(--borde); padding-top: 10px; margin-top: 6px; font-size: 15px; font-weight: 600; color: var(--texto); }
        .alerta-error { background: var(--error-bg); border-radius: 8px; padding: 10px 12px; font-size: 12px; color: var(--error); margin-bottom: 12px; display: none; }
        .alerta-error.visible { display: block; }
        .btn-confirmar { width: 100%; padding: 13px; background: var(--verde); color: white; border: none; border-radius: 10px; font-family: 'DM Sans', sans-serif; font-size: 15px; font-weight: 500; cursor: pointer; margin-top: 16px; display: none; }
        .btn-confirmar.visible { display: block; }
        .btn-confirmar:hover { background: var(--verde-dark); }
        #mapa { grid-area: mapa; width: 100%; height: 100%; }
        #form-viaje { display: none; }
    </style>
</head>
<body>

<nav>
    <span class="nav-logo">Urbvan</span>
    <div class="nav-usuario">
        Hola, <strong>${sessionScope.nombre}</strong>
        <a href="${pageContext.request.contextPath}/logout" class="btn-logout">Cerrar sesión</a>
    </div>
</nav>

<div class="panel">
    <div class="panel-header">
        <div class="panel-titulo">Solicitar viaje</div>
        <div class="panel-sub">Selecciona tu origen y destino en el mapa</div>
    </div>
    <div class="panel-body">
        <div id="alerta" class="alerta-error"></div>
        <div class="campo-busqueda">
            <label><span class="punto punto-origen"></span>Punto de origen</label>
            <input type="text" id="input-origen" class="input-busqueda" placeholder="Haz clic en el mapa" readonly/>
            <button type="button" class="btn-ubicacion" onclick="usarUbicacionActual()">Usar mi ubicación actual</button>
        </div>
        <div class="divisor-ruta">│</div>
        <div class="campo-busqueda">
            <label><span class="punto punto-destino"></span>Destino</label>
            <input type="text" id="input-destino" class="input-busqueda" placeholder="Escribe y presiona Enter"/>
        </div>
        <div id="resumen" class="resumen">
            <div class="resumen-titulo">Resumen del viaje</div>
            <div class="resumen-fila"><span>Distancia</span><span id="r-distancia">—</span></div>
            <div class="resumen-fila"><span>Tiempo estimado</span><span id="r-eta">—</span></div>
            <div class="resumen-fila"><span>Tarifa base</span><span>$15.00</span></div>
            <div class="resumen-fila"><span>Costo por km</span><span id="r-costo-km">—</span></div>
            <div class="resumen-fila"><span>Cargo de servicio</span><span>$3.00</span></div>
            <div class="resumen-fila total"><span>Total</span><span id="r-total">$0.00</span></div>
        </div>
        <button type="button" id="btn-confirmar" class="btn-confirmar" onclick="confirmarViaje()">
            Continuar al pago →
        </button>
    </div>
</div>

<div id="mapa"></div>

<form id="form-viaje" method="POST" action="${pageContext.request.contextPath}/pasajero/solicitar">
    <input type="hidden" id="f-origen-lat"  name="origen_lat">
    <input type="hidden" id="f-origen-lng"  name="origen_lng">
    <input type="hidden" id="f-origen-dir"  name="origen_direccion">
    <input type="hidden" id="f-destino-lat" name="destino_lat">
    <input type="hidden" id="f-destino-lng" name="destino_lng">
    <input type="hidden" id="f-destino-dir" name="destino_direccion">
    <input type="hidden" id="f-distancia"   name="distancia_km">
    <input type="hidden" id="f-eta"         name="eta_min">
</form>

<script>
    var AZURE_KEY = '1iXcaVW3TPpFb16nqn0fOdmUzXa9PTEIUz67L6z8IhMUGCgC3CazJQQJ99CEAC8vTInh3jNvAAAgAZMPPoqn';
    var CTX_PATH  = '${pageContext.request.contextPath}';
</script>
<script src="https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js"></script>
<script src="${pageContext.request.contextPath}/assets/js/mapa.js"></script>

</body>
</html>
