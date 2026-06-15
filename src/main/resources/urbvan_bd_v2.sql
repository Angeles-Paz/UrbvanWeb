-- ==============================================================================
--  URBVAN v2 - Schema Unificado B2C + B2B
--  Equipo BioniX | CECyT 9 "Juan de Dios Bátiz"
--  MySQL 8.0  |  Tomcat 10.1  |  Java 17  |  Junio 2026
-- ==============================================================================
--
--  JDBC URL (db.properties):
--  jdbc:mysql://localhost:3306/urbvan
--    ?useSSL=false
--    &serverTimezone=America/Mexico_City
--    &characterEncoding=UTF-8
--    &useUnicode=true
--
--  INSTRUCCIONES:
--    1. Ejecutar este script COMPLETO en MySQL como root
--    2. No modificar el orden de los bloques (dependencias de FK)
--    3. Las secciones marcadas con ⚙ son configurables sin tocar código Java
-- ==============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SETUP
-- ─────────────────────────────────────────────────────────────────────────────

DROP DATABASE IF EXISTS urbvan;
CREATE DATABASE urbvan
    CHARACTER SET utf8mb4
    COLLATE      utf8mb4_unicode_ci;

USE urbvan;

SET FOREIGN_KEY_CHECKS = 0;


-- ==============================================================================
-- BLOQUE 1 - USUARIOS (rol unificado B2C + B2B)
-- ==============================================================================

CREATE TABLE usuarios (
    id                   INT            PRIMARY KEY AUTO_INCREMENT,
    nombre               VARCHAR(100)   NOT NULL,
    apellido             VARCHAR(100)   NULL,
    telefono             VARCHAR(30)    NULL,
    email                VARCHAR(150)   NOT NULL,
    contrasena           VARCHAR(64)    NOT NULL   COMMENT 'SHA-256 hex (64 chars)',
    rol                  ENUM(
                             'pasajero',
                             'operador',
                             'admin',
                             'admin_empresa'
                         ) NOT NULL DEFAULT 'pasajero',
    activo               BOOLEAN        NOT NULL DEFAULT TRUE,

    -- Posición en tiempo real (solo operadores la actualizan vía ActualizarPosicionServlet)
    lat                  DECIMAL(10,8)            COMMENT 'Latitud actual del operador',
    lng                  DECIMAL(11,8)            COMMENT 'Longitud actual del operador',

    -- Score compartido B2C + B2B (actualizado por SP tras cada calificación)
    calificacion_promedio DECIMAL(5,2)  NOT NULL DEFAULT 100.00
                              COMMENT '0-100 | Escala: Problemático/Malo/Regular/Bueno/Excelente',

    -- Solo para admin_empresa: aviso de cambio de contraseña en primer login (no forzado)
    primer_login         BOOLEAN        NOT NULL DEFAULT FALSE,

    created_at           TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_email (email),
    INDEX idx_usuarios_rol_activo (rol, activo),
    INDEX idx_usuarios_posicion   (lat, lng)   COMMENT 'Para búsqueda por proximidad en AsignadorOperador'
) ENGINE=InnoDB
  COMMENT='Todos los usuarios del sistema. El rol B2B (empleado) se gestiona en empresa_usuarios.';


-- ==============================================================================
-- BLOQUE 2 - FLOTA DE VEHÍCULOS
-- ==============================================================================

CREATE TABLE vehiculos (
    id          INT  PRIMARY KEY AUTO_INCREMENT,
    modelo      ENUM(
                    -- B2C (transporte individual)
                    'Sedan',
                    'SUV',
                    'Minivan',
                    -- B2B (transporte corporativo - buses)
                    'Irizar_i8',
                    'Busstar_DD',
                    'Marcopolo_G7',
                    'Volvo_9800',
                    'Irizar_i6',
                    'Torino'
                ) NOT NULL,
    capacidad   INT            NOT NULL COMMENT 'Máximo de pasajeros',
    placa       VARCHAR(20)    NOT NULL,
    color       VARCHAR(50),
    operador_id INT                     COMMENT 'NULL = vehículo sin operador asignado',
    categoria   ENUM('b2c','b2b')  NOT NULL DEFAULT 'b2c'
                    COMMENT 'b2c = uso en viajes individuales | b2b = uso en rutas corporativas',
    activo      BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_placa       (placa),
    FOREIGN KEY fk_veh_op (operador_id) REFERENCES usuarios(id) ON DELETE SET NULL,
    INDEX idx_vehiculos_categoria_activo (categoria, activo),
    INDEX idx_vehiculos_modelo           (modelo)
) ENGINE=InnoDB
  COMMENT='Flota unificada B2C y B2B. categoria distingue el tipo de servicio.';


-- ==============================================================================
-- BLOQUE 3 - CONFIGURACIÓN DEL SISTEMA ⚙
-- ==============================================================================

CREATE TABLE configuracion (
    clave       VARCHAR(60)    PRIMARY KEY,
    valor       VARCHAR(255)   NOT NULL,
    descripcion VARCHAR(300),
    updated_at  TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB
  COMMENT='Parámetros globales editables sin recompilar. Leer en tiempo de ejecución.';

INSERT INTO configuracion (clave, valor, descripcion) VALUES
-- B2C pricing
('b2c_costo_base',        '35.00',  'MXN - tarifa base fija por viaje B2C'),
('b2c_costo_por_km',      '12.00',  'MXN - cargo adicional por kilómetro B2C'),
('b2c_radio_busqueda_km', '10',     'Radio máximo (km) para buscar operadores disponibles'),
('b2c_max_operadores',    '5',      'Máximo de operadores a intentar en cascada'),
-- Sistema
('penalizacion_cancelacion_tardia', '10.00',
 'Puntos descontados del score empresa por cancelar B2B con < 24h'),
('version_sistema',       '2.0',    'Versión actual del sistema Urbvan');


-- ==============================================================================
-- BLOQUE 4 - VIAJES B2C
-- ==============================================================================

CREATE TABLE viajes (
    id               INT           PRIMARY KEY AUTO_INCREMENT,
    pasajero_id      INT           NOT NULL,
    operador_id      INT                       COMMENT 'NULL hasta que un operador acepta',
    vehiculo_id      INT                       COMMENT 'NULL hasta asignación',

    -- Origen
    origen_lat       DECIMAL(10,8) NOT NULL,
    origen_lng       DECIMAL(11,8) NOT NULL,
    origen_nombre    VARCHAR(255)              COMMENT 'Geocodificado por Azure Maps',

    -- Destino
    destino_lat      DECIMAL(10,8) NOT NULL,
    destino_lng      DECIMAL(11,8) NOT NULL,
    destino_nombre   VARCHAR(255)              COMMENT 'Geocodificado por Azure Maps',

    -- Cálculos de Azure Maps (se llenan al confirmar el viaje)
    distancia_km     DECIMAL(8,2),
    duracion_min     INT,
    costo            DECIMAL(10,2)             COMMENT 'b2c_costo_base + (km * b2c_costo_por_km)',

    -- Ciclo de vida
    estado           ENUM(
                         'solicitado',    -- pasajero pidió el viaje
                         'asignado',      -- sistema asignó operador, esperando aceptación
                         'aceptado',      -- operador aceptó, va en camino al origen
                         'en_camino',     -- operador recogió al pasajero, viaje en curso
                         'en_curso',      -- compatibilidad con v1: viaje en desarrollo
                         'completado',    -- llegaron al destino
                         'cancelado'      -- cancelado por pasajero u operador
                     ) NOT NULL DEFAULT 'solicitado',

    metodo_pago      ENUM('efectivo','tarjeta') NOT NULL DEFAULT 'efectivo'
                         COMMENT 'Simulado - sin pasarela de pago real',
    cancelado_por    ENUM('pasajero','operador','sistema'),

    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY fk_viaje_pasajero  (pasajero_id) REFERENCES usuarios(id)  ON DELETE RESTRICT,
    FOREIGN KEY fk_viaje_operador  (operador_id) REFERENCES usuarios(id)  ON DELETE SET NULL,
    FOREIGN KEY fk_viaje_vehiculo  (vehiculo_id) REFERENCES vehiculos(id) ON DELETE SET NULL,

    INDEX idx_viajes_pasajero_estado  (pasajero_id, estado),
    INDEX idx_viajes_operador_estado  (operador_id, estado),
    INDEX idx_viajes_estado           (estado)
) ENGINE=InnoDB
  COMMENT='Viajes individuales B2C. Flujo de estado gestionado por Servlets y AsignadorOperador.';


-- ==============================================================================
-- BLOQUE 5 - SOLICITUDES DE OPERADOR (cascading assignment B2C)
-- ==============================================================================

CREATE TABLE solicitudes_operador (
    id          INT     PRIMARY KEY AUTO_INCREMENT,
    viaje_id    INT     NOT NULL,
    operador_id INT     NOT NULL,
    estado      ENUM('pendiente','aceptado','rechazado') NOT NULL DEFAULT 'pendiente',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY fk_sol_viaje    (viaje_id)    REFERENCES viajes(id)    ON DELETE CASCADE,
    FOREIGN KEY fk_sol_operador (operador_id) REFERENCES usuarios(id)  ON DELETE CASCADE,
    INDEX idx_sol_viaje_estado  (viaje_id, estado),
    INDEX idx_sol_op_pendiente  (operador_id, estado)
) ENGINE=InnoDB
  COMMENT='Registro de intentos de asignación. AsignadorOperador evita re-intentar operadores ya rechazados.';


-- ==============================================================================
-- BLOQUE 6 - CALIFICACIONES B2C (pasajero → operador)
-- ==============================================================================

CREATE TABLE calificaciones_viaje (
    id          INT     PRIMARY KEY AUTO_INCREMENT,
    viaje_id    INT     NOT NULL,
    autor_id    INT     NOT NULL   COMMENT 'Pasajero que califica',
    operador_id INT     NOT NULL   COMMENT 'Operador calificado',
    puntuacion  INT     NOT NULL   COMMENT '0-100',
    comentario  VARCHAR(500),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_cal_viaje (viaje_id)  COMMENT 'Una sola calificación por viaje',
    CONSTRAINT chk_punt_viaje CHECK (puntuacion BETWEEN 0 AND 100),
    FOREIGN KEY fk_cal_viaje_v  (viaje_id)    REFERENCES viajes(id)   ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_viaje_a  (autor_id)    REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_viaje_op (operador_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    INDEX idx_cal_viaje_operador (operador_id)
) ENGINE=InnoDB
  COMMENT='Calificaciones post-viaje B2C. Impactan calificacion_promedio del operador (SP).';


-- ==============================================================================
-- BLOQUE 7 - TARIFAS B2B ⚙
-- ==============================================================================

CREATE TABLE tarifas_vehiculo (
    id              INT           PRIMARY KEY AUTO_INCREMENT,
    modelo          ENUM(
                        'Irizar_i8',
                        'Busstar_DD',
                        'Marcopolo_G7',
                        'Volvo_9800',
                        'Irizar_i6',
                        'Torino'
                    ) NOT NULL,
    capacidad       TINYINT UNSIGNED NOT NULL COMMENT 'Pasajeros máximos',
    costo_por_km    DECIMAL(8,2)  NOT NULL    COMMENT 'MXN / km',
    costo_por_hora  DECIMAL(8,2)  NOT NULL    COMMENT 'MXN / hora (incluye estancias)',
    updated_at      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uq_tarifa_modelo (modelo)
) ENGINE=InnoDB
  COMMENT='Tarifas B2B por modelo. Editable desde panel Admin Urbvan sin tocar código.';

INSERT INTO tarifas_vehiculo (modelo, capacidad, costo_por_km, costo_por_hora) VALUES
('Irizar_i8',    47, 18.50, 320.00),
('Busstar_DD',   66, 22.00, 400.00),
('Marcopolo_G7', 44, 17.00, 300.00),
('Volvo_9800',   44, 17.00, 300.00),
('Irizar_i6',    50, 19.00, 330.00),
('Torino',       43, 16.50, 290.00);


-- ==============================================================================
-- BLOQUE 8 - LAYOUT DE ASIENTOS (poblado por SP en Bloque 19)
-- ==============================================================================

CREATE TABLE modelo_asientos_layout (
    id             INT              PRIMARY KEY AUTO_INCREMENT,
    modelo         ENUM(
                       'Irizar_i8',
                       'Busstar_DD',
                       'Marcopolo_G7',
                       'Volvo_9800',
                       'Irizar_i6',
                       'Torino'
                   ) NOT NULL,
    numero_asiento SMALLINT UNSIGNED NOT NULL COMMENT '1 .. capacidad del modelo',
    fila           CHAR(2)          NOT NULL  COMMENT 'A, B, C... (4 asientos por fila)',
    columna        TINYINT UNSIGNED NOT NULL
                       COMMENT '1=ventana-izq | 2=pasillo-izq | 3=pasillo-der | 4=ventana-der',
    es_pasillo     BOOLEAN          NOT NULL DEFAULT FALSE,

    UNIQUE KEY uq_layout (modelo, numero_asiento),
    INDEX idx_layout_modelo (modelo)
) ENGINE=InnoDB
  COMMENT='Mapa físico de asientos. Base para la UI de selección visual en el panel B2B.';


-- ==============================================================================
-- BLOQUE 9 - EMPRESAS B2B
-- ==============================================================================

CREATE TABLE empresas (
    id          INT           PRIMARY KEY AUTO_INCREMENT,
    nombre      VARCHAR(255)  NOT NULL,
    score       DECIMAL(5,2)  NOT NULL DEFAULT 100.00
                    COMMENT '0-100 | Calculado por SPs tras calificaciones y cancelaciones tardías',
    gasto_total DECIMAL(12,2) NOT NULL DEFAULT 0.00
                    COMMENT 'Suma acumulada de costos de rutas (informativo, sin pagos reales)',
    activa      BOOLEAN       NOT NULL DEFAULT TRUE
                    COMMENT 'FALSE = inhabilitada por Admin Urbvan. sp_inhabilitar_empresa() lo gestiona.',
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_empresas_activa (activa)
) ENGINE=InnoDB
  COMMENT='Empresas cliente del módulo B2B. Alta realizada por Admin Urbvan.';


-- ==============================================================================
-- BLOQUE 10 - USUARIOS DE EMPRESA (roles B2B)
-- ==============================================================================
--
--  Un usuario puede ser pasajero B2C Y empleado B2B simultáneamente.
--  usuarios.rol = 'pasajero' + empresa_usuarios.rol = 'empleado'  → ve pestaña "Empresa"
--  usuarios.rol = 'admin_empresa'                                  → accede al portal B2B
--
CREATE TABLE empresa_usuarios (
    id          INT  PRIMARY KEY AUTO_INCREMENT,
    empresa_id  INT  NOT NULL,
    usuario_id  INT  NOT NULL,
    rol         ENUM('admin_empresa','empleado') NOT NULL,
    activo      BOOLEAN  NOT NULL DEFAULT TRUE
                    COMMENT 'FALSE = baja de empresa. Cuenta de usuario intacta.',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_empresa_usuario_rol (empresa_id, usuario_id, rol),
    FOREIGN KEY fk_eu_empresa (empresa_id) REFERENCES empresas(id)  ON DELETE RESTRICT,
    FOREIGN KEY fk_eu_usuario (usuario_id) REFERENCES usuarios(id)  ON DELETE RESTRICT,
    INDEX idx_eu_usuario_activo  (usuario_id, activo),
    INDEX idx_eu_empresa_activo  (empresa_id, activo)
) ENGINE=InnoDB
  COMMENT='Vinculación usuario <-> empresa con rol B2B. Gestiona alta/baja de empleados.';


-- ==============================================================================
-- BLOQUE 11 - LOG DE SCORE CORPORATIVO
-- ==============================================================================

CREATE TABLE empresa_score_log (
    id             INT          PRIMARY KEY AUTO_INCREMENT,
    empresa_id     INT          NOT NULL,
    delta          DECIMAL(5,2) NOT NULL   COMMENT 'Cambio en puntos (+/-)',
    score_anterior DECIMAL(5,2) NOT NULL,
    score_nuevo    DECIMAL(5,2) NOT NULL,
    motivo         ENUM(
                       'calificacion_operador',
                       'cancelacion_tardia',
                       'ajuste_manual'
                   ) NOT NULL,
    referencia_id  INT                     COMMENT 'ID de ruta o calificación origen',
    created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY fk_score_log (empresa_id) REFERENCES empresas(id) ON DELETE RESTRICT,
    INDEX idx_score_log_empresa_fecha (empresa_id, created_at)
) ENGINE=InnoDB
  COMMENT='Trazabilidad completa de cada cambio de score corporativo.';


-- ==============================================================================
-- BLOQUE 12 - RUTAS B2B
-- ==============================================================================

CREATE TABLE rutas_b2b (
    id                  INT           PRIMARY KEY AUTO_INCREMENT,
    empresa_id          INT           NOT NULL,
    vehiculo_id         INT           NOT NULL,
    operador_id         INT           NOT NULL,

    fecha_inicio        DATETIME      NOT NULL,
    fecha_fin_est       DATETIME               COMMENT 'fecha_inicio + Σ trayectos + Σ estancias',
    km_totales          DECIMAL(8,2)           COMMENT 'Calculado por Azure Maps al crear la ruta',
    costo_total         DECIMAL(10,2)          COMMENT 'f(modelo, km, horas) usando tarifas_vehiculo',

    estado              ENUM(
                            'pendiente',
                            'activa',
                            'completada',
                            'cancelada'
                        ) NOT NULL DEFAULT 'pendiente',

    asignacion_completa BOOLEAN       NOT NULL DEFAULT FALSE
                            COMMENT 'TRUE cuando al menos un empleado tiene asiento asignado',
    cancelada_tarde     BOOLEAN       NOT NULL DEFAULT FALSE
                            COMMENT 'TRUE si canceló con < 24h. Penalización en score empresa.',
    penalizacion_puntos DECIMAL(5,2)  NOT NULL DEFAULT 0.00,

    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY fk_ruta_empresa  (empresa_id)  REFERENCES empresas(id)  ON DELETE RESTRICT,
    FOREIGN KEY fk_ruta_vehiculo (vehiculo_id) REFERENCES vehiculos(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_ruta_operador (operador_id) REFERENCES usuarios(id)  ON DELETE RESTRICT,

    INDEX idx_rutas_empresa_estado   (empresa_id,  estado),
    INDEX idx_rutas_operador_ventana (operador_id, fecha_inicio, fecha_fin_est),
    INDEX idx_rutas_vehiculo_estado  (vehiculo_id, estado),
    INDEX idx_rutas_fecha_inicio     (fecha_inicio)
) ENGINE=InnoDB
  COMMENT='Rutas corporativas B2B. No puede crearse sin operador disponible confirmado.';


-- ==============================================================================
-- BLOQUE 13 - PARADAS DE RUTA
-- ==============================================================================
--
--  orden 0   = origen
--  orden 1-6 = paradas intermedias (máx. 6 según requisitos)
--  orden MAX = destino final
--
CREATE TABLE ruta_paradas (
    id              INT              PRIMARY KEY AUTO_INCREMENT,
    ruta_id         INT              NOT NULL,
    orden           TINYINT UNSIGNED NOT NULL  COMMENT '0=origen | 1..6=intermedias | último=destino',
    tipo            ENUM('origen','parada','destino') NOT NULL,
    latitud         DECIMAL(10,8)    NOT NULL,
    longitud        DECIMAL(11,8)    NOT NULL,
    nombre_lugar    VARCHAR(255)               COMMENT 'Azure Maps geocoding o entrada manual',
    tiempo_estancia SMALLINT UNSIGNED NOT NULL DEFAULT 0
                        COMMENT 'Minutos de parada (0 para origen y destino)',
    hora_estimada   DATETIME                   COMMENT 'Base del horario compartido a empleados',

    UNIQUE KEY uq_ruta_orden (ruta_id, orden),
    FOREIGN KEY fk_parada_ruta (ruta_id) REFERENCES rutas_b2b(id) ON DELETE CASCADE,
    INDEX idx_paradas_ruta_orden (ruta_id, orden)
) ENGINE=InnoDB
  COMMENT='Puntos de la ruta B2B en orden. CASCADE: se eliminan si se elimina la ruta.';


-- ==============================================================================
-- BLOQUE 14 - ASIENTOS (soft-delete, unicidad via TRIGGER)
-- ==============================================================================
--
--  ⚠ No hay UNIQUE constraints aquí porque son incompatibles con soft-delete.
--     El trigger trg_ruta_asientos_before_insert (Bloque 17) enforza la unicidad
--     solo sobre registros activos, permitiendo reasignaciones y preservando historial.
--
CREATE TABLE ruta_asientos (
    id             INT              PRIMARY KEY AUTO_INCREMENT,
    ruta_id        INT              NOT NULL,
    empleado_id    INT              NOT NULL,
    numero_asiento SMALLINT UNSIGNED NOT NULL,
    activo         BOOLEAN          NOT NULL DEFAULT TRUE
                       COMMENT 'FALSE = empleado removido. Registro preservado para historial.',
    created_at     TIMESTAMP        DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY fk_asiento_ruta     (ruta_id)     REFERENCES rutas_b2b(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_asiento_empleado (empleado_id) REFERENCES usuarios(id)  ON DELETE RESTRICT,
    INDEX idx_asientos_ruta_activo   (ruta_id, activo),
    INDEX idx_asientos_empleado      (empleado_id)
) ENGINE=InnoDB
  COMMENT='Asignación empleado <-> asiento por ruta. Unicidad de activos gestionada por trigger.';


-- ==============================================================================
-- BLOQUE 15 - CALIFICACIONES AL OPERADOR B2B (empleado / admin_empresa → operador)
-- ==============================================================================

CREATE TABLE calificaciones_operador_b2b (
    id          INT     PRIMARY KEY AUTO_INCREMENT,
    ruta_id     INT     NOT NULL,
    autor_id    INT     NOT NULL    COMMENT 'Empleado o admin_empresa que califica',
    tipo_autor  ENUM('empleado','admin_empresa') NOT NULL,
    operador_id INT     NOT NULL,
    puntuacion  INT     NOT NULL    COMMENT '0-100',
    comentario  VARCHAR(500),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_cal_op_b2b_ruta_autor (ruta_id, autor_id)
        COMMENT 'Una calificación por persona por ruta',
    CONSTRAINT chk_punt_op_b2b CHECK (puntuacion BETWEEN 0 AND 100),
    FOREIGN KEY fk_cal_opb2b_ruta (ruta_id)     REFERENCES rutas_b2b(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_opb2b_aut  (autor_id)    REFERENCES usuarios(id)  ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_opb2b_op   (operador_id) REFERENCES usuarios(id)  ON DELETE RESTRICT,
    INDEX idx_cal_opb2b_operador (operador_id),
    INDEX idx_cal_opb2b_ruta     (ruta_id)
) ENGINE=InnoDB
  COMMENT='Ratings al operador en contexto B2B. Impactan calificacion_promedio compartido.';


-- ==============================================================================
-- BLOQUE 16 - CALIFICACIONES A LA EMPRESA (operador → empresa)
-- ==============================================================================

CREATE TABLE calificaciones_empresa_b2b (
    id          INT     PRIMARY KEY AUTO_INCREMENT,
    ruta_id     INT     NOT NULL,
    operador_id INT     NOT NULL    COMMENT 'Operador que califica el comportamiento corporativo',
    empresa_id  INT     NOT NULL,
    puntuacion  INT     NOT NULL    COMMENT '0-100',
    comentario  VARCHAR(500),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_cal_emp_ruta_op (ruta_id, operador_id)
        COMMENT 'El operador califica una sola vez por ruta',
    CONSTRAINT chk_punt_emp CHECK (puntuacion BETWEEN 0 AND 100),
    FOREIGN KEY fk_cal_emp_ruta (ruta_id)    REFERENCES rutas_b2b(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_emp_op   (operador_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_cal_emp_emp  (empresa_id) REFERENCES empresas(id)  ON DELETE RESTRICT,
    INDEX idx_cal_emp_empresa (empresa_id),
    INDEX idx_cal_emp_ruta    (ruta_id)
) ENGINE=InnoDB
  COMMENT='Calificación del operador sobre la empresa. Impacta score corporativo.';


-- ==============================================================================
-- BLOQUE 17 - NOTIFICACIONES
-- ==============================================================================

CREATE TABLE notificaciones (
    id         INT     PRIMARY KEY AUTO_INCREMENT,
    usuario_id INT     NOT NULL,
    tipo       ENUM(
                   'ruta_cancelada',
                   'asiento_asignado',
                   'asiento_removido',
                   'ruta_iniciada',
                   'calificacion_pendiente',
                   'empresa_inhabilitada',
                   'viaje_asignado'         -- B2C: operador recibió solicitud
               ) NOT NULL,
    mensaje    TEXT    NOT NULL,
    ruta_id    INT              COMMENT 'Referencia a ruta B2B (nullable)',
    viaje_id   INT              COMMENT 'Referencia a viaje B2C (nullable)',
    leida      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY fk_notif_usuario (usuario_id) REFERENCES usuarios(id)  ON DELETE CASCADE,
    FOREIGN KEY fk_notif_ruta    (ruta_id)    REFERENCES rutas_b2b(id) ON DELETE SET NULL,
    FOREIGN KEY fk_notif_viaje   (viaje_id)   REFERENCES viajes(id)    ON DELETE SET NULL,
    INDEX idx_notif_usuario_leida (usuario_id, leida, created_at)
) ENGINE=InnoDB
  COMMENT='Notificaciones para todos los roles. Lectura por polling desde JSP.';


-- ==============================================================================
-- BLOQUE 17.1 - BITÁCORA DE ACCIONES (funcionalidades recuperadas de v1)
-- ==============================================================================

CREATE TABLE bitacora_acciones (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    id_actor      INT NULL,
    nombre_actor  VARCHAR(150),
    rol           VARCHAR(40),
    accion        VARCHAR(80) NOT NULL,
    descripcion   VARCHAR(500),
    direccion_ip  VARCHAR(60),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_bitacora_actor_fecha (id_actor, created_at),
    INDEX idx_bitacora_accion      (accion)
) ENGINE=InnoDB
  COMMENT='Bitácora compatible con funciones v1: perfil, recuperación y acciones críticas.';


SET FOREIGN_KEY_CHECKS = 1;


-- ==============================================================================
-- BLOQUE 18 - TRIGGERS
-- ==============================================================================

-- ─── Unicidad de asientos activos (evita doble asignación con soft-delete) ───

DROP TRIGGER IF EXISTS trg_ruta_asientos_before_insert;

DELIMITER //

CREATE TRIGGER trg_ruta_asientos_before_insert
BEFORE INSERT ON ruta_asientos
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM ruta_asientos
        WHERE ruta_id        = NEW.ruta_id
          AND numero_asiento = NEW.numero_asiento
          AND activo         = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERR_ASIENTO_OCUPADO: El asiento ya tiene un empleado activo asignado';
    END IF;

    IF EXISTS (
        SELECT 1 FROM ruta_asientos
        WHERE ruta_id    = NEW.ruta_id
          AND empleado_id = NEW.empleado_id
          AND activo      = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERR_EMPLEADO_YA_ASIGNADO: El empleado ya tiene un asiento activo en esta ruta';
    END IF;
END //

DELIMITER ;


-- ==============================================================================
-- BLOQUE 19 - STORED PROCEDURES
-- ==============================================================================

-- ─── SP: Recalcular calificacion_promedio del operador ───────────────────────
--  Llamar tras insertar en calificaciones_viaje O calificaciones_operador_b2b

DROP PROCEDURE IF EXISTS sp_recalcular_score_operador;

DELIMITER //

CREATE PROCEDURE sp_recalcular_score_operador(IN p_operador_id INT)
    COMMENT 'Recalcula calificacion_promedio del operador sumando B2C y B2B.'
BEGIN
    DECLARE v_score DECIMAL(5,2);

    -- Promedio ponderado: todas las calificaciones recibidas (B2C + B2B)
    SELECT AVG(puntuacion)
    INTO   v_score
    FROM (
        SELECT puntuacion FROM calificaciones_viaje          WHERE operador_id = p_operador_id
        UNION ALL
        SELECT puntuacion FROM calificaciones_operador_b2b   WHERE operador_id = p_operador_id
    ) t;

    -- Si aún no tiene calificaciones, mantener 100
    IF v_score IS NULL THEN
        SET v_score = 100.00;
    END IF;

    UPDATE usuarios
    SET    calificacion_promedio = v_score
    WHERE  id = p_operador_id;
END //

DELIMITER ;

-- ─── SP: Cancelar ruta B2B con penalización ──────────────────────────────────

DROP PROCEDURE IF EXISTS sp_cancelar_ruta_b2b;

DELIMITER //

CREATE PROCEDURE sp_cancelar_ruta_b2b(IN p_ruta_id INT)
    COMMENT 'Cancela ruta, aplica penalización si < 24h, libera asientos, notifica empleados.'
BEGIN
    DECLARE v_empresa_id      INT;
    DECLARE v_fecha_inicio    DATETIME;
    DECLARE v_estado          VARCHAR(20);
    DECLARE v_horas_rest      DOUBLE;
    DECLARE v_penalizacion    DECIMAL(5,2) DEFAULT 0.00;
    DECLARE v_score_ant       DECIMAL(5,2);
    DECLARE v_score_nuevo     DECIMAL(5,2);
    DECLARE v_pen_config      DECIMAL(5,2) DEFAULT 10.00;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT empresa_id, fecha_inicio, estado
    INTO   v_empresa_id, v_fecha_inicio, v_estado
    FROM   rutas_b2b WHERE id = p_ruta_id FOR UPDATE;

    IF v_estado IN ('completada','cancelada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERR_ESTADO: La ruta ya fue completada o cancelada';
    END IF;

    SET v_horas_rest = TIMESTAMPDIFF(MINUTE, NOW(), v_fecha_inicio) / 60.0;

    -- Leer penalización desde configuración
    SELECT CAST(valor AS DECIMAL(5,2)) INTO v_pen_config
    FROM   configuracion WHERE clave = 'penalizacion_cancelacion_tardia';

    IF v_horas_rest < 24.0 THEN
        SET v_penalizacion = v_pen_config;
    END IF;

    -- Cancelar la ruta
    UPDATE rutas_b2b
    SET    estado              = 'cancelada',
           cancelada_tarde     = (v_penalizacion > 0),
           penalizacion_puntos = v_penalizacion,
           updated_at          = NOW()
    WHERE  id = p_ruta_id;

    -- Soft-delete de asientos
    UPDATE ruta_asientos SET activo = FALSE
    WHERE  ruta_id = p_ruta_id AND activo = TRUE;

    -- Penalización al score de la empresa
    IF v_penalizacion > 0 THEN
        SELECT score INTO v_score_ant FROM empresas WHERE id = v_empresa_id FOR UPDATE;
        SET v_score_nuevo = GREATEST(0.00, v_score_ant - v_penalizacion);

        UPDATE empresas SET score = v_score_nuevo WHERE id = v_empresa_id;

        INSERT INTO empresa_score_log
            (empresa_id, delta, score_anterior, score_nuevo, motivo, referencia_id)
        VALUES
            (v_empresa_id, -v_penalizacion, v_score_ant, v_score_nuevo,
             'cancelacion_tardia', p_ruta_id);
    END IF;

    -- Notificar a empleados
    INSERT INTO notificaciones (usuario_id, tipo, mensaje, ruta_id)
    SELECT
        ra.empleado_id,
        'ruta_cancelada',
        CONCAT('Tu ruta del ',
               DATE_FORMAT(v_fecha_inicio, '%d/%m/%Y a las %H:%i'),
               ' fue cancelada por la empresa.'),
        p_ruta_id
    FROM ruta_asientos ra WHERE ra.ruta_id = p_ruta_id;

    COMMIT;
END //

DELIMITER ;

-- ─── SP: Inhabilitar empresa ──────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_inhabilitar_empresa;

DELIMITER //

CREATE PROCEDURE sp_inhabilitar_empresa(IN p_empresa_id INT)
    COMMENT 'Inhabilita empresa, cancela rutas pendientes/activas, libera asientos, notifica.'
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Cancelar rutas (sin penalización: es decisión de Admin Urbvan)
    UPDATE rutas_b2b
    SET    estado = 'cancelada', updated_at = NOW()
    WHERE  empresa_id = p_empresa_id AND estado IN ('pendiente','activa');

    -- Liberar asientos
    UPDATE ruta_asientos ra
    JOIN   rutas_b2b r ON ra.ruta_id = r.id
    SET    ra.activo = FALSE
    WHERE  r.empresa_id = p_empresa_id AND ra.activo = TRUE;

    -- Notificar empleados afectados
    INSERT INTO notificaciones (usuario_id, tipo, mensaje, ruta_id)
    SELECT DISTINCT
        ra.empleado_id,
        'empresa_inhabilitada',
        'Tu empresa ha sido inhabilitada en Urbvan. Tus rutas pendientes han sido canceladas.',
        ra.ruta_id
    FROM ruta_asientos ra
    JOIN rutas_b2b r ON ra.ruta_id = r.id
    WHERE r.empresa_id = p_empresa_id;

    UPDATE empresas SET activa = FALSE WHERE id = p_empresa_id;

    COMMIT;
END //

DELIMITER ;

-- ─── SP: Calificar operador B2B ───────────────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_calificar_operador_b2b;

DELIMITER //

CREATE PROCEDURE sp_calificar_operador_b2b(
    IN p_ruta_id     INT,
    IN p_autor_id    INT,
    IN p_tipo_autor  ENUM('empleado','admin_empresa'),
    IN p_operador_id INT,
    IN p_puntuacion  INT,
    IN p_comentario  VARCHAR(500)
)
    COMMENT 'Registra calificación al operador y recalcula su score promedio B2C+B2B.'
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO calificaciones_operador_b2b
        (ruta_id, autor_id, tipo_autor, operador_id, puntuacion, comentario)
    VALUES
        (p_ruta_id, p_autor_id, p_tipo_autor, p_operador_id, p_puntuacion, p_comentario);

    CALL sp_recalcular_score_operador(p_operador_id);

    COMMIT;
END //

DELIMITER ;

-- ─── SP: Calificar empresa B2B ────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_calificar_empresa_b2b;

DELIMITER //

CREATE PROCEDURE sp_calificar_empresa_b2b(
    IN p_ruta_id     INT,
    IN p_operador_id INT,
    IN p_empresa_id  INT,
    IN p_puntuacion  INT,
    IN p_comentario  VARCHAR(500)
)
    COMMENT 'Registra calificación del operador sobre la empresa y actualiza score corporativo.'
BEGIN
    DECLARE v_score_ant  DECIMAL(5,2);
    DECLARE v_score_nuevo DECIMAL(5,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO calificaciones_empresa_b2b
        (ruta_id, operador_id, empresa_id, puntuacion, comentario)
    VALUES
        (p_ruta_id, p_operador_id, p_empresa_id, p_puntuacion, p_comentario);

    SELECT score INTO v_score_ant FROM empresas WHERE id = p_empresa_id FOR UPDATE;

    SELECT AVG(puntuacion) INTO v_score_nuevo
    FROM   calificaciones_empresa_b2b WHERE empresa_id = p_empresa_id;

    UPDATE empresas SET score = v_score_nuevo WHERE id = p_empresa_id;

    INSERT INTO empresa_score_log
        (empresa_id, delta, score_anterior, score_nuevo, motivo, referencia_id)
    VALUES
        (p_empresa_id, v_score_nuevo - v_score_ant, v_score_ant, v_score_nuevo,
         'calificacion_operador', p_ruta_id);

    COMMIT;
END //

DELIMITER ;

-- ─── SP: Seed de layout de asientos ──────────────────────────────────────────

DROP PROCEDURE IF EXISTS sp_seed_layout_asientos;

DELIMITER //

CREATE PROCEDURE sp_seed_layout_asientos(
    IN p_modelo    VARCHAR(20),
    IN p_capacidad SMALLINT UNSIGNED
)
    COMMENT 'Genera mapa de asientos para un modelo (4 por fila: ventana-pasillo-pasillo-ventana).'
BEGIN
    DECLARE i        SMALLINT UNSIGNED DEFAULT 1;
    DECLARE v_fila   CHAR(2);
    DECLARE v_col    TINYINT UNSIGNED;
    DECLARE v_pasill BOOLEAN;

    DELETE FROM modelo_asientos_layout WHERE modelo = p_modelo;

    WHILE i <= p_capacidad DO
        SET v_fila  = CHAR(64 + CAST(CEIL(i / 4) AS UNSIGNED));
        SET v_col   = CASE
                          WHEN i % 4 = 1 THEN 1
                          WHEN i % 4 = 2 THEN 2
                          WHEN i % 4 = 3 THEN 3
                          ELSE                4
                      END;
        SET v_pasill = (v_col IN (2, 3));

        INSERT INTO modelo_asientos_layout (modelo, numero_asiento, fila, columna, es_pasillo)
        VALUES (p_modelo, i, v_fila, v_col, v_pasill);

        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;


-- ==============================================================================
-- BLOQUE 20 - VISTAS
-- ==============================================================================

-- Vista: detalle completo de ruta B2B
CREATE OR REPLACE VIEW v_rutas_b2b_detalle AS
SELECT
    r.id                  AS ruta_id,
    r.estado,
    r.fecha_inicio,
    r.fecha_fin_est,
    r.km_totales,
    r.costo_total,
    r.asignacion_completa,
    r.cancelada_tarde,
    r.created_at          AS ruta_creada_at,
    e.id                  AS empresa_id,
    e.nombre              AS empresa_nombre,
    e.score               AS empresa_score,
    v.id                  AS vehiculo_id,
    v.modelo              AS vehiculo_modelo,
    v.placa               AS vehiculo_placa,
    v.capacidad           AS vehiculo_capacidad,
    op.id                 AS operador_id,
    op.nombre             AS operador_nombre,
    op.calificacion_promedio AS operador_score,
    COUNT(CASE WHEN ra.activo = TRUE THEN 1 END) AS asientos_ocupados
FROM      rutas_b2b     r
JOIN      empresas      e  ON r.empresa_id  = e.id
JOIN      vehiculos     v  ON r.vehiculo_id = v.id
JOIN      usuarios      op ON r.operador_id = op.id
LEFT JOIN ruta_asientos ra ON ra.ruta_id    = r.id
GROUP BY
    r.id, r.estado, r.fecha_inicio, r.fecha_fin_est, r.km_totales, r.costo_total,
    r.asignacion_completa, r.cancelada_tarde, r.created_at,
    e.id, e.nombre, e.score, v.id, v.modelo, v.placa, v.capacidad,
    op.id, op.nombre, op.calificacion_promedio;

-- Vista: operadores disponibles base (para asignación automática B2B)
--   Filtrar adicionalmente por modelo y ventana de tiempo en el Servlet/DAO
CREATE OR REPLACE VIEW v_operadores_disponibles_base AS
SELECT
    u.id                    AS operador_id,
    u.nombre                AS operador_nombre,
    u.calificacion_promedio AS operador_score,
    u.lat,
    u.lng,
    v.id                    AS vehiculo_id,
    v.modelo                AS vehiculo_modelo,
    v.capacidad             AS vehiculo_capacidad
FROM  usuarios  u
JOIN  vehiculos v ON v.operador_id = u.id
WHERE u.rol    = 'operador'
  AND u.activo = TRUE
  AND v.activo = TRUE
  AND v.categoria = 'b2b';

-- Vista: rutas asignadas a un empleado (pestaña "Empresa")
CREATE OR REPLACE VIEW v_rutas_empleado AS
SELECT
    ra.empleado_id,
    ra.numero_asiento,
    r.id              AS ruta_id,
    r.estado,
    r.fecha_inicio,
    r.fecha_fin_est,
    r.costo_total,
    e.nombre          AS empresa_nombre,
    v.modelo          AS vehiculo_modelo,
    op.nombre         AS operador_nombre,
    op.calificacion_promedio AS operador_score
FROM      ruta_asientos ra
JOIN      rutas_b2b     r  ON ra.ruta_id    = r.id
JOIN      empresas      e  ON r.empresa_id  = e.id
JOIN      vehiculos     v  ON r.vehiculo_id = v.id
JOIN      usuarios      op ON r.operador_id = op.id
WHERE ra.activo = TRUE;

-- Vista: panel de empresas para Admin Urbvan
CREATE OR REPLACE VIEW v_panel_empresas AS
SELECT
    e.id                    AS empresa_id,
    e.nombre,
    e.score,
    e.gasto_total,
    e.activa,
    e.created_at,
    COUNT(DISTINCT CASE WHEN eu.rol = 'empleado' AND eu.activo = TRUE
                   THEN eu.usuario_id END)       AS empleados_activos,
    COUNT(DISTINCT CASE WHEN r.estado = 'completada'
                   THEN r.id END)                AS rutas_completadas,
    COUNT(DISTINCT CASE WHEN r.estado IN ('pendiente','activa')
                   THEN r.id END)                AS rutas_en_curso,
    COALESCE(SUM(CASE WHEN r.estado = 'completada' THEN r.costo_total END), 0)
                                                 AS gasto_verificado
FROM      empresas       e
LEFT JOIN empresa_usuarios eu ON eu.empresa_id = e.id
LEFT JOIN rutas_b2b        r  ON r.empresa_id  = e.id
GROUP BY  e.id, e.nombre, e.score, e.gasto_total, e.activa, e.created_at;

-- Vista: historial de viajes B2C enriquecido
CREATE OR REPLACE VIEW v_viajes_detalle AS
SELECT
    v.id,
    v.estado,
    v.origen_nombre,
    v.destino_nombre,
    v.distancia_km,
    v.duracion_min,
    v.costo,
    v.metodo_pago,
    v.created_at,
    p.id     AS pasajero_id,
    p.nombre AS pasajero_nombre,
    o.id     AS operador_id,
    o.nombre AS operador_nombre,
    o.calificacion_promedio AS operador_score,
    vh.modelo AS vehiculo_modelo,
    vh.placa  AS vehiculo_placa,
    cal.puntuacion AS calificacion_dada
FROM      viajes              v
JOIN      usuarios            p   ON v.pasajero_id  = p.id
LEFT JOIN usuarios            o   ON v.operador_id  = o.id
LEFT JOIN vehiculos           vh  ON v.vehiculo_id  = vh.id
LEFT JOIN calificaciones_viaje cal ON cal.viaje_id  = v.id;


-- ==============================================================================
-- BLOQUE 21 - SEED DATA
-- ==============================================================================

-- ─── Layout de asientos ───────────────────────────────────────────────────────
CALL sp_seed_layout_asientos('Irizar_i8',    47);
CALL sp_seed_layout_asientos('Busstar_DD',   66);
CALL sp_seed_layout_asientos('Marcopolo_G7', 44);
CALL sp_seed_layout_asientos('Volvo_9800',   44);
CALL sp_seed_layout_asientos('Irizar_i6',    50);
CALL sp_seed_layout_asientos('Torino',       43);

-- ─── Usuario Admin Urbvan ─────────────────────────────────────────────────────
-- Contraseña: Admin1234  (SHA-256)
INSERT INTO usuarios (nombre, email, contrasena, rol) VALUES
('Admin Urbvan',
 'admin@urbvan.mx',
 '3f21a8490cef2bfb60a9702e9d2ddb7a390b9a4fb88bdbde97a3d3ef5b0b8a1f',
 'admin');

-- ─── Operador de prueba ───────────────────────────────────────────────────────
-- Contraseña: Operador1  (SHA-256)
INSERT INTO usuarios (nombre, email, contrasena, rol, lat, lng) VALUES
('Carlos Mendoza',
 'carlos.operador@urbvan.mx',
 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3',
 'operador',
 19.4326, -99.1332);

-- ─── Vehículo B2B de prueba asignado al operador ─────────────────────────────
INSERT INTO vehiculos (modelo, capacidad, placa, color, operador_id, categoria) VALUES
('Irizar_i8', 47, 'ABC-123-CDMX', 'Blanco', 2, 'b2b');

-- ─── Operadores y unidades B2C para la función tipo Uber ─────────────────────
-- Contraseña de ambos operadores: Operador1
INSERT INTO usuarios (nombre, apellido, telefono, email, contrasena, rol, lat, lng) VALUES
('Luis',  'Ramírez', '5511111111', 'luis.operador@urbvan.mx',
 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'operador', 19.4340, -99.1360),
('Ana',   'Torres',  '5522222222', 'ana.operador@urbvan.mx',
 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'operador', 19.4280, -99.1300),
('Diego', 'Santos',  '5533333333', 'diego.operador@urbvan.mx',
 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'operador', 19.4400, -99.1200);

INSERT INTO vehiculos (modelo, capacidad, placa, color, operador_id, categoria) VALUES
('Sedan',   4, 'UBR-101-CDMX', 'Blanco', 3, 'b2c'),
('SUV',     6, 'UBR-202-CDMX', 'Negro',  4, 'b2c'),
('Minivan', 8, 'UBR-303-CDMX', 'Gris',   5, 'b2c');

-- ─── Pasajero de prueba ───────────────────────────────────────────────────────
-- Contraseña: Pasajero1  (SHA-256)
INSERT INTO usuarios (nombre, apellido, telefono, email, contrasena, rol) VALUES
('María', 'López', '5544444444',
 'maria.pasajero@urbvan.mx',
 'e3afed0047b08059d0fada10f400c1e5cc3576f6b29367f62d4aea8b2dddd549',
 'pasajero');




-- ==============================================================================
-- BLOQUE 21 - EVENTOS OPERATIVOS B2B Y TRACKING EN VIVO
-- ==============================================================================
-- Registra cada avance operativo que realiza el operador B2B desde el portal:
-- iniciar ruta, llegar a una parada, salir hacia el siguiente punto y terminar ruta.
-- La posición lat/lng se toma del navegador del operador cuando está disponible.

CREATE TABLE IF NOT EXISTS ruta_b2b_eventos (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    ruta_id       INT NOT NULL,
    operador_id   INT NOT NULL,
    parada_id     INT NULL,
    orden_parada  TINYINT UNSIGNED NULL,
    tipo          ENUM('inicio_ruta','llegada_parada','salida_parada','fin_ruta') NOT NULL,
    latitud       DECIMAL(10,8) NULL,
    longitud      DECIMAL(11,8) NULL,
    comentario    VARCHAR(300) NULL,
    creado_en     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY fk_ev_b2b_ruta     (ruta_id)     REFERENCES rutas_b2b(id) ON DELETE CASCADE,
    FOREIGN KEY fk_ev_b2b_operador (operador_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY fk_ev_b2b_parada   (parada_id)   REFERENCES ruta_paradas(id) ON DELETE SET NULL,
    INDEX idx_ev_b2b_ruta_fecha (ruta_id, creado_en),
    INDEX idx_ev_b2b_operador_fecha (operador_id, creado_en)
) ENGINE=InnoDB
  COMMENT='Eventos del operador B2B para tracking en vivo y trazabilidad de paradas.';

-- ==============================================================================
-- VERIFICACIÓN FINAL
-- ==============================================================================

SELECT '=== Tablas creadas ===' AS '';
SELECT table_name AS Tabla,
       table_rows AS Filas_est,
       table_comment AS Descripcion
FROM   information_schema.tables
WHERE  table_schema = 'urbvan'
  AND  table_type   = 'BASE TABLE'
ORDER BY table_name;

SELECT '=== Vistas ===' AS '';
SELECT table_name AS Vista
FROM   information_schema.views
WHERE  table_schema = 'urbvan'
ORDER BY table_name;

SELECT '=== Asientos generados ===' AS '';
SELECT modelo, COUNT(*) AS total_asientos
FROM   modelo_asientos_layout
GROUP BY modelo ORDER BY modelo;

SELECT '=== Usuarios seed ===' AS '';
SELECT id, nombre, email, rol FROM usuarios;

-- ==============================================================================
--  FIN - urbvan_bd_v2.sql
--  Clases Java que necesitan actualización tras ejecutar este script:
--    1. FiltroSesion.java       → añadir rutas /b2b/* y rol admin_empresa
--    2. AsignadorOperador.java  → actualizar query para usar solicitudes_operador
--    3. Usuario.java (modelo)   → añadir campo calificacionPromedio, primerLogin
--    4. Vehiculo.java (modelo)  → añadir campo categoria
--    5. Nuevos: Empresa.java, RutaB2B.java, RutaParada.java, RutaAsiento.java
-- ==============================================================================

UPDATE usuarios SET contrasena = '60fe74406e7f353ed979f350f2fbb6a2e8690a5fa7d1b0c32983d1d8b3f95f67' WHERE email = 'admin@urbvan.mx';
UPDATE usuarios SET contrasena = 'bbba28c852444bd0f7b343941a8932c4ca8625d76868793c5bce10aabd1012bb' WHERE email = 'carlos.operador@urbvan.mx';
UPDATE usuarios SET contrasena = 'cc69b446e277220e777bcf83bf3740c408199f8794bd25fd8a30f4d0d19c7a71' WHERE email = 'maria.pasajero@urbvan.mx';