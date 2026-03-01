USE inmobiliaria_db;

-- ================================================================
-- CRUD CLIENTES
-- "clientes interesados en alquilar o comprar"
-- ================================================================


-- ----------------------------------------------------------------
-- CREATE — Registrar un nuevo cliente
-- Inserta primero en Personas luego en Clientes
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_insertar_cliente;

DELIMITER $$

CREATE PROCEDURE sp_insertar_cliente(
    IN p_persona_id  VARCHAR(10),
    IN p_nombre      VARCHAR(80),
    IN p_apellido    VARCHAR(80),
    IN p_telefono    VARCHAR(20),
    IN p_email       VARCHAR(120),
    IN p_cliente_id  VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL INSERTAR CLIENTE',
                'Procedimiento: sp_insertar_cliente',
                CONCAT('No se pudo registrar el cliente: ', p_nombre, ' ', p_apellido));
    END;

    -- Insertar en la superentidad Personas primero
    INSERT INTO Personas (Persona_ID, Nombre, Apellido, Telefono, Email)
    VALUES (p_persona_id, p_nombre, p_apellido, p_telefono, p_email);

    -- Luego registrar como Cliente
    INSERT INTO Clientes (Cliente_ID, Persona_ID)
    VALUES (p_cliente_id, p_persona_id);

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CLIENTE REGISTRADO', 'Procedimiento: sp_insertar_cliente',
            CONCAT('Cliente ID: ', p_cliente_id, ' | Persona: ', p_nombre, ' ', p_apellido,
                   ' | Email: ', p_email));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_insertar_cliente('PER-20', 'Laura', 'Martínez', '315-555-0001', 'laura.m@email.com', 'CLI-10');


-- ----------------------------------------------------------------
-- READ — Consultar todos los clientes con sus datos completos
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_consultar_clientes;

DELIMITER $$

CREATE PROCEDURE sp_consultar_clientes()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL CONSULTAR CLIENTES',
                'Procedimiento: sp_consultar_clientes',
                'No se pudo realizar la consulta de clientes');
    END;

    SELECT
        cl.Cliente_ID,
        p.Nombre,
        p.Apellido,
        p.Telefono,
        p.Email
    FROM Clientes cl
    JOIN Personas p ON p.Persona_ID = cl.Persona_ID
    ORDER BY p.Apellido, p.Nombre;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CONSULTA CLIENTES', 'Procedimiento: sp_consultar_clientes',
            'Consulta de todos los clientes realizada exitosamente');
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_consultar_clientes();


-- ----------------------------------------------------------------
-- UPDATE — Actualizar datos de contacto de un cliente
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_actualizar_cliente;

DELIMITER $$

CREATE PROCEDURE sp_actualizar_cliente(
    IN p_persona_id  VARCHAR(10),
    IN p_telefono    VARCHAR(20),
    IN p_email       VARCHAR(120)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ACTUALIZAR CLIENTE',
                'Procedimiento: sp_actualizar_cliente',
                CONCAT('No se pudo actualizar datos de la persona ID: ', p_persona_id));
    END;

    UPDATE Personas
    SET Telefono = p_telefono, Email = p_email
    WHERE Persona_ID = p_persona_id;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CLIENTE ACTUALIZADO', 'Procedimiento: sp_actualizar_cliente',
            CONCAT('Persona ID: ', p_persona_id, ' | Nuevo teléfono: ', p_telefono,
                   ' | Nuevo email: ', p_email));
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_actualizar_cliente('PER-20', '315-555-9999', 'laura.nueva@email.com');


-- ----------------------------------------------------------------
-- DELETE — Eliminar un cliente
-- Solo permite si no tiene contratos activos
-- ----------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_eliminar_cliente;

DELIMITER $$

CREATE PROCEDURE sp_eliminar_cliente(
    IN p_cliente_id VARCHAR(10)
)
BEGIN
    DECLARE v_contratos  INT DEFAULT 0;
    DECLARE v_persona_id VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ERROR AL ELIMINAR CLIENTE',
                'Procedimiento: sp_eliminar_cliente',
                CONCAT('No se pudo eliminar el cliente ID: ', p_cliente_id));
    END;

    SELECT COUNT(*) INTO v_contratos FROM Contratos WHERE Cliente_ID = p_cliente_id;

    IF v_contratos > 0 THEN
        INSERT INTO logs_errores (Fecha_Error, Nombre_Error, Lugar_Error, Detalle)
        VALUES (NOW(), 'ELIMINACIÓN NO PERMITIDA',
                'Procedimiento: sp_eliminar_cliente',
                CONCAT('El cliente ID: ', p_cliente_id,
                       ' tiene ', v_contratos, ' contrato(s). No se puede eliminar.'));
    ELSE
        SELECT Persona_ID INTO v_persona_id FROM Clientes WHERE Cliente_ID = p_cliente_id;

        DELETE FROM Clientes WHERE Cliente_ID  = p_cliente_id;
        DELETE FROM Personas WHERE Persona_ID  = v_persona_id;

        INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
        VALUES (NOW(), 'CLIENTE ELIMINADO', 'Procedimiento: sp_eliminar_cliente',
                CONCAT('Cliente ID: ', p_cliente_id, ' eliminado exitosamente'));
    END IF;
END$$

DELIMITER ;

-- Ejemplo de uso
CALL sp_eliminar_cliente('CLI-10');

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 5;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 5;