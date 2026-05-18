-- ============================================================
--  URBVAN — Script de creación de base de datos
--  Proyecto de titulación | Equipo BioniX
--  Stack: MySQL 8.x
--  Versión: 1.0 | Mayo 2026
-- ============================================================

CREATE DATABASE IF NOT EXISTS urbvan CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE urbvan;

-- ------------------------------------------------------------
-- 1. ADMINISTRADORES
-- ------------------------------------------------------------
CREATE TABLE administradores (
    id_admin        INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100)  NOT NULL,
    correo          VARCHAR(150)  NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255)  NOT NULL,
    fecha_registro  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. USUARIOS (pasajeros)
-- ------------------------------------------------------------
CREATE TABLE usuarios (
    id_usuario      INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(100)  NOT NULL,
    apellido        VARCHAR(100)  NOT NULL,
    correo          VARCHAR(150)  NOT NULL UNIQUE,
    contrasena_hash VARCHAR(255)  NOT NULL,
    telefono        VARCHAR(20),
    activo          TINYINT(1)    NOT NULL DEFAULT 1,
    fecha_registro  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. VEHÍCULOS
-- ------------------------------------------------------------
CREATE TABLE vehiculos (
    id_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
    placa       VARCHAR(15)  NOT NULL UNIQUE,
    marca       VARCHAR(60)  NOT NULL,
    modelo      VARCHAR(60)  NOT NULL,
    anio        YEAR         NOT NULL,
    color       VARCHAR(40),
    capacidad   TINYINT      NOT NULL DEFAULT 4,
    activo      TINYINT(1)   NOT NULL DEFAULT 1
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. OPERADORES (conductores)
-- ------------------------------------------------------------
CREATE TABLE operadores (
    id_operador       INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(100)  NOT NULL,
    apellido          VARCHAR(100)  NOT NULL,
    correo            VARCHAR(150)  NOT NULL UNIQUE,
    contrasena_hash   VARCHAR(255)  NOT NULL,
    telefono          VARCHAR(20),
    id_vehiculo       INT,
    disponible        TINYINT(1)    NOT NULL DEFAULT 0,
    calificacion_prom DECIMAL(3,2)  NOT NULL DEFAULT 5.00,
    activo            TINYINT(1)    NOT NULL DEFAULT 1,
    fecha_registro    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_op_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculos(id_vehiculo)
        ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX idx_op_disponible (disponible)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 5. POSICIÓN EN TIEMPO REAL (para el polling)
--    Un registro por operador — se actualiza con UPSERT.
-- ------------------------------------------------------------
CREATE TABLE posicion_operador (
    id_operador          INT          NOT NULL PRIMARY KEY,
    latitud              DECIMAL(10,7) NOT NULL,
    longitud             DECIMAL(10,7) NOT NULL,
    ultima_actualizacion DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pos_operador FOREIGN KEY (id_operador) REFERENCES operadores(id_operador)
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 6. TARIFAS
-- ------------------------------------------------------------
CREATE TABLE tarifas (
    id_tarifa      INT AUTO_INCREMENT PRIMARY KEY,
    tarifa_base    DECIMAL(8,2) NOT NULL COMMENT 'Costo fijo al iniciar el viaje (MXN)',
    costo_por_km   DECIMAL(8,2) NOT NULL COMMENT 'Costo adicional por kilómetro (MXN)',
    cargo_servicio DECIMAL(8,2) NOT NULL DEFAULT 0.00 COMMENT 'Cargo fijo de plataforma (MXN)',
    activa         TINYINT(1)   NOT NULL DEFAULT 1,
    fecha_vigencia DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 7. VIAJES  — tabla central del sistema
-- ------------------------------------------------------------
CREATE TABLE viajes (
    id_viaje           INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario         INT          NOT NULL,
    id_operador        INT,
    origen_lat         DECIMAL(10,7) NOT NULL,
    origen_lng         DECIMAL(10,7) NOT NULL,
    origen_direccion   VARCHAR(255),
    destino_lat        DECIMAL(10,7) NOT NULL,
    destino_lng        DECIMAL(10,7) NOT NULL,
    destino_direccion  VARCHAR(255),
    distancia_km       DECIMAL(8,3),
    precio_total       DECIMAL(10,2),
    estado             ENUM(
                         'SOLICITADO',
                         'EN_ASIGNACION',
                         'ACEPTADO',
                         'OPERADOR_EN_CAMINO',
                         'VIAJE_INICIADO',
                         'COMPLETADO',
                         'CANCELADO'
                       ) NOT NULL DEFAULT 'SOLICITADO',
    eta_operador_min   INT COMMENT 'ETA en minutos del operador al origen',
    eta_viaje_min      INT COMMENT 'ETA en minutos del origen al destino',
    fecha_solicitud    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_aceptacion   DATETIME,
    fecha_inicio       DATETIME,
    fecha_fin          DATETIME,
    CONSTRAINT fk_viaje_usuario  FOREIGN KEY (id_usuario)  REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_viaje_operador FOREIGN KEY (id_operador) REFERENCES operadores(id_operador)
        ON DELETE SET NULL,
    INDEX idx_viaje_estado    (estado),
    INDEX idx_viaje_usuario   (id_usuario),
    INDEX idx_viaje_operador  (id_operador)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 8. SOLICITUDES DE ASIGNACIÓN (cascada operador)
-- ------------------------------------------------------------
CREATE TABLE solicitudes_asignacion (
    id_solicitud   INT AUTO_INCREMENT PRIMARY KEY,
    id_viaje       INT      NOT NULL,
    id_operador    INT      NOT NULL,
    numero_intento TINYINT  NOT NULL DEFAULT 1 COMMENT '1 al 5 máximo',
    estado         ENUM('PENDIENTE','ACEPTADA','RECHAZADA','EXPIRADA')
                            NOT NULL DEFAULT 'PENDIENTE',
    fecha_envio    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_respuesta DATETIME,
    CONSTRAINT fk_sol_viaje    FOREIGN KEY (id_viaje)    REFERENCES viajes(id_viaje),
    CONSTRAINT fk_sol_operador FOREIGN KEY (id_operador) REFERENCES operadores(id_operador)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 9. PAGOS (simulados)
-- ------------------------------------------------------------
CREATE TABLE pagos (
    id_pago        INT AUTO_INCREMENT PRIMARY KEY,
    id_viaje       INT          NOT NULL UNIQUE,
    metodo_pago    ENUM('TARJETA','EFECTIVO') NOT NULL DEFAULT 'TARJETA',
    monto          DECIMAL(10,2) NOT NULL,
    estado_pago    ENUM('PENDIENTE','APROBADO','CANCELADO') NOT NULL DEFAULT 'PENDIENTE',
    referencia_sim VARCHAR(40)  COMMENT 'UUID simulado de transacción',
    fecha_pago     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pago_viaje FOREIGN KEY (id_viaje) REFERENCES viajes(id_viaje)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 10. CALIFICACIONES
-- ------------------------------------------------------------
CREATE TABLE calificaciones (
    id_calificacion    INT AUTO_INCREMENT PRIMARY KEY,
    id_viaje           INT     NOT NULL UNIQUE,
    id_operador        INT     NOT NULL,
    puntuacion         TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario         TEXT,
    fecha_calificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cal_viaje    FOREIGN KEY (id_viaje)    REFERENCES viajes(id_viaje),
    CONSTRAINT fk_cal_operador FOREIGN KEY (id_operador) REFERENCES operadores(id_operador)
) ENGINE=InnoDB;

-- ============================================================
-- DATOS INICIALES
-- ============================================================

-- Tarifa base inicial (configurable desde el panel admin)
INSERT INTO tarifas (tarifa_base, costo_por_km, cargo_servicio) VALUES (15.00, 8.50, 3.00);

-- Administrador inicial (contraseña: Admin2026! — cambiar en producción)
-- Hash SHA-256 de "Admin2026!"
INSERT INTO administradores (nombre, correo, contrasena_hash)
VALUES ('Admin Urbvan', 'admin@urbvan.mx', SHA2('Admin2026!', 256));

-- ============================================================
-- VISTAS ÚTILES
-- ============================================================

-- Vista: viajes activos con información completa
CREATE OR REPLACE VIEW v_viajes_activos AS
SELECT
    v.id_viaje,
    CONCAT(u.nombre, ' ', u.apellido) AS pasajero,
    u.telefono                         AS tel_pasajero,
    CONCAT(o.nombre, ' ', o.apellido) AS operador,
    veh.placa,
    CONCAT(veh.marca, ' ', veh.modelo) AS vehiculo,
    v.origen_direccion,
    v.destino_direccion,
    v.precio_total,
    v.estado,
    v.fecha_solicitud,
    v.eta_operador_min,
    v.eta_viaje_min,
    p.latitud  AS op_lat,
    p.longitud AS op_lng
FROM viajes v
JOIN usuarios   u   ON u.id_usuario  = v.id_usuario
LEFT JOIN operadores o   ON o.id_operador = v.id_operador
LEFT JOIN vehiculos  veh ON veh.id_vehiculo = o.id_vehiculo
LEFT JOIN posicion_operador p ON p.id_operador = o.id_operador
WHERE v.estado NOT IN ('COMPLETADO', 'CANCELADO');

-- Vista: resumen de operadores para el dashboard
CREATE OR REPLACE VIEW v_resumen_operadores AS
SELECT
    o.id_operador,
    CONCAT(o.nombre, ' ', o.apellido) AS nombre_completo,
    o.disponible,
    o.calificacion_prom,
    CONCAT(veh.marca, ' ', veh.modelo, ' (', veh.placa, ')') AS vehiculo,
    COUNT(v.id_viaje)  AS total_viajes,
    p.latitud, p.longitud
FROM operadores o
LEFT JOIN vehiculos         veh ON veh.id_vehiculo = o.id_vehiculo
LEFT JOIN viajes            v   ON v.id_operador   = o.id_operador AND v.estado = 'COMPLETADO'
LEFT JOIN posicion_operador p   ON p.id_operador   = o.id_operador
WHERE o.activo = 1
GROUP BY o.id_operador, o.nombre, o.apellido, o.disponible,
         o.calificacion_prom, veh.marca, veh.modelo, veh.placa, p.latitud, p.longitud;
