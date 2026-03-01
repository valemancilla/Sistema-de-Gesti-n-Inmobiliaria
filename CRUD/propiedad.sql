USE inmobiliaria_db;

-- ================================================================
-- CRUD PROPIEDAD
-- "administrar su portafolio de propiedades
--  (casas, apartamentos, locales comerciales)"
-- ================================================================


-- ----------------------------------------------------------------
-- CREATE — Agregar una nueva propiedad al portafolio
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_insertar_propiedad;

DELIMITER $$

CREATE PROCEDURE sp_insertar_propiedad(
    IN p_propiedad_id    VARCHAR(10),
    IN p_direccion       VARCHAR(150),
    IN p_precio          DECIMAL(15,2),
    IN p_tipo_id         VARCHAR(10),
    IN p_estado_id       VARCHAR(10),
    IN p_barrio_id       VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL INSERTAR PROPIEDAD',
                'Procedimiento: sp_insertar_propiedad',
                CONCAT('No se pudo insertar la propiedad ID: ', p_propiedad_id));
    END;

    INSERT INTO Propiedad (Propiedad_ID, Direccion, Precio_Propiedad, TipoP_ID, EstadoP_ID, Barrio_ID)
    VALUES (p_propiedad_id, p_direccion, p_precio, p_tipo_id, p_estado_id, p_barrio_id);

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PROPIEDAD INSERTADA', 'Procedimiento: sp_insertar_propiedad',
            CONCAT('Propiedad ID: ', p_propiedad_id, ' | Dirección: ', p_direccion,
                   ' | Tipo: ', p_tipo_id, ' | Estado: ', p_estado_id));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_insertar_propiedad('PROP-10', 'Cra 15 #30-45', 180000000.00, 'TP-01', 'EP-01', 'BAR-02');


-- ----------------------------------------------------------------
-- READ — Consultar propiedades por estado
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_consultar_propiedades;

DELIMITER $$

CREATE PROCEDURE sp_consultar_propiedades(
    IN p_estado_id VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL CONSULTAR PROPIEDADES',
                'Procedimiento: sp_consultar_propiedades',
                CONCAT('No se pudo consultar propiedades con estado: ', p_estado_id));
    END;

    SELECT
        pr.Propiedad_ID,
        pr.Direccion,
        pr.Precio_Propiedad,
        tp.Descripcion   AS tipo_propiedad,
        ep.Descripcion   AS estado,
        b.Nombre_Barrio  AS barrio,
        ci.Nombre_Ciudad AS ciudad
    FROM Propiedad pr
    JOIN TipoPropiedad   tp ON tp.TipoP_ID   = pr.TipoP_ID
    JOIN EstadoPropiedad ep ON ep.EstadoP_ID = pr.EstadoP_ID
    JOIN Barrio          b  ON b.Barrio_ID   = pr.Barrio_ID
    JOIN Ciudad          ci ON ci.Ciudad_ID  = b.Ciudad_ID
    WHERE pr.EstadoP_ID = p_estado_id;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CONSULTA PROPIEDADES', 'Procedimiento: sp_consultar_propiedades',
            CONCAT('Consulta realizada con estado: ', p_estado_id));
END$$

DELIMITER ;

-- Ejemplo de uso: consultar propiedades disponibles
CALL sp_consultar_propiedades('EP-01');


-- ----------------------------------------------------------------
-- UPDATE — Cambiar el estado de una propiedad
-- (activa el trigger trg_after_update_estado_propiedad)
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_estado_propiedad;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_estado_propiedad(
    IN p_propiedad_id VARCHAR(10),
    IN p_nuevo_estado VARCHAR(10)
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ACTUALIZAR ESTADO PROPIEDAD',
                'Procedimiento: sp_actualizar_estado_propiedad',
                CONCAT('No se pudo actualizar la propiedad ID: ', p_propiedad_id,
                       ' al estado: ', p_nuevo_estado));
    END;

    SELECT COUNT(*) INTO v_existe FROM Propiedad WHERE Propiedad_ID = p_propiedad_id;

    IF v_existe = 0 THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'PROPIEDAD NO ENCONTRADA',
                'Procedimiento: sp_actualizar_estado_propiedad',
                CONCAT('La propiedad ID: ', p_propiedad_id, ' no existe en el sistema'));
    ELSE
        -- El trigger trg_after_update_estado_propiedad registra
        -- automáticamente el cambio en AuditoriaPropiedad
        UPDATE Propiedad SET EstadoP_ID = p_nuevo_estado
        WHERE Propiedad_ID = p_propiedad_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'ESTADO PROPIEDAD ACTUALIZADO',
                'Procedimiento: sp_actualizar_estado_propiedad',
                CONCAT('Propiedad ID: ', p_propiedad_id, ' actualizada al estado: ', p_nuevo_estado));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso: marcar propiedad como arrendada
CALL sp_actualizar_estado_propiedad('PROP-10', 'EP-02');


-- ----------------------------------------------------------------
-- DELETE — Eliminar una propiedad del portafolio
-- Solo permite eliminar si está disponible (EP-01)
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_eliminar_propiedad;

DELIMITER $$

CREATE PROCEDURE sp_eliminar_propiedad(
    IN p_propiedad_id VARCHAR(10)
)
BEGIN
    DECLARE v_estado VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ELIMINAR PROPIEDAD',
                'Procedimiento: sp_eliminar_propiedad',
                CONCAT('No se pudo eliminar la propiedad ID: ', p_propiedad_id,
                       '. Puede tener contratos asociados.'));
    END;

    SELECT EstadoP_ID INTO v_estado FROM Propiedad WHERE Propiedad_ID = p_propiedad_id;

    IF v_estado <> 'EP-01' THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ELIMINACIÓN NO PERMITIDA',
                'Procedimiento: sp_eliminar_propiedad',
                CONCAT('La propiedad ID: ', p_propiedad_id,
                       ' no puede eliminarse. Estado actual: ', v_estado));
    ELSE
        DELETE FROM Propiedad WHERE Propiedad_ID = p_propiedad_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'PROPIEDAD ELIMINADA', 'Procedimiento: sp_eliminar_propiedad',
                CONCAT('Propiedad ID: ', p_propiedad_id, ' eliminada exitosamente'));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_eliminar_propiedad('PROP-10');

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 5;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 5;