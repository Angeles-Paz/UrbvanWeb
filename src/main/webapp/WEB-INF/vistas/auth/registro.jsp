<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan — Crear cuenta</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --verde:      #1D9E75;
            --verde-dark: #0F6E56;
            --verde-light:#E1F5EE;
            --texto:      #1a1a1a;
            --texto-2:    #5a5a5a;
            --texto-3:    #9a9a9a;
            --borde:      #e4e4e4;
            --fondo:      #f7f7f5;
            --blanco:     #ffffff;
            --error:      #D85A30;
            --error-bg:   #FAECE7;
            --exito:      #1D9E75;
            --exito-bg:   #E1F5EE;
        }

        body {
            font-family: 'DM Sans', sans-serif;
            background: var(--fondo);
            min-height: 100vh;
            display: grid;
            grid-template-columns: 1fr 1fr;
        }

        /* ── Panel izquierdo ── */
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

        .logo-icono svg { width: 20px; height: 20px; fill: none; stroke: white; stroke-width: 2; stroke-linecap: round; }

        .logo-texto { font-size: 20px; font-weight: 600; color: white; letter-spacing: -0.3px; }

        .marca-contenido { position: relative; z-index: 1; }

        .marca-tag {
            display: inline-block;
            font-size: 11px; font-weight: 500;
            letter-spacing: .1em; text-transform: uppercase;
            color: rgba(255,255,255,0.5); margin-bottom: 20px;
        }

        .marca-titulo {
            font-size: 34px; font-weight: 300;
            color: white; line-height: 1.25; margin-bottom: 20px;
        }

        .marca-titulo strong { font-weight: 600; }

        .marca-desc {
            font-size: 14px; color: rgba(255,255,255,0.6);
            line-height: 1.7; max-width: 340px;
        }

        .pasos { position: relative; z-index: 1; }

        .paso {
            display: flex; align-items: flex-start;
            gap: 14px; margin-bottom: 20px;
        }

        .paso-num {
            width: 28px; height: 28px; border-radius: 50%;
            background: rgba(255,255,255,0.12);
            display: flex; align-items: center; justify-content: center;
            font-size: 12px; font-weight: 600; color: white;
            flex-shrink: 0; margin-top: 1px;
        }

        .paso-texto strong {
            display: block; font-size: 13px;
            font-weight: 500; color: white; margin-bottom: 2px;
        }

        .paso-texto span { font-size: 12px; color: rgba(255,255,255,0.5); }

        /* ── Panel derecho ── */
        .panel-form {
            display: flex; align-items: center;
            justify-content: center; padding: 40px 40px;
            overflow-y: auto;
        }

        .form-contenedor { width: 100%; max-width: 420px; }

        .form-encabezado { margin-bottom: 28px; }

        .form-titulo {
            font-size: 24px; font-weight: 600;
            color: var(--texto); margin-bottom: 6px; letter-spacing: -0.3px;
        }

        .form-subtitulo { font-size: 14px; color: var(--texto-2); }

        /* Alertas */
        .alerta {
            border-radius: 10px; padding: 12px 16px;
            font-size: 13px; margin-bottom: 20px;
            display: flex; align-items: center; gap: 8px;
        }

        .alerta svg { width: 16px; height: 16px; flex-shrink: 0; }
        .alerta-error  { background: var(--error-bg);  color: var(--error);  border: 1px solid rgba(216,90,48,0.2); }
        .alerta-exito  { background: var(--exito-bg);  color: var(--exito);  border: 1px solid rgba(29,158,117,0.2); }

        /* Fila de dos columnas */
        .fila-doble { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }

        /* Campos */
        .campo { margin-bottom: 16px; }

        .campo label {
            display: block; font-size: 13px;
            font-weight: 500; color: var(--texto); margin-bottom: 7px;
        }

        .campo input {
            width: 100%; padding: 11px 14px;
            border: 1.5px solid var(--borde); border-radius: 10px;
            font-family: 'DM Sans', sans-serif; font-size: 14px;
            color: var(--texto); background: var(--blanco);
            transition: border-color .15s, box-shadow .15s; outline: none;
        }

        .campo input:focus {
            border-color: var(--verde);
            box-shadow: 0 0 0 3px rgba(29,158,117,0.12);
        }

        .campo input::placeholder { color: var(--texto-3); }

        .campo-hint {
            font-size: 11px; color: var(--texto-3); margin-top: 5px;
        }

        /* Botón */
        .btn-registrar {
            width: 100%; padding: 13px;
            background: var(--verde); color: white;
            border: none; border-radius: 10px;
            font-family: 'DM Sans', sans-serif;
            font-size: 15px; font-weight: 500;
            cursor: pointer; margin-top: 8px;
            transition: background .15s, transform .1s;
            letter-spacing: -0.1px;
        }

        .btn-registrar:hover  { background: var(--verde-dark); }
        .btn-registrar:active { transform: scale(0.99); }

        /* Pie */
        .pie-form {
            text-align: center; font-size: 14px;
            color: var(--texto-2); margin-top: 24px;
        }

        .pie-form a { color: var(--verde); font-weight: 500; text-decoration: none; }
        .pie-form a:hover { text-decoration: underline; }

        /* Divider */
        .divisor {
            display: flex; align-items: center;
            gap: 12px; margin: 20px 0;
            color: var(--texto-3); font-size: 12px;
        }
        .divisor::before, .divisor::after {
            content: ''; flex: 1; height: 1px; background: var(--borde);
        }

        @media (max-width: 768px) {
            body { grid-template-columns: 1fr; }
            .panel-marca { display: none; }
            .panel-form { padding: 32px 20px; }
            .fila-doble { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<!-- ── Panel izquierdo ── -->
<div class="panel-marca">
    <div class="logo">
        <div class="logo-icono">
            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11a2 2 0 0 1 2 2v3"/>
                <rect x="9" y="11" width="14" height="10" rx="2"/>
                <circle cx="12" cy="21" r="1"/><circle cx="20" cy="21" r="1"/>
            </svg>
        </div>
        <span class="logo-texto">Urbvan</span>
    </div>

    <div class="marca-contenido">
        <span class="marca-tag">Únete hoy</span>
        <h1 class="marca-titulo">Tu viaje comienza<br><strong>aquí</strong></h1>
        <p class="marca-desc">
            Crea tu cuenta en segundos y empieza a solicitar viajes seguros
            en toda la Ciudad de México.
        </p>
    </div>

    <div class="pasos">
        <div class="paso">
            <div class="paso-num">1</div>
            <div class="paso-texto">
                <strong>Crea tu cuenta</strong>
                <span>Llena el formulario con tus datos básicos</span>
            </div>
        </div>
        <div class="paso">
            <div class="paso-num">2</div>
            <div class="paso-texto">
                <strong>Solicita tu viaje</strong>
                <span>Indica tu origen y destino en el mapa</span>
            </div>
        </div>
        <div class="paso">
            <div class="paso-num">3</div>
            <div class="paso-texto">
                <strong>Viaja seguro</strong>
                <span>Un operador verificado llegará a recogerte</span>
            </div>
        </div>
    </div>
</div>

<!-- ── Panel derecho ── -->
<div class="panel-form">
    <div class="form-contenedor">

        <div class="form-encabezado">
            <h2 class="form-titulo">Crear cuenta</h2>
            <p class="form-subtitulo">Todos los campos marcados son obligatorios</p>
        </div>

        <%-- Alerta de error --%>
        <% if (request.getAttribute("error") != null) { %>
        <div class="alerta alerta-error">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <line x1="12" y1="8" x2="12" y2="12"/>
                <line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <%= request.getAttribute("error") %>
        </div>
        <% } %>

        <%-- Ayudante para recuperar valor previo o vacío --%>
        <%!
            private String val(jakarta.servlet.http.HttpServletRequest r, String attr) {
                Object v = r.getAttribute(attr);
                return v != null ? (String) v : "";
            }
        %>

        <form method="POST" action="${pageContext.request.contextPath}/registro" novalidate>

            <div class="fila-doble">
                <div class="campo">
                    <label for="nombre">Nombre *</label>
                    <input type="text" id="nombre" name="nombre"
                           placeholder="Ej. Ángel"
                           value="<%= val(request, "val_nombre") %>"
                           required autocomplete="given-name"/>
                </div>
                <div class="campo">
                    <label for="apellido">Apellido *</label>
                    <input type="text" id="apellido" name="apellido"
                           placeholder="Ej. García"
                           value="<%= val(request, "val_apellido") %>"
                           required autocomplete="family-name"/>
                </div>
            </div>

            <div class="campo">
                <label for="correo">Correo electrónico *</label>
                <input type="email" id="correo" name="correo"
                       placeholder="tu@correo.com"
                       value="<%= val(request, "val_correo") %>"
                       required autocomplete="email"/>
            </div>

            <div class="campo">
                <label for="telefono">Teléfono</label>
                <input type="tel" id="telefono" name="telefono"
                       placeholder="55 1234 5678"
                       value="<%= val(request, "val_telefono") %>"
                       autocomplete="tel"/>
                <div class="campo-hint">Opcional — útil para que el operador te contacte</div>
            </div>

            <div class="divisor">contraseña</div>

            <div class="fila-doble">
                <div class="campo">
                    <label for="contrasena">Contraseña *</label>
                    <input type="password" id="contrasena" name="contrasena"
                           placeholder="Mínimo 6 caracteres"
                           required autocomplete="new-password"/>
                </div>
                <div class="campo">
                    <label for="contrasena_confirm">Confirmar *</label>
                    <input type="password" id="contrasena_confirm" name="contrasena_confirm"
                           placeholder="Repite tu contraseña"
                           required autocomplete="new-password"/>
                </div>
            </div>

            <button type="submit" class="btn-registrar">Crear mi cuenta</button>

        </form>

        <div class="pie-form">
            ¿Ya tienes cuenta? <a href="${pageContext.request.contextPath}/login">Inicia sesión</a>
        </div>

    </div>
</div>

</body>
</html>
