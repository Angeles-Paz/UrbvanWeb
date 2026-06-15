

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


-- Para bases ya creadas, ejecutar este archivo una vez sobre la base urbvan.
