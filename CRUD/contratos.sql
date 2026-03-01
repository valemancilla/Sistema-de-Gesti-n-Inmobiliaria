USE inmobiliaria_db;

-- ================================================================
-- CRUD CONTRATOS
-- "contratos firmados"
-- ================================================================


-- ----------------------------------------------------------------
-- CREATE — Registrar un nuevo contrato
-- Activa automáticamente:
-- trg_before_insert_contrato_disponibilidad (valida propiedad)
-- trg_after_insert_contrato (registra en AuditoriaContrato)
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_insertar_contrato;

DELIMITER $$

CREATE PROCEDURE sp_insertar_contrato(
    IN p_contrato_id   VARCHAR(10),
    IN p_fecha         DATE,
    IN p_tipo          ENUM('Arriendo','Venta'),
    IN p_cliente_id    VARCHAR(10),
    IN p_agente_id     VARCHAR(10),
    IN p_propiedad_id  VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL INSERTAR CONTRATO',
                'Procedimiento: sp_insertar_contrato',
                CONCAT('No se pudo registrar el contrato ID: ', p_contrato_id,
                       ' | Propiedad: ', p_propiedad_id));
    END;

    INSERT INTO Contratos (Contrato_ID, Fecha_Contrato, Tipo_Contrato, Cliente_ID, Agente_ID, Propiedad_ID)
    VALUES (p_contrato_id, p_fecha, p_tipo, p_cliente_id, p_agente_id, p_propiedad_id);

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CONTRATO REGISTRADO', 'Procedimiento: sp_insertar_contrato',
            CONCAT('Contrato ID: ', p_contrato_id, ' | Tipo: ', p_tipo,
                   ' | Cliente: ', p_cliente_id, ' | Propiedad: ', p_propiedad_id));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_insertar_contrato('CON-010', '2025-03-01', 'Arriendo', 'CLI-01', 'AGE-01', 'PROP-05');


-- ----------------------------------------------------------------
-- READ — Consultar contratos de un cliente específico
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_consultar_contratos_cliente;

DELIMITER $$

CREATE PROCEDURE sp_consultar_contratos_cliente(
    IN p_cliente_id VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL CONSULTAR CONTRATOS',
                'Procedimiento: sp_consultar_contratos_cliente',
                CONCAT('No se pudieron consultar contratos del cliente: ', p_cliente_id));
    END;

    SELECT
        c.Contrato_ID,
        c.Fecha_Contrato,
        c.Tipo_Contrato,
        CONCAT(p.Nombre, ' ', p.Apellido) AS nombre_cliente,
        pr.Direccion                       AS propiedad,
        ep.Descripcion                     AS estado_propiedad
    FROM Contratos c
    JOIN Clientes cl        ON cl.Cliente_ID   = c.Cliente_ID
    JOIN Personas p         ON p.Persona_ID    = cl.Persona_ID
    JOIN Propiedad pr       ON pr.Propiedad_ID = c.Propiedad_ID
    JOIN EstadoPropiedad ep ON ep.EstadoP_ID   = pr.EstadoP_ID
    WHERE c.Cliente_ID = p_cliente_id;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CONSULTA CONTRATOS CLIENTE', 'Procedimiento: sp_consultar_contratos_cliente',
            CONCAT('Consulta de contratos del cliente ID: ', p_cliente_id));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_consultar_contratos_cliente('CLI-01');


-- ----------------------------------------------------------------
-- UPDATE — Actualizar el agente de un contrato
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_agente_contrato;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_agente_contrato(
    IN p_contrato_id  VARCHAR(10),
    IN p_nuevo_agente VARCHAR(10)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ACTUALIZAR CONTRATO',
                'Procedimiento: sp_actualizar_agente_contrato',
                CONCAT('No se pudo actualizar el agente del contrato ID: ', p_contrato_id));
    END;

    SELECT COUNT(*) INTO v_existe FROM Contratos WHERE Contrato_ID = p_contrato_id;

    IF v_existe = 0 THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'CONTRATO NO ENCONTRADO',
                'Procedimiento: sp_actualizar_agente_contrato',
                CONCAT('El contrato ID: ', p_contrato_id, ' no existe en el sistema'));
    ELSE
        UPDATE Contratos SET Agente_ID = p_nuevo_agente WHERE Contrato_ID = p_contrato_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'AGENTE CONTRATO ACTUALIZADO', 'Procedimiento: sp_actualizar_agente_contrato',
                CONCAT('Contrato ID: ', p_contrato_id, ' | Nuevo agente: ', p_nuevo_agente));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_actualizar_agente_contrato('CON-010', 'AGE-02');


-- ----------------------------------------------------------------
-- DELETE — Eliminar un contrato
-- Solo permite si no tiene pagos registrados
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_eliminar_contrato;

DELIMITER $$

CREATE PROCEDURE sp_eliminar_contrato(
    IN p_contrato_id VARCHAR(10)
)
BEGIN
    DECLARE v_pagos INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ELIMINAR CONTRATO',
                'Procedimiento: sp_eliminar_contrato',
                CONCAT('No se pudo eliminar el contrato ID: ', p_contrato_id));
    END;

    SELECT COUNT(*) INTO v_pagos FROM Pagos WHERE Contrato_ID = p_contrato_id;

    IF v_pagos > 0 THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ELIMINACIÓN NO PERMITIDA',
                'Procedimiento: sp_eliminar_contrato',
                CONCAT('El contrato ID: ', p_contrato_id,
                       ' tiene ', v_pagos, ' pago(s) registrado(s). No se puede eliminar.'));
    ELSE
        DELETE FROM Contratos WHERE Contrato_ID = p_contrato_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'CONTRATO ELIMINADO', 'Procedimiento: sp_eliminar_contrato',
                CONCAT('Contrato ID: ', p_contrato_id, ' eliminado exitosamente'));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_eliminar_contrato('CON-010');

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 5;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 5;