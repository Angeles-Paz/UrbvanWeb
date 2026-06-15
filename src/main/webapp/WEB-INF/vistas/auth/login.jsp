<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan - Iniciar sesión</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        *{box-sizing:border-box;margin:0;padding:0}
        :root{--purple:#9D00FF;--purple-dark:#7B00CC;--purple-light:#F5EEFF;--purple-subtle:rgba(157,0,255,.1)}
        body{
            font-family:'DM Sans',sans-serif;
            background:#F5F6FA;min-height:100vh;
            display:flex;align-items:center;justify-content:center;
            padding:24px;
        }
        .auth-wrap{
            width:100%;max-width:440px;
        }
        .auth-header{text-align:center;margin-bottom:28px}
        /* Logo: reemplaza este SVG con <img src="assets/img/tu-logo.png" alt="Urbvan" style="height:48px"> */
        .auth-logo-svg{display:block;margin:0 auto 12px}
        .auth-brand{font-size:26px;font-weight:800;color:var(--purple);letter-spacing:-.5px}
        .auth-sub{color:#6B7280;font-size:14px;margin-top:4px}

        .auth-card{
            background:#fff;
            border-radius:18px;padding:36px;
            box-shadow:0 4px 32px rgba(0,0,0,.08);
            border:1px solid #E5E7EB;
        }
        .auth-title{font-size:20px;font-weight:700;color:#111827;margin-bottom:24px}

        label{display:block;color:#6B7280;font-size:13px;font-weight:600;margin-bottom:6px;letter-spacing:.2px}
        input{
            width:100%;padding:12px 14px;
            background:#fff;border:1.5px solid #E5E7EB;
            border-radius:10px;color:#111827;
            font-size:15px;font-family:'DM Sans',sans-serif;
            margin-bottom:18px;outline:none;
            transition:border-color .18s,box-shadow .18s;
        }
        input:focus{
            border-color:var(--purple);
            box-shadow:0 0 0 3px var(--purple-subtle);
        }
        .btn-submit{
            width:100%;padding:14px;
            background:var(--purple);color:#fff;
            border:none;border-radius:10px;
            font-size:15px;font-weight:700;
            font-family:'DM Sans',sans-serif;
            cursor:pointer;transition:all .18s;
        }
        .btn-submit:hover{
            background:var(--purple-dark);
            transform:translateY(-1px);
            box-shadow:0 4px 14px var(--purple-subtle);
        }
        .alerta-error{
            background:#FEF2F2;color:#DC2626;
            border-radius:8px;padding:12px 16px;
            font-size:14px;margin-bottom:20px;
            border-left:4px solid #DC2626;
        }
        .alerta-ok{
            background:#ECFDF5;color:#065F46;
            border-radius:8px;padding:12px 16px;
            font-size:14px;margin-bottom:20px;
            border-left:4px solid #10B981;
        }
        .auth-links{text-align:center;margin-top:20px;color:#6B7280;font-size:14px}
        .auth-links a{color:var(--purple);text-decoration:none;font-weight:600}
        .auth-links a:hover{text-decoration:underline}
        .divider{height:1px;background:#E5E7EB;margin:20px 0}
    </style>
</head>
<body>
<div class="auth-wrap">
        <div class="auth-header">
        <img src="${pageContext.request.contextPath}/assets/img/Logo_UrbvanPasajero.png"
             alt="Urbvan"
             style="height:56px;width:auto;display:block;margin:0 auto 10px;object-fit:contain">
        <div class="auth-sub">Transporte urbano inteligente</div>
    </div>

    <div class="auth-card">
        <div class="auth-title">Iniciar sesión</div>

        <c:if test="${not empty error}">
            <div class="alerta-error">${error}</div>
        </c:if>
        <c:if test="${param.registro == 'ok'}">
            <div class="alerta-ok">¡Cuenta creada! Ya puedes iniciar sesión.</div>
        </c:if>
        <c:if test="${param.recuperacion == 'ok'}">
            <div class="alerta-ok">Contraseña actualizada correctamente.</div>
        </c:if>

        <form method="post" action="${pageContext.request.contextPath}/login">
            <label for="email">Correo electrónico</label>
            <input type="email" id="email" name="email" placeholder="correo@ejemplo.com" required autofocus>
            <label for="contrasena">Contraseña</label>
            <input type="password" id="contrasena" name="contrasena" placeholder="Tu contraseña" required>
            <button type="submit" class="btn-submit">Entrar</button>
        </form>

        <div class="divider"></div>
        <div class="auth-links">¿No tienes cuenta? <a href="${pageContext.request.contextPath}/registro">Regístrate gratis</a></div>
        <div class="auth-links" style="margin-top:10px"><a href="${pageContext.request.contextPath}/recuperar">Olvidé mi contraseña</a></div>
    </div>
</div>
</body>
</html>
