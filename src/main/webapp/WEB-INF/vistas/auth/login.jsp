<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Iniciar sesión</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=DM+Mono:wght@400;500&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --verde:     #1D9E75;
            --verde-dark:#0F6E56;
            --verde-light:#E1F5EE;
            --texto:     #1a1a1a;
            --texto-2:   #5a5a5a;
            --texto-3:   #9a9a9a;
            --borde:     #e4e4e4;
            --fondo:     #f7f7f5;
            --blanco:    #ffffff;
            --error:     #D85A30;
            --error-bg:  #FAECE7;
            --exito:    #1D9E75;
            --exito-bg: #E1F5EE;
        }

        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--fondo);
            min-height: 100vh;
            display: grid;
            grid-template-columns: 1fr 1fr;
        }

        /* ── Panel izquierdo — branding ── */
        .panel-marca {
            background: var(--verde-dark);
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            padding: 48px;
            position: relative;
            overflow: hidden;
        }

        .panel-marca::before {
            content: '';
            position: absolute;
            width: 480px; height: 480px;
            border-radius: 50%;
            border: 60px solid rgba(255,255,255,0.05);
            top: -120px; left: -120px;
        }

        .panel-marca::after {
            content: '';
            position: absolute;
            width: 320px; height: 320px;
            border-radius: 50%;
            border: 40px solid rgba(255,255,255,0.04);
            bottom: -80px; right: -80px;
        }

        .logo {
            display: flex;
            align-items: center;
            gap: 10px;
            position: relative;
            z-index: 1;
        }

        .logo-icono {
            width: 36px; height: 36px;
            background: rgba(255,255,255,0.15);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
        }

        .logo-icono svg { width: 20px; height: 20px; fill: white; }

        .logo-texto {
            font-size: 20px;
            font-weight: 600;
            color: white;
            letter-spacing: -0.3px;
        }

        .marca-contenido {
            position: relative;
            z-index: 1;
        }

        .marca-tag {
            display: inline-block;
            font-size: 11px;
            font-weight: 500;
            letter-spacing: .1em;
            text-transform: uppercase;
            color: rgba(255,255,255,0.5);
            margin-bottom: 20px;
        }

        .marca-titulo {
            font-size: 36px;
            font-weight: 300;
            color: white;
            line-height: 1.25;
            margin-bottom: 20px;
        }

        .marca-titulo strong { font-weight: 600; }

        .marca-desc {
            font-size: 14px;
            color: rgba(255,255,255,0.6);
            line-height: 1.7;
            max-width: 340px;
        }

        .marca-stats {
            display: flex;
            gap: 32px;
            position: relative;
            z-index: 1;
        }

        .stat-item { }
        .stat-num {
            font-size: 24px;
            font-weight: 600;
            color: white;
            line-height: 1;
        }
        .stat-label {
            font-size: 12px;
            color: rgba(255,255,255,0.5);
            margin-top: 4px;
        }

        /* ── Panel derecho — formulario ── */
        .panel-form {
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 48px 40px;
        }

        .form-contenedor {
            width: 100%;
            max-width: 380px;
        }

        .form-encabezado {
            margin-bottom: 36px;
        }

        .form-titulo {
            font-size: 24px;
            font-weight: 600;
            color: var(--texto);
            margin-bottom: 6px;
            letter-spacing: -0.3px;
        }

        .form-subtitulo {
            font-size: 14px;
            color: var(--texto-2);
        }

        /* Alerta de error */
        .alerta-error {
            background: var(--error-bg);
            border: 1px solid rgba(216,90,48,0.2);
            border-radius: 10px;
            padding: 12px 16px;
            font-size: 13px;
            color: var(--error);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .alerta-error svg { width: 16px; height: 16px; flex-shrink: 0; }

        .alerta-exito {
            background: var(--exito-bg);
            color: var(--exito);
            border: 1px solid rgba(29,158,117,0.2);
            border-radius: 10px;
            padding: 12px 16px;
            font-size: 13px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .alerta-exito svg { width: 16px; height: 16px; flex-shrink: 0; }

        /* Campos del formulario */
        .campo {
            margin-bottom: 18px;
        }

        .campo label {
            display: block;
            font-size: 13px;
            font-weight: 500;
            color: var(--texto);
            margin-bottom: 7px;
        }

        .campo input {
            width: 100%;
            padding: 11px 14px;
            border: 1.5px solid var(--borde);
            border-radius: 10px;
            font-family: 'DM Sans', sans-serif;
            font-size: 14px;
            color: var(--texto);
            background: var(--blanco);
            transition: border-color .15s, box-shadow .15s;
            outline: none;
        }

        .campo input:focus {
            border-color: var(--verde);
            box-shadow: 0 0 0 3px rgba(29,158,117,0.12);
        }

        .campo input::placeholder { color: var(--texto-3); }

        /* Fila de recordarme + olvidé */
        .fila-opciones {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 24px;
        }

        .check-label {
            display: flex;
            align-items: center;
            gap: 7px;
            font-size: 13px;
            color: var(--texto-2);
            cursor: pointer;
        }

        .check-label input[type="checkbox"] {
            width: 16px; height: 16px;
            accent-color: var(--verde);
            cursor: pointer;
        }

        .link-olvide {
            font-size: 13px;
            color: var(--verde);
            text-decoration: none;
            font-weight: 500;
        }

        .link-olvide:hover { text-decoration: underline; }

        /* Botón principal */
        .btn-ingresar {
            width: 100%;
            padding: 13px;
            background: var(--verde);
            color: white;
            border: none;
            border-radius: 10px;
            font-family: 'DM Sans', sans-serif;
            font-size: 15px;
            font-weight: 500;
            cursor: pointer;
            transition: background .15s, transform .1s;
            letter-spacing: -0.1px;
        }

        .btn-ingresar:hover  { background: var(--verde-dark); }
        .btn-ingresar:active { transform: scale(0.99); }

        /* Divisor */
        .divisor {
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 24px 0;
            color: var(--texto-3);
            font-size: 12px;
        }

        .divisor::before, .divisor::after {
            content: '';
            flex: 1;
            height: 1px;
            background: var(--borde);
        }

        /* Enlace de registro */
        .pie-form {
            text-align: center;
            font-size: 14px;
            color: var(--texto-2);
        }

        .pie-form a {
            color: var(--verde);
            font-weight: 500;
            text-decoration: none;
        }

        .pie-form a:hover { text-decoration: underline; }

        /* Chips de roles */
        .roles-chips {
            display: flex;
            gap: 6px;
            flex-wrap: wrap;
            margin-top: 20px;
        }

        .chip {
            font-size: 11px;
            padding: 4px 10px;
            border-radius: 20px;
            border: 1px solid var(--borde);
            color: var(--texto-3);
            background: var(--blanco);
        }

        /* Responsive */
        @media (max-width: 768px) {
            body { grid-template-columns: 1fr; }
            .panel-marca { display: none; }
            .panel-form { padding: 40px 24px; }
        }
    </style>
</head>
<body>

<!-- ── Panel izquierdo — branding ── -->
<div class="panel-marca">
    <div class="logo">
        <div class="logo-icono">
            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M18 8h1a4 4 0 0 1 0 8h-1M2 9l3-3 3 3M5 6v12M2 16h16a2 2 0 0 0 0-4H4a2 2 0 0 1 0-4h1"/>
            </svg>
        </div>
        <span class="logo-texto">Urbvan</span>
    </div>

    <div class="marca-contenido">
        <span class="marca-tag">Ciudad de México</span>
        <h1 class="marca-titulo">
            Transporte urbano<br>
            <strong>inteligente</strong>
        </h1>
        <p class="marca-desc">
            Conectamos pasajeros con operadores verificados en toda la CDMX.
            Viajes seguros, cómodos y a tiempo — cuando los necesitas.
        </p>
    </div>

    <div class="marca-stats">
        <div class="stat-item">
            <div class="stat-num">16</div>
            <div class="stat-label">Alcaldías</div>
        </div>
        <div class="stat-item">
            <div class="stat-num">3</div>
            <div class="stat-label">Roles de acceso</div>
        </div>
        <div class="stat-item">
            <div class="stat-num">24/7</div>
            <div class="stat-label">Disponible</div>
        </div>
    </div>
</div>

<!-- ── Panel derecho — formulario ── -->
<div class="panel-form">
    <div class="form-contenedor">

        <div class="form-encabezado">
            <h2 class="form-titulo">Bienvenido de nuevo</h2>
            <p class="form-subtitulo">Ingresa tus credenciales para continuar</p>
        </div>

        <%-- Alerta de registro exitoso --%>
        <% if ("ok".equals(request.getParameter("registro"))) { %>
        <div class="alerta-exito">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
                <polyline points="22 4 12 14.01 9 11.01"/>
            </svg>
            Cuenta creada exitosamente. Ya puedes iniciar sesión.
        </div>
        <% } %>

        <%-- Mostrar error si existe --%>
        <% if (request.getAttribute("error") != null) { %>
        <div class="alerta-error">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <%= request.getAttribute("error") %>
        </div>
        <% } %>

        <form method="POST" action="${pageContext.request.contextPath}/login" novalidate>

            <div class="campo">
                <label for="correo">Correo electrónico</label>
                <input
                    type="email"
                    id="correo"
                    name="correo"
                    placeholder="tu@correo.com"
                    value="<%= request.getAttribute("error") != null && request.getParameter("correo") != null
                               ? request.getParameter("correo") : "" %>"
                    required
                    autocomplete="email"
                />
            </div>

            <div class="campo">
                <label for="contrasena">Contraseña</label>
                <input
                    type="password"
                    id="contrasena"
                    name="contrasena"
                    placeholder="••••••••"
                    required
                    autocomplete="current-password"
                />
            </div>

            <div class="fila-opciones">
                <label class="check-label">
                    <input type="checkbox" name="recordar"> Recordarme
                </label>
                <a href="#" class="link-olvide">¿Olvidaste tu contraseña?</a>
            </div>

            <button type="submit" class="btn-ingresar">Iniciar sesión</button>

        </form>

        <div class="divisor">acceso por rol</div>

        <div class="roles-chips">
            <span class="chip">Pasajero</span>
            <span class="chip">Operador</span>
            <span class="chip">Administrador</span>
        </div>

        <div class="pie-form" style="margin-top: 28px;">
            ¿No tienes cuenta? <a href="${pageContext.request.contextPath}/registro">Regístrate aquí</a>
        </div>

    </div>
</div>

</body>
</html>
