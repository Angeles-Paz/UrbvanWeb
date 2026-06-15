<%@ page contentType="text/html;charset=UTF-8" language="java" isELIgnored="true" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urbvan - Shuttles corporativos y transporte urbano en CDMX</title>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,400&display=swap" rel="stylesheet">
    <style>
        *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
        :root{
            --purple:#9D00FF;--purple-dark:#7B00CC;
            --purple-light:#F5EEFF;--purple-subtle:rgba(157,0,255,.1);
            --text:#111827;--text2:#6B7280;--text3:#9CA3AF;
            --border:#E5E7EB;--bg:#F9FAFB;
        }
        html{scroll-behavior:smooth}
        body{font-family:'DM Sans',sans-serif;background:#fff;color:var(--text);overflow-x:hidden}
        a{text-decoration:none;color:inherit}

        /* ── NAV ── */
        .nav{position:fixed;top:0;left:0;right:0;z-index:200;height:68px;padding:0 48px;
            display:flex;align-items:center;justify-content:space-between;
            background:#fff;border-bottom:1px solid var(--border);transition:box-shadow .3s}
        .nav.scrolled{box-shadow:0 4px 20px rgba(0,0,0,.06)}
        .logo{display:flex;align-items:center;gap:0;cursor:pointer}
        .logo-img{height:44px;width:auto;object-fit:contain}
        .nav-links{display:flex;gap:4px}
        .nav-link{padding:8px 16px;border-radius:8px;color:var(--text2);font-size:14px;font-weight:500;transition:all .18s}
        .nav-link:hover{color:var(--purple);background:var(--purple-light)}
        .nav-ctas{display:flex;gap:10px;align-items:center}
        .btn-ghost-nav{padding:9px 20px;border:1.5px solid var(--border);border-radius:10px;
            color:var(--text2);font-size:14px;font-weight:500;transition:all .18s}
        .btn-ghost-nav:hover{border-color:var(--purple);color:var(--purple)}
        .btn-primary-nav{padding:10px 24px;background:var(--purple);border-radius:10px;
            color:#fff;font-size:14px;font-weight:700;transition:all .18s}
        .btn-primary-nav:hover{background:var(--purple-dark);transform:translateY(-1px)}

        /* ── HERO ── */
        .hero{min-height:100vh;display:flex;align-items:center;justify-content:center;
            text-align:center;padding:120px 24px 80px;background:#fff;position:relative;overflow:hidden}
        .hero-bg-circle{position:absolute;width:600px;height:600px;
            background:radial-gradient(circle,rgba(157,0,255,.07) 0%,transparent 70%);
            top:-100px;left:50%;transform:translateX(-50%);pointer-events:none}
        .hero-inner{position:relative;max-width:860px;margin:0 auto}
        .hero-pill{display:inline-flex;align-items:center;gap:8px;padding:5px 16px 5px 6px;
            background:var(--purple-light);border:1px solid rgba(157,0,255,.2);
            border-radius:30px;font-size:13px;color:var(--purple);font-weight:500;margin-bottom:28px}
        .hero-pill-tag{background:var(--purple);color:#fff;border-radius:20px;
            padding:3px 10px;font-size:12px;font-weight:700}
        .hero-h1{font-size:clamp(38px,5.5vw,66px);font-weight:900;line-height:1.07;
            letter-spacing:-2px;margin-bottom:22px;color:var(--text)}
        .hero-h1 em{font-style:normal;background:linear-gradient(90deg,var(--purple),#C84BFF);
            -webkit-background-clip:text;-webkit-text-fill-color:transparent}
        .hero-p{font-size:clamp(15px,1.8vw,18px);color:var(--text2);line-height:1.7;
            max-width:600px;margin:0 auto 36px}
        .hero-btns{display:flex;gap:14px;justify-content:center;flex-wrap:wrap}
        .btn-hero-primary{padding:15px 34px;border-radius:12px;font-size:16px;font-weight:700;
            background:var(--purple);color:#fff;transition:all .2s}
        .btn-hero-primary:hover{background:var(--purple-dark);transform:translateY(-2px);
            box-shadow:0 8px 24px rgba(157,0,255,.3)}
        .btn-hero-outline{padding:15px 34px;border-radius:12px;font-size:16px;font-weight:600;
            border:1.5px solid var(--border);color:var(--text);transition:all .2s}
        .btn-hero-outline:hover{border-color:var(--purple);color:var(--purple)}

        /* ── STATS ── */
        .stats-strip{display:flex;gap:0;justify-content:center;margin-top:64px;
            padding-top:48px;border-top:1px solid var(--border);flex-wrap:wrap}
        .stat-item{text-align:center;padding:0 36px;position:relative}
        .stat-item+.stat-item::before{content:'';position:absolute;left:0;top:20%;bottom:20%;
            width:1px;background:var(--border)}
        .stat-num{font-size:clamp(26px,3vw,40px);font-weight:900;color:var(--text);letter-spacing:-1px}
        .stat-num span{color:var(--purple)}
        .stat-label{font-size:13px;color:var(--text3);margin-top:4px}

        /* ── TICKER ── */
        .ticker-wrap{overflow:hidden;padding:28px 0;
            border-top:1px solid var(--border);border-bottom:1px solid var(--border);
            background:var(--bg);position:relative}
        .ticker-fade-l{position:absolute;left:0;top:0;bottom:0;width:120px;
            background:linear-gradient(90deg,var(--bg),transparent);z-index:10;
            display:flex;align-items:center;padding-left:20px;
            font-size:11px;font-weight:700;color:var(--text3);letter-spacing:2px;text-transform:uppercase}
        .ticker-fade-r{position:absolute;right:0;top:0;bottom:0;width:120px;
            background:linear-gradient(270deg,var(--bg),transparent);z-index:10}
        .ticker-track{display:flex;gap:56px;width:max-content;
            animation:ticker 45s linear infinite;align-items:center}
        .ticker-track:hover{animation-play-state:paused}
        @keyframes ticker{from{transform:translateX(0)}to{transform:translateX(-50%)}}
        .ticker-co{display:flex;align-items:center;height:36px;flex-shrink:0}
        .ticker-logo{height:28px;width:auto;max-width:110px;object-fit:contain;
            filter:brightness(0);opacity:0.28;transition:opacity .2s}
        .ticker-co:hover .ticker-logo{opacity:0.55}

        /* ── SECTIONS ── */
        .section{padding:88px 24px}
        .section-inner{max-width:1140px;margin:0 auto}
        .section-center{text-align:center;max-width:640px;margin:0 auto}
        .section-tag{display:inline-block;font-size:11px;font-weight:800;
            letter-spacing:2.5px;text-transform:uppercase;color:var(--purple);margin-bottom:14px}
        .section-h2{font-size:clamp(28px,4vw,44px);font-weight:800;letter-spacing:-1.5px;
            line-height:1.1;margin-bottom:14px;color:var(--text)}
        .section-p{font-size:17px;color:var(--text2);line-height:1.65}
        .section-alt{background:var(--bg)}

        /* ── ICON WRAPPERS ── */
        .icon-wrap{width:52px;height:52px;background:var(--purple-light);border-radius:12px;
            display:flex;align-items:center;justify-content:center;margin-bottom:18px;flex-shrink:0;color:var(--purple)}
        .icon-wrap.sm{width:40px;height:40px}

        /* ── SOLUTION CARDS ── */
        .sol-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:20px;margin-top:48px}
        @media(max-width:900px){.sol-grid{grid-template-columns:1fr 1fr}}
        @media(max-width:600px){.sol-grid{grid-template-columns:1fr}}
        .sol-card{background:#fff;border:1.5px solid var(--border);border-radius:18px;padding:28px;transition:all .25s}
        .sol-card:hover{border-color:var(--purple);box-shadow:0 8px 28px rgba(157,0,255,.1);transform:translateY(-4px)}
        .sol-title{font-size:18px;font-weight:700;margin-bottom:10px;color:var(--text)}
        .sol-desc{font-size:14px;color:var(--text2);line-height:1.65}
        .sol-check{margin-top:18px;display:flex;flex-direction:column;gap:7px}
        .sol-check-item{font-size:13px;color:var(--text2);display:flex;gap:8px;align-items:flex-start}
        .sol-check-item .ck{color:var(--purple);font-weight:700;flex-shrink:0;font-size:15px}
        .sol-tag{display:inline-flex;align-items:center;margin-top:18px;font-size:12px;
            font-weight:700;padding:5px 12px;border-radius:20px;background:var(--purple-light);color:var(--purple)}

        /* ── WHY GRID ── */
        .why-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:1px;margin-top:48px;
            background:var(--border);border:1px solid var(--border);border-radius:16px;overflow:hidden}
        @media(max-width:700px){.why-grid{grid-template-columns:1fr 1fr}}
        .why-item{background:#fff;padding:28px 24px;transition:background .18s;color:var(--purple)}
        .why-item:hover{background:var(--purple-light)}
        .why-icon-wrap{width:44px;height:44px;background:var(--purple-light);border-radius:10px;
            display:flex;align-items:center;justify-content:center;margin-bottom:14px}
        .why-title{font-size:15px;font-weight:700;margin-bottom:6px;color:var(--text)}
        .why-desc{font-size:13px;color:var(--text2);line-height:1.6}

        /* ── STEPS ── */
        .steps-grid{display:grid;grid-template-columns:repeat(5,1fr);gap:0;margin-top:48px}
        @media(max-width:900px){.steps-grid{grid-template-columns:repeat(3,1fr)}}
        @media(max-width:600px){.steps-grid{grid-template-columns:1fr 1fr}}
        .step{padding:28px 16px;text-align:center;position:relative}
        .step-num{width:42px;height:42px;border-radius:50%;background:var(--purple-light);
            border:2px solid rgba(157,0,255,.25);display:flex;align-items:center;
            justify-content:center;margin:0 auto 16px;font-size:15px;font-weight:800;color:var(--purple)}
        .step-title{font-size:15px;font-weight:700;margin-bottom:6px;color:var(--text)}
        .step-desc{font-size:13px;color:var(--text2);line-height:1.5}
        .step-conn{position:absolute;top:49px;right:0;width:50%;height:2px;
            background:linear-gradient(90deg,transparent,rgba(157,0,255,.2))}

        /* ── B2B SECTION ── */
        .b2b-section{background:var(--bg)}
        .b2b-inner{max-width:1140px;margin:0 auto;padding:88px 24px;
            display:grid;grid-template-columns:1fr 1fr;gap:60px;align-items:center}
        @media(max-width:900px){.b2b-inner{grid-template-columns:1fr}}
        .b2b-feat{display:flex;gap:14px;margin-bottom:22px}
        .b2b-feat-ico{width:40px;height:40px;border-radius:10px;flex-shrink:0;
            background:var(--purple-light);display:flex;align-items:center;
            justify-content:center;color:var(--purple)}
        .b2b-feat-title{font-size:15px;font-weight:700;margin-bottom:3px;color:var(--text)}
        .b2b-feat-desc{font-size:13px;color:var(--text2);line-height:1.55}
        .b2b-card{background:#fff;border:1.5px solid var(--border);border-radius:20px;
            padding:28px;box-shadow:0 4px 24px rgba(0,0,0,.06)}
        .route-item{display:flex;gap:14px;align-items:flex-start;
            padding:10px 0;border-bottom:1px solid var(--border)}
        .route-item:last-child{border-bottom:none}
        .route-dot{width:12px;height:12px;border-radius:50%;margin-top:3px;flex-shrink:0}
        .route-name{font-size:14px;font-weight:600;color:var(--text)}
        .route-meta{font-size:12px;color:var(--text3);margin-top:1px}

        /* ── CTA ── */
        .cta-section{padding:100px 24px;text-align:center;background:#fff}
        .cta-inner{max-width:660px;margin:0 auto}
        .cta-h2{font-size:clamp(28px,4vw,52px);font-weight:900;letter-spacing:-1.5px;
            line-height:1.1;margin-bottom:14px;color:var(--text)}
        .cta-p{font-size:17px;color:var(--text2);margin-bottom:40px}
        .cta-btns{display:flex;gap:14px;justify-content:center;flex-wrap:wrap}

        /* ── FOOTER ── */
        .footer{border-top:1px solid var(--border);padding:36px 48px 28px;
            display:flex;align-items:center;justify-content:space-between;
            flex-wrap:wrap;gap:20px;background:#fff}
        .footer-copy{font-size:13px;color:var(--text3)}
        .footer-links{display:flex;gap:22px}
        .footer-links a{font-size:13px;color:var(--text3);transition:color .18s}
        .footer-links a:hover{color:var(--purple)}

        /* ── FADE IN ── */
        .fade-in{opacity:0;transform:translateY(24px);transition:opacity .55s ease,transform .55s ease}
        .fade-in.visible{opacity:1;transform:translateY(0)}
    </style>
</head>
<body>

<!-- NAV -->
<nav class="nav" id="mainNav">
    <div class="logo" onclick="window.scrollTo({top:0,behavior:'smooth'})">
        <img src="<%= request.getContextPath() %>/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" class="logo-img">
    </div>
    <div class="nav-links">
        <a href="#soluciones" class="nav-link">Soluciones</a>
        <a href="#empresas" class="nav-link">Empresas</a>
        <a href="#como" class="nav-link">Cómo funciona</a>
    </div>
    <div class="nav-ctas">
        <a href="<%= request.getContextPath() %>/login" class="btn-ghost-nav">Iniciar sesión</a>
        <a href="<%= request.getContextPath() %>/registro" class="btn-primary-nav">Registrarse</a>
    </div>
</nav>

<!-- HERO -->
<section class="hero">
    <div class="hero-bg-circle"></div>
    <div class="hero-inner">
        <div class="hero-pill">
            <span class="hero-pill-tag">Nuevo</span>
            Módulo B2B disponible para empresas en CDMX
        </div>
        <h1 class="hero-h1">
            Shuttles corporativos<br>para <em>potenciar el transporte</em><br>de tus colaboradores
        </h1>
        <p class="hero-p">
            Nuestra plataforma optimiza rutas y permite cambios en tiempo real, garantizando
            eficiencia y reducción de costos mientras ofrece a tus colaboradores
            un transporte confiable que mejora su satisfacción laboral.
        </p>
        <div class="hero-btns">
            <a href="<%= request.getContextPath() %>/registro" class="btn-hero-primary">Solicitar acceso</a>
            <a href="#soluciones" class="btn-hero-outline">Ver soluciones</a>
        </div>
        <div class="stats-strip">
            <div class="stat-item"><div class="stat-num"><span>+</span>120</div><div class="stat-label">Empresas</div></div>
            <div class="stat-item"><div class="stat-num"><span>+</span>1.5M</div><div class="stat-label">Viajes realizados</div></div>
            <div class="stat-item"><div class="stat-num"><span>+</span>10M</div><div class="stat-label">Pasajeros</div></div>
            <div class="stat-item"><div class="stat-num"><span>+</span>40</div><div class="stat-label">Ciudades</div></div>
        </div>
    </div>
</section>

<!-- TICKER -->
<div class="ticker-wrap">
    <div class="ticker-fade-l">Confían en nosotros</div>
    <div class="ticker-fade-r"></div>
    <div class="ticker-track">
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/disney.svg" alt="Disney" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/ups.svg" alt="UPS" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/pfizer.svg" alt="Pfizer" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/heineken.svg" alt="Heineken" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/danone.svg" alt="Danone" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/huawei.svg" alt="Huawei" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/pepsico.svg" alt="PepsiCo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/samsung.svg" alt="Samsung" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/jose-cuervo.svg" alt="José Cuervo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/comex.svg" alt="Comex" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/sony.svg" alt="Sony" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/electrolux.svg" alt="Electrolux" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/prudential.svg" alt="Prudential" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/aliat.svg" alt="Aliat" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/caf.svg" alt="CAF" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/crediclub.svg" alt="CrediClub" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/elektra.svg" alt="Elektra" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/farmacias-ahorro.svg" alt="Farmacias Ahorro" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/indorama.svg" alt="Indorama" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/justo.svg" alt="Justo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/mizco.svg" alt="Mizco" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/nadro.svg" alt="NADRO" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/softys.svg" alt="Softys" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/tangelo.svg" alt="Tangelo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/uvm.svg" alt="UVM" class="ticker-logo"></span>
        <%-- Duplicado para bucle infinito --%>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/disney.svg" alt="Disney" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/ups.svg" alt="UPS" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/pfizer.svg" alt="Pfizer" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/heineken.svg" alt="Heineken" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/danone.svg" alt="Danone" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/huawei.svg" alt="Huawei" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/pepsico.svg" alt="PepsiCo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/samsung.svg" alt="Samsung" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/jose-cuervo.svg" alt="José Cuervo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/comex.svg" alt="Comex" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/sony.svg" alt="Sony" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/electrolux.svg" alt="Electrolux" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/prudential.svg" alt="Prudential" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/aliat.svg" alt="Aliat" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/caf.svg" alt="CAF" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/crediclub.svg" alt="CrediClub" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/elektra.svg" alt="Elektra" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/farmacias-ahorro.svg" alt="Farmacias Ahorro" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/indorama.svg" alt="Indorama" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/justo.svg" alt="Justo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/mizco.svg" alt="Mizco" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/nadro.svg" alt="NADRO" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/softys.svg" alt="Softys" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/tangelo.svg" alt="Tangelo" class="ticker-logo"></span>
        <span class="ticker-co"><img src="<%= request.getContextPath() %>/assets/img/uvm.svg" alt="UVM" class="ticker-logo"></span>
    </div>
</div>

<!-- SOLUCIONES -->
<section class="section" id="soluciones">
    <div class="section-inner">
        <div class="section-center">
            <span class="section-tag">Soluciones de transporte</span>
            <h2 class="section-h2 fade-in">Un ecosistema de movilidad<br>para cada necesidad</h2>
            <p class="section-p fade-in" style="margin:0 auto">
                Desde traslados individuales dentro de la ciudad hasta shuttles corporativos
                con flota de autobuses de alta capacidad.
            </p>
        </div>
        <div class="sol-grid">
            <div class="sol-card fade-in">
                <div class="icon-wrap"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M5 11l1.5-5h11L19 11m-14 0h14m-14 0v6a1 1 0 001 1h1m11-7v6a1 1 0 01-1 1h-1m-11 0a2 2 0 104 0m8 0a2 2 0 104 0"/></svg></div>
                <div class="sol-title">Intracity</div>
                <div class="sol-desc">Viaja de forma segura dentro de la ciudad. Operador asignado automáticamente según tu ubicación.</div>
                <div class="sol-check">
                    <div class="sol-check-item"><span class="ck">+</span> Asignación automática en tiempo real</div>
                    <div class="sol-check-item"><span class="ck">+</span> Rastreo GPS del operador</div>
                    <div class="sol-check-item"><span class="ck">+</span> Pago en efectivo o tarjeta</div>
                </div>
                <span class="sol-tag">Para pasajeros</span>
            </div>
            <div class="sol-card fade-in">
                <div class="icon-wrap"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="16" rx="1"/><path d="M9 21V12h6v9"/><path d="M7 9h.01M7 13h.01M17 9h.01M17 13h.01M12 9h.01M12 13h.01"/></svg></div>
                <div class="sol-title">Corporativo</div>
                <div class="sol-desc">Eleva los beneficios de transporte para tus colaboradores. Rutas personalizadas con flota de autobuses.</div>
                <div class="sol-check">
                    <div class="sol-check-item"><span class="ck">+</span> Hasta 66 pasajeros por unidad</div>
                    <div class="sol-check-item"><span class="ck">+</span> Asignación visual de asientos</div>
                    <div class="sol-check-item"><span class="ck">+</span> Panel de control empresarial</div>
                </div>
                <span class="sol-tag">Para empresas</span>
            </div>
            <div class="sol-card fade-in">
                <div class="icon-wrap"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><polyline points="9 12 11 14 15 10"/></svg></div>
                <div class="sol-title">Operadores verificados</div>
                <div class="sol-desc">Sé parte de nuestra red de socios conductores. Recibe viajes y rutas corporativas y mantén tu score.</div>
                <div class="sol-check">
                    <div class="sol-check-item"><span class="ck">+</span> Score unificado B2C y B2B</div>
                    <div class="sol-check-item"><span class="ck">+</span> Panel propio de control</div>
                    <div class="sol-check-item"><span class="ck">+</span> Historial completo de servicios</div>
                </div>
                <span class="sol-tag">Para operadores</span>
            </div>
        </div>
    </div>
</section>

<!-- POR QUÉ URBVAN -->
<section class="section section-alt">
    <div class="section-inner">
        <div class="section-center">
            <span class="section-tag">Por qué elegirnos</span>
            <h2 class="section-h2 fade-in">La mejor opción<br>para tu empresa</h2>
        </div>
        <div class="why-grid fade-in">
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div>
                <div class="why-title">Implementación rápida</div>
                <div class="why-desc">Optimizamos rutas en tiempo real para garantizar la puntualidad de tus empleados desde el primer día.</div>
            </div>
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 18 13.5 8.5 8.5 13.5 1 6"/><polyline points="17 18 23 18 23 12"/></svg></div>
                <div class="why-title">Reducción de costos</div>
                <div class="why-desc">Optimiza recursos, reduce costos operativos y mejora la eficiencia en la movilidad de tu personal.</div>
            </div>
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg></div>
                <div class="why-title">Plataforma inteligente</div>
                <div class="why-desc">Ágil e intuitiva para gestionar rutas y servicios en tiempo real desde cualquier dispositivo.</div>
            </div>
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg></div>
                <div class="why-title">Seguridad y protección</div>
                <div class="why-desc">Rastreo GPS en tiempo real, operadores verificados y procesos de control de calidad.</div>
            </div>
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg></div>
                <div class="why-title">Atención al cliente</div>
                <div class="why-desc">Sistema de notificaciones en plataforma para consultas y cambios en tiempo real.</div>
            </div>
            <div class="why-item">
                <div class="why-icon-wrap"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/></svg></div>
                <div class="why-title">Flexibilidad</div>
                <div class="why-desc">Cancela, modifica o asigna asientos hasta 24 horas antes del servicio.</div>
            </div>
        </div>
    </div>
</section>

<!-- CÓMO FUNCIONA -->
<section class="section" id="como">
    <div class="section-inner">
        <div class="section-center">
            <span class="section-tag">Cómo creamos la solución perfecta</span>
            <h2 class="section-h2 fade-in">De la solicitud<br>al primer viaje</h2>
        </div>
        <div class="steps-grid fade-in">
            <div class="step"><div class="step-conn"></div><div class="step-num">1</div><div class="step-title">Diseño</div><div class="step-desc">Identificamos rutas óptimas para tus empleados usando el mapa interactivo.</div></div>
            <div class="step"><div class="step-conn"></div><div class="step-num">2</div><div class="step-title">Asignación</div><div class="step-desc">El sistema asigna vehículo y operador disponible según el modelo requerido.</div></div>
            <div class="step"><div class="step-conn"></div><div class="step-num">3</div><div class="step-title">Lanzamiento</div><div class="step-desc">Asignas los asientos a cada empleado. Todos reciben notificación con horarios.</div></div>
            <div class="step"><div class="step-conn"></div><div class="step-num">4</div><div class="step-title">Operación</div><div class="step-desc">El operador ejecuta la ruta. Los empleados ven información en tiempo real.</div></div>
            <div class="step"><div class="step-num">5</div><div class="step-title">Evaluación</div><div class="step-desc">Empleados y operador se califican mutuamente. El score corporativo se actualiza.</div></div>
        </div>
    </div>
</section>

<!-- B2B -->
<div class="b2b-section" id="empresas">
    <div class="b2b-inner">
        <div>
            <span class="section-tag">Módulo Corporativo</span>
            <h2 class="section-h2 fade-in">Movilidad empresarial<br>sin complicaciones</h2>
            <p class="section-p fade-in" style="margin-bottom:28px">
                Gestiona el transporte de tus empleados desde un panel centralizado.
                Flota de autobuses de alta capacidad con trazabilidad completa.
            </p>
            <div class="b2b-feat fade-in">
                <div class="b2b-feat-ico"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="1 6 1 22 8 18 16 22 23 18 23 2 16 6 8 2 1 6"/><line x1="8" y1="2" x2="8" y2="18"/><line x1="16" y1="6" x2="16" y2="22"/></svg></div>
                <div><div class="b2b-feat-title">Rutas con múltiples paradas</div><div class="b2b-feat-desc">Define origen, hasta 6 paradas intermedias y destino en el mapa. El sistema calcula costo y horario automáticamente.</div></div>
            </div>
            <div class="b2b-feat fade-in">
                <div class="b2b-feat-ico"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg></div>
                <div><div class="b2b-feat-title">Gestión visual de asientos</div><div class="b2b-feat-desc">Asigna a cada empleado su asiento en el plano del autobús antes de que salga la ruta.</div></div>
            </div>
            <div class="b2b-feat fade-in">
                <div class="b2b-feat-ico"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></div>
                <div><div class="b2b-feat-title">Score corporativo en tiempo real</div><div class="b2b-feat-desc">Tu empresa mantiene un score de reputación basado en calificaciones y puntualidad.</div></div>
            </div>
            <div class="b2b-feat fade-in">
                <div class="b2b-feat-ico"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg></div>
                <div><div class="b2b-feat-title">Notificaciones automáticas</div><div class="b2b-feat-desc">Empleados reciben avisos de asignación, cambios de ruta y cancelaciones en la plataforma.</div></div>
            </div>
            <a href="<%= request.getContextPath() %>/login" class="btn-hero-primary fade-in" style="display:inline-block;margin-top:8px;font-size:15px">Solicitar acceso corporativo</a>
        </div>
        <div class="b2b-card fade-in">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
                <div>
                    <div style="font-size:11px;color:var(--text3);font-weight:700;letter-spacing:1px;text-transform:uppercase;margin-bottom:2px">Score corporativo</div>
                    <div style="font-size:38px;font-weight:900;color:var(--purple);line-height:1">94 <span style="font-size:14px;color:var(--text2);font-weight:400">/ 100</span></div>
                </div>
                <span style="padding:4px 14px;background:var(--purple-light);color:var(--purple);border-radius:20px;font-size:12px;font-weight:700">Excelente</span>
            </div>
            <div style="font-size:11px;font-weight:700;color:var(--text3);text-transform:uppercase;letter-spacing:1.5px;margin-bottom:10px">Ruta activa hoy</div>
            <div class="route-item"><div class="route-dot" style="background:#10b981;margin-top:4px"></div><div><div class="route-name">Corporativo Insurgentes Norte</div><div class="route-meta">07:30 - Origen</div></div></div>
            <div class="route-item"><div class="route-dot" style="background:#9D00FF;margin-top:4px"></div><div><div class="route-name">Metro Indios Verdes</div><div class="route-meta">07:55 - 5 min estancia</div></div></div>
            <div class="route-item"><div class="route-dot" style="background:#9D00FF;margin-top:4px"></div><div><div class="route-name">Toreo de Cuatro Caminos</div><div class="route-meta">08:20 - 5 min estancia</div></div></div>
            <div class="route-item" style="border:none"><div class="route-dot" style="background:#ef4444;margin-top:4px"></div><div><div class="route-name">Paseo de la Reforma 505</div><div class="route-meta">09:00 - Destino</div></div></div>
            <div style="display:flex;justify-content:space-between;align-items:center;margin-top:16px;padding-top:16px;border-top:1px solid var(--border)">
                <div style="font-size:13px;color:var(--text2)">Irizar i8 - 44/47 asientos</div>
                <div style="font-size:16px;font-weight:800;color:var(--purple)">$4,280 MXN</div>
            </div>
        </div>
    </div>
</div>

<!-- CTA FINAL -->
<section class="cta-section">
    <div class="cta-inner">
        <span class="section-tag">Empieza hoy</span>
        <h2 class="cta-h2 fade-in">¿Listo para mover<br>a tu equipo con Urbvan?</h2>
        <p class="cta-p fade-in">Únete a las más de 120 empresas que ya confían en nosotros para la movilidad de sus colaboradores.</p>
        <div class="cta-btns">
            <a href="<%= request.getContextPath() %>/registro" class="btn-hero-primary">Crear cuenta gratis</a>
            <a href="<%= request.getContextPath() %>/login" class="btn-hero-outline">Ya tengo cuenta</a>
        </div>
    </div>
</section>

<!-- FOOTER -->
<footer class="footer">
    <div style="display:flex;align-items:center;gap:12px">
        <img src="<%= request.getContextPath() %>/assets/img/Logo_UrbvanPasajero.png" alt="Urbvan" style="height:36px;width:auto;object-fit:contain">
        <span class="footer-copy">© 2026 BioniX - CECyT 9 "Juan de Dios Bátiz"</span>
    </div>
    <div class="footer-links">
        <a href="#soluciones">Soluciones</a>
        <a href="#empresas">Empresas</a>
        <a href="#como">Cómo funciona</a>
        <a href="<%= request.getContextPath() %>/login">Iniciar sesión</a>
        <a href="<%= request.getContextPath() %>/registro">Registrarse</a>
    </div>
</footer>

<script>
var nav = document.getElementById('mainNav');
window.addEventListener('scroll', function() { nav.classList.toggle('scrolled', window.scrollY > 40); });
var obs = new IntersectionObserver(function(entries) {
    entries.forEach(function(e) { if(e.isIntersecting) e.target.classList.add('visible'); });
}, {threshold:0.08, rootMargin:'0px 0px -40px 0px'});
document.querySelectorAll('.fade-in').forEach(function(el) { obs.observe(el); });
document.querySelectorAll('a[href^="#"]').forEach(function(a) {
    a.addEventListener('click', function(e) {
        var t = document.querySelector(this.getAttribute('href'));
        if(t){ e.preventDefault(); t.scrollIntoView({behavior:'smooth',block:'start'}); }
    });
});
</script>
</body>
</html>