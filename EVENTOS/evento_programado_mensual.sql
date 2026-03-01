USE inmobiliaria_db;

-- ============================================================
-- EVENTO PROGRAMADO MENSUAL
-- Se ejecuta automáticamente cada mes
-- Inserta en reportepagos los contratos de arriendo
-- con pagos pendientes o vencidos
-- ============================================================

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_reporte_mensual_pagos_pendientes;

DELIMITER $$

CREATE EVENT evt_reporte_mensual_pagos_pendientes
ON SCHEDULE EVERY 1 MONTH
STARTS '2024-01-01 00:00:00'
DO
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
            'ERROR EN EVENTO: evt_reporte_mensual_pagos_pendientes',
            'Evento programado mensual',
            CONCAT('Error al generar reporte del periodo: ',
                   DATE_FORMAT(CURDATE(), '%Y-%m'))
        );
    END;

    INSERT INTO reportepagos (
        Reporte_ID,
        Contrato_ID,
        Fecha_Reporte,
        Monto_Pendiente,
        Descripcion,
        Periodo
    )
    SELECT
        CONCAT('REP-', UUID_SHORT()),
        p.Contrato_ID,
        CURDATE(),
        SUM(p.Monto_Pago),
        CONCAT('Reporte mensual automático | Contrato: ', p.Contrato_ID,
               ' | Pagos pendientes/vencidos: ', COUNT(p.Pago_ID)),
        DATE_FORMAT(CURDATE(), '%Y-%m')
    FROM pagos p
    JOIN contratos c ON c.Contrato_ID  = p.Contrato_ID
                    AND c.Tipo_Contrato = 'Arriendo'
    WHERE p.EstadoPago_ID IN ('EPG-02', 'EPG-03')
    GROUP BY p.Contrato_ID
    HAVING SUM(p.Monto_Pago) > 0;

    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'EVENTO MENSUAL EJECUTADO',
        'Evento: evt_reporte_mensual_pagos_pendientes',
        CONCAT('Reporte mensual generado para el periodo: ',
               DATE_FORMAT(CURDATE(), '%Y-%m'))
    );

END$$

DELIMITER ;

-- ============================================================
-- VERIFICACIONES FINALES
-- ============================================================

SHOW EVENTS FROM inmobiliaria_db;

SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 5;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 5;