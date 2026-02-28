USE inmobiliaria_db;

-- ================================================================
-- VISTA 2: vista_pagos_pendientes
-- Muestra todos los pagos en estado Pendiente o Vencido
-- con los datos del cliente y el contrato asociado
-- Diseñada para que el contador vea de un vistazo quién debe y cuánto
-- ================================================================

DROP PROCEDURE IF EXISTS sp_crear_vista_pagos_pendientes;

DELIMITER $$

CREATE PROCEDURE sp_crear_vista_pagos_pendientes()
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
            'ERROR AL CREAR VISTA: vista_pagos_pendientes',
            'Procedimiento: sp_crear_vista_pagos_pendientes',
            'Ocurrió un error al intentar crear la vista vista_pagos_pendientes'
        );
    END;

    -- Eliminar la vista si ya existe
    DROP VIEW IF EXISTS vista_pagos_pendientes;

    -- Crear la vista
    CREATE VIEW vista_pagos_pendientes AS
    SELECT
        p.Pago_ID                               AS pago_id,
        p.Contrato_ID                           AS contrato_id,
        c.Tipo_Contrato                         AS tipo_contrato,
        CONCAT(pc.Nombre, ' ', pc.Apellido)     AS nombre_cliente,
        pc.Telefono                             AS telefono_cliente,
        pc.Email                                AS email_cliente,
        p.Fecha_Pago                            AS fecha_pago,
        p.Monto_Pago                            AS monto_pendiente,
        ep.Descripcion                          AS estado_pago
    FROM pagos p
    JOIN contratos c        ON c.Contrato_ID  = p.Contrato_ID
    JOIN clientes cl        ON cl.Cliente_ID  = c.Cliente_ID
    JOIN personas pc        ON pc.Persona_ID  = cl.Persona_ID
    JOIN estadopago ep      ON ep.EstadoPago_ID = p.EstadoPago_ID
    WHERE p.EstadoPago_ID IN ('EPG-02', 'EPG-03');

    -- Registrar éxito en logs_cambios
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'VISTA CREADA: vista_pagos_pendientes',
        'Procedimiento: sp_crear_vista_pagos_pendientes',
        'Vista vista_pagos_pendientes creada exitosamente. Filtra pagos EPG-02 (Pendiente) y EPG-03 (Vencido). Une: pagos, contratos, clientes, personas, estadopago.'
    );

END$$

DELIMITER ;

-- Ejecutar el procedimiento
CALL sp_crear_vista_pagos_pendientes();


-- ================================================================
-- EJEMPLOS DE USO
-- ================================================================

-- Ver todos los pagos pendientes y vencidos
SELECT * FROM vista_pagos_pendientes;

-- Ver solo los pagos vencidos
SELECT * FROM vista_pagos_pendientes
WHERE estado_pago = 'Vencido';

-- Ver deuda total por cliente
SELECT
    nombre_cliente,
    SUM(monto_pendiente) AS deuda_total
FROM vista_pagos_pendientes
GROUP BY nombre_cliente
ORDER BY deuda_total DESC;

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 3;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 3;