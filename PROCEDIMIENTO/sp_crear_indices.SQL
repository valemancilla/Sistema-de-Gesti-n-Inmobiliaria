

USE inmobiliaria_db;

-- ============================================================
-- PROCEDIMIENTO 2: sp_crear_indices
-- Solo crea índices — usa EXIT HANDLER para registrar
-- en logs_errores si algo falla al crearlos
-- ============================================================

DROP PROCEDURE IF EXISTS sp_crear_indices;

DELIMITER $$

CREATE PROCEDURE sp_crear_indices()
BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (
            Fecha_Error,
            Nombre_Error,
            Lugar_Error,
            Detalle
        )
        VALUES (
            NOW(),
            'ERROR AL CREAR ÍNDICES',
            'Procedimiento: sp_crear_indices',
            'Ocurrió un error al intentar crear los índices de optimización'
        );
    END;

    -- Tabla: contratos
    CREATE INDEX idx_contratos_tipo      ON contratos (Tipo_Contrato);
    CREATE INDEX idx_contratos_cliente   ON contratos (Cliente_ID);
    CREATE INDEX idx_contratos_propiedad ON contratos (Propiedad_ID);
    CREATE INDEX idx_contratos_agente    ON contratos (Agente_ID);

    -- Tabla: pagos
    CREATE INDEX idx_pagos_contrato ON pagos (Contrato_ID);
    CREATE INDEX idx_pagos_estado   ON pagos (EstadoPago_ID);
    CREATE INDEX idx_pagos_fecha    ON pagos (Fecha_Pago);

    -- Tabla: propiedad
    CREATE INDEX idx_propiedad_estado ON propiedad (EstadoP_ID);
    CREATE INDEX idx_propiedad_tipo   ON propiedad (TipoP_ID);

    -- Tabla: reportepagos
    CREATE INDEX idx_reportepagos_contrato ON reportepagos (Contrato_ID);
    CREATE INDEX idx_reportepagos_periodo  ON reportepagos (Periodo);

    -- Tabla: contratoarriendo
    CREATE INDEX idx_contratoarriendo_contrato ON contratoarriendo (Contrato_ID);

    -- Registrar éxito en logs_cambios
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'CREACIÓN DE ÍNDICES',
        'Procedimiento: sp_crear_indices',
        'Índices creados exitosamente en tablas: contratos, pagos, propiedad, reportepagos, contratoarriendo'
    );

END$$

DELIMITER ;


-- ============================================================
-- EJECUTAR: primero eliminar, luego crear
-- ============================================================

CALL sp_eliminar_indices();
CALL sp_crear_indices();


-- ============================================================
-- VERIFICACIONES FINALES
-- ============================================================

SHOW EVENTS FROM inmobiliaria_db;

SHOW INDEX FROM contratos;
SHOW INDEX FROM pagos;
SHOW INDEX FROM propiedad;
SHOW INDEX FROM reportepagos;
SHOW INDEX FROM contratoarriendo;

SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC;