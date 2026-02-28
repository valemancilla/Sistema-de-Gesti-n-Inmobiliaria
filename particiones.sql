USE inmobiliaria_db;

-- ================================================================
-- PARTICIONAMIENTO DE LA TABLA PAGOS
-- Tipo: PARTITION BY RANGE (YEAR(Fecha_Pago))
-- Justificación: Pagos es la tabla que más crece en el tiempo.
-- Cada contrato de arriendo genera un pago mensual indefinidamente.
-- Particionar por año permite que las consultas solo lean
-- la partición del año relevante en vez de toda la tabla.
-- ================================================================

DROP PROCEDURE IF EXISTS sp_particionar_pagos;

DELIMITER $$

CREATE PROCEDURE sp_particionar_pagos()
BEGIN

    -- ============================================================
    -- Manejador de errores: si algo falla registra en logs_errores
    -- ============================================================
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
            'ERROR AL PARTICIONAR TABLA PAGOS',
            'Procedimiento: sp_particionar_pagos',
            'Ocurrió un error al recrear la tabla Pagos con particionamiento RANGE.'
        );
    END;

    -- ============================================================
    -- PASO 1: Eliminar la tabla Pagos existente
    -- ============================================================
    DROP TABLE IF EXISTS Pagos;

    -- ============================================================
    -- PASO 2: Recrear Pagos con particionamiento RANGE por año
       -- ============================================================
    CREATE TABLE Pagos (
        Pago_ID       VARCHAR(10)   NOT NULL,
        Contrato_ID   VARCHAR(10)   NOT NULL,
        Fecha_Pago    DATE          NOT NULL,
        Monto_Pago    DECIMAL(12,2) NOT NULL,
        EstadoPago_ID VARCHAR(10)   NOT NULL,
        PRIMARY KEY   (Pago_ID, Fecha_Pago)
    ) PARTITION BY RANGE (YEAR(Fecha_Pago)) (
        PARTITION p2023    VALUES LESS THAN (2024),
        PARTITION p2024    VALUES LESS THAN (2025),
        PARTITION p2025    VALUES LESS THAN (2026),
        PARTITION p2026    VALUES LESS THAN (2027),
        PARTITION p_futuro VALUES LESS THAN MAXVALUE
    );

    -- ============================================================
    -- PASO 3: Reinsertar los datos de prueba
    -- ============================================================
    INSERT INTO Pagos (Pago_ID, Contrato_ID, Fecha_Pago, Monto_Pago, EstadoPago_ID) VALUES
    ('PAG-001', 'CON-001', '2024-01-15',   800000.00, 'EPG-01'),
    ('PAG-002', 'CON-001', '2024-02-15',   800000.00, 'EPG-01'),
    ('PAG-003', 'CON-001', '2024-03-15',   800000.00, 'EPG-02'),
    ('PAG-004', 'CON-002', '2024-02-01',  9600000.00, 'EPG-01'),
    ('PAG-005', 'CON-003', '2024-03-10',  1200000.00, 'EPG-01'),
    ('PAG-006', 'CON-003', '2024-04-10',  1200000.00, 'EPG-02'),
    ('PAG-007', 'CON-004', '2024-04-05', 13500000.00, 'EPG-01'),
    ('PAG-008', 'CON-005', '2024-05-20',   950000.00, 'EPG-03'),
    ('PAG-009', 'CON-006', '2024-06-12',  8400000.00, 'EPG-01');

    -- ============================================================
    -- PASO 4: Registrar éxito en logs_cambios
    -- ============================================================
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'PARTICIONAMIENTO TABLA PAGOS',
        'Procedimiento: sp_particionar_pagos',
        'Tabla Pagos recreada con PARTITION BY RANGE (YEAR(Fecha_Pago)). Particiones: p2023, p2024, p2025, p2026, p_futuro. Datos de prueba reinsertados.'
    );

END$$

DELIMITER ;

-- ================================================================
-- EJECUTAR EL PROCEDIMIENTO
-- ================================================================
CALL sp_particionar_pagos();


-- ================================================================
-- VERIFICACIONES FINALES
-- ================================================================

-- Ver cuántas filas hay en cada partición
SELECT
    PARTITION_NAME        AS particion,
    PARTITION_DESCRIPTION AS limite_superior,
    TABLE_ROWS            AS filas
FROM
    information_schema.PARTITIONS
WHERE
    TABLE_SCHEMA = 'inmobiliaria_db'
    AND TABLE_NAME = 'pagos'
ORDER BY
    PARTITION_ORDINAL_POSITION;

-- Consultar solo los pagos de la partición 2024
SELECT * FROM Pagos PARTITION (p2024);

-- Verificar los logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 3;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 3;