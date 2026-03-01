USE inmobiliaria_db;

-- ================================================================
-- CRUD PAGOS
-- "historial de pagos"
-- ================================================================


-- ----------------------------------------------------------------
-- CREATE — Registrar un nuevo pago
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_insertar_pago;

DELIMITER $$

CREATE PROCEDURE sp_insertar_pago(
    IN p_pago_id      VARCHAR(10),
    IN p_contrato_id  VARCHAR(10),
    IN p_fecha        DATE,
    IN p_monto        DECIMAL(12,2),
    IN p_estado_id    VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL INSERTAR PAGO',
                'Procedimiento: sp_insertar_pago',
                CONCAT('No se pudo registrar el pago ID: ', p_pago_id,
                       ' del contrato: ', p_contrato_id));
    END;

    INSERT INTO Pagos (Pago_ID, Contrato_ID, Fecha_Pago, Monto_Pago, EstadoPago_ID)
    VALUES (p_pago_id, p_contrato_id, p_fecha, p_monto, p_estado_id);

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PAGO REGISTRADO', 'Procedimiento: sp_insertar_pago',
            CONCAT('Pago ID: ', p_pago_id, ' | Contrato: ', p_contrato_id,
                   ' | Monto: $', p_monto, ' | Estado: ', p_estado_id));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_insertar_pago('PAG-010', 'CON-001', '2025-03-15', 800000.00, 'EPG-02');


-- ----------------------------------------------------------------
-- READ — Consultar todos los pagos de un contrato
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_consultar_pagos_contrato;

DELIMITER $$

CREATE PROCEDURE sp_consultar_pagos_contrato(
    IN p_contrato_id VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL CONSULTAR PAGOS',
                'Procedimiento: sp_consultar_pagos_contrato',
                CONCAT('No se pudieron consultar pagos del contrato: ', p_contrato_id));
    END;

    SELECT
        p.Pago_ID,
        p.Fecha_Pago,
        p.Monto_Pago,
        ep.Descripcion AS estado_pago
    FROM Pagos p
    JOIN EstadoPago ep ON ep.EstadoPago_ID = p.EstadoPago_ID
    WHERE p.Contrato_ID = p_contrato_id
    ORDER BY p.Fecha_Pago ASC;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CONSULTA PAGOS CONTRATO', 'Procedimiento: sp_consultar_pagos_contrato',
            CONCAT('Consulta de pagos del contrato ID: ', p_contrato_id));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_consultar_pagos_contrato('CON-001');


-- ----------------------------------------------------------------
-- UPDATE — Marcar un pago como pagado
-- Activa automáticamente: trg_after_update_estado_pago
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_estado_pago;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_estado_pago(
    IN p_pago_id      VARCHAR(10),
    IN p_nuevo_estado VARCHAR(10)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ACTUALIZAR PAGO',
                'Procedimiento: sp_actualizar_estado_pago',
                CONCAT('No se pudo actualizar el pago ID: ', p_pago_id));
    END;

    SELECT COUNT(*) INTO v_existe FROM Pagos WHERE Pago_ID = p_pago_id;

    IF v_existe = 0 THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'PAGO NO ENCONTRADO',
                'Procedimiento: sp_actualizar_estado_pago',
                CONCAT('El pago ID: ', p_pago_id, ' no existe en el sistema'));
    ELSE
        -- El trigger trg_after_update_estado_pago registra
        -- el cambio automáticamente en logs_cambios
        UPDATE Pagos SET EstadoPago_ID = p_nuevo_estado WHERE Pago_ID = p_pago_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'ESTADO PAGO ACTUALIZADO', 'Procedimiento: sp_actualizar_estado_pago',
                CONCAT('Pago ID: ', p_pago_id, ' actualizado al estado: ', p_nuevo_estado));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso: marcar pago como pagado
CALL sp_actualizar_estado_pago('PAG-010', 'EPG-01');


-- ----------------------------------------------------------------
-- DELETE — Eliminar un pago
-- Solo permite eliminar pagos que NO estén pagados (EPG-01)
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_eliminar_pago;

DELIMITER $$

CREATE PROCEDURE sp_eliminar_pago(
    IN p_pago_id VARCHAR(10)
)
BEGIN
    DECLARE v_estado VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ELIMINAR PAGO',
                'Procedimiento: sp_eliminar_pago',
                CONCAT('No se pudo eliminar el pago ID: ', p_pago_id));
    END;

    SELECT EstadoPago_ID INTO v_estado FROM Pagos WHERE Pago_ID = p_pago_id;

    IF v_estado = 'EPG-01' THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ELIMINACIÓN NO PERMITIDA',
                'Procedimiento: sp_eliminar_pago',
                CONCAT('El pago ID: ', p_pago_id,
                       ' ya fue pagado y no puede eliminarse.'));
    ELSE
        DELETE FROM Pagos WHERE Pago_ID = p_pago_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'PAGO ELIMINADO', 'Procedimiento: sp_eliminar_pago',
                CONCAT('Pago ID: ', p_pago_id, ' eliminado exitosamente'));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_eliminar_pago('PAG-010');

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 5;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 5;