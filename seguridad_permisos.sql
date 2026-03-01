USE inmobiliaria_db;

-- ============================================================
-- PASO 1: ELIMINAR USUARIOS ANÓNIMOS
-- ============================================================

SET SQL_SAFE_UPDATES = 0;
DELETE FROM mysql.user WHERE User = '';
FLUSH PRIVILEGES;
SET SQL_SAFE_UPDATES = 1;

INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
VALUES (NOW(), 'ELIMINACIÓN USUARIOS ANÓNIMOS', 'mysql.user',
        'Se eliminaron los usuarios anónimos del sistema por seguridad');


-- ============================================================
-- PASO 2: PROCEDIMIENTO — Crear los 4 usuarios
-- ============================================================

DROP PROCEDURE IF EXISTS sp_crear_usuarios;

DELIMITER $$

CREATE PROCEDURE sp_crear_usuarios()
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
            'ERROR AL CREAR USUARIOS',
            'Procedimiento: sp_crear_usuarios',
            'Ocurrió un error al intentar crear los usuarios del sistema'
        );
    END;

    -- Eliminar usuarios si ya existen
    DROP USER IF EXISTS 'admin_inmobiliaria'@'localhost';
    DROP USER IF EXISTS 'agente_inmobiliario'@'localhost';
    DROP USER IF EXISTS 'contador_inmobiliaria'@'localhost';
    DROP USER IF EXISTS 'cliente_inmobiliaria'@'localhost';

    -- Crear los 4 usuarios
    CREATE USER 'admin_inmobiliaria'@'localhost'    IDENTIFIED BY 'Admin#Inmo2024';
    CREATE USER 'agente_inmobiliario'@'localhost'   IDENTIFIED BY 'Agente#Inmo2024';
    CREATE USER 'contador_inmobiliaria'@'localhost' IDENTIFIED BY 'Contador#Inmo2024';
    CREATE USER 'cliente_inmobiliaria'@'localhost'  IDENTIFIED BY 'Cliente#Inmo2024';

    -- Registrar en logs_cambios si todo salió bien
    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'CREACIÓN DE USUARIOS', 'sp_crear_usuarios',
            'Usuarios creados: admin_inmobiliaria, agente_inmobiliario, contador_inmobiliaria, cliente_inmobiliaria');

END$$

DELIMITER ;

-- Ejecutar el procedimiento
CALL sp_crear_usuarios();


-- ============================================================
-- PASO 3: PROCEDIMIENTO — Privilegios Administrador
-- ============================================================

DROP PROCEDURE IF EXISTS sp_privilegios_admin;

DELIMITER $$

CREATE PROCEDURE sp_privilegios_admin()
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
            'ERROR AL ASIGNAR PRIVILEGIOS ADMINISTRADOR',
            'Procedimiento: sp_privilegios_admin',
            'Falló la asignación de ALL PRIVILEGES a admin_inmobiliaria'
        );
    END;

    GRANT ALL PRIVILEGES ON inmobiliaria_db.*
    TO 'admin_inmobiliaria'@'localhost'
    WITH GRANT OPTION;

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PRIVILEGIOS ADMINISTRADOR', 'inmobiliaria_db.*',
            'admin_inmobiliaria: ALL PRIVILEGES + WITH GRANT OPTION');

END$$

DELIMITER ;

CALL sp_privilegios_admin();


-- ============================================================
-- PASO 4: PROCEDIMIENTO — Privilegios Agente Inmobiliario
-- Gestiona propiedades, contratos y clientes
-- No tiene acceso a pagos, reportes ni logs
-- ============================================================

DROP PROCEDURE IF EXISTS sp_privilegios_agente;

DELIMITER $$

CREATE PROCEDURE sp_privilegios_agente()
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
            'ERROR AL ASIGNAR PRIVILEGIOS AGENTE INMOBILIARIO',
            'Procedimiento: sp_privilegios_agente',
            'Falló la asignación de privilegios a agente_inmobiliario'
        );
    END;

    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.propiedad        TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.contratos        TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.contratoventa    TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.contratoarriendo TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.clientes         TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.personas         TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.agentes          TO 'agente_inmobiliario'@'localhost';

    -- Tablas de catálogo: solo consulta
    GRANT SELECT ON inmobiliaria_db.tipopropiedad   TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT ON inmobiliaria_db.estadopropiedad TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT ON inmobiliaria_db.barrio          TO 'agente_inmobiliario'@'localhost';
    GRANT SELECT ON inmobiliaria_db.ciudad          TO 'agente_inmobiliario'@'localhost';

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PRIVILEGIOS AGENTE INMOBILIARIO', 'inmobiliaria_db.*',
            'agente_inmobiliario: SELECT,INSERT,UPDATE en propiedades, contratos y clientes');

END$$

DELIMITER ;

CALL sp_privilegios_agente();


-- ============================================================
-- PASO 5: PROCEDIMIENTO — Privilegios Contador
-- Solo gestiona pagos y reportes
-- No puede modificar contratos, propiedades ni clientes
-- ============================================================

DROP PROCEDURE IF EXISTS sp_privilegios_contador;

DELIMITER $$

CREATE PROCEDURE sp_privilegios_contador()
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
            'ERROR AL ASIGNAR PRIVILEGIOS CONTADOR',
            'Procedimiento: sp_privilegios_contador',
            'Falló la asignación de privilegios a contador_inmobiliaria'
        );
    END;

    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.pagos        TO 'contador_inmobiliaria'@'localhost';
    GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.reportepagos TO 'contador_inmobiliaria'@'localhost';

    -- Solo consulta para cruzar información contable
    GRANT SELECT ON inmobiliaria_db.estadopago       TO 'contador_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.contratos        TO 'contador_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.contratoarriendo TO 'contador_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.propiedad        TO 'contador_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.clientes         TO 'contador_inmobiliaria'@'localhost';

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PRIVILEGIOS CONTADOR', 'inmobiliaria_db.*',
            'contador_inmobiliaria: SELECT,INSERT,UPDATE solo en pagos y reportepagos');

END$$

DELIMITER ;

CALL sp_privilegios_contador();


-- ============================================================
-- PASO 6: PROCEDIMIENTO — Privilegios Cliente
-- Solo puede consultar propiedades disponibles
-- No puede ver contratos, pagos ni datos de otros clientes
-- Inferido de: "clientes interesados en alquilar o comprar"
-- y ROL-03 Cliente definido en la tabla Rol del modelo
-- ============================================================

DROP PROCEDURE IF EXISTS sp_privilegios_cliente;

DELIMITER $$

CREATE PROCEDURE sp_privilegios_cliente()
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
            'ERROR AL ASIGNAR PRIVILEGIOS CLIENTE',
            'Procedimiento: sp_privilegios_cliente',
            'Falló la asignación de privilegios a cliente_inmobiliaria'
        );
    END;

    -- Solo puede consultar propiedades y su ubicación
    GRANT SELECT ON inmobiliaria_db.propiedad        TO 'cliente_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.tipopropiedad    TO 'cliente_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.estadopropiedad  TO 'cliente_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.barrio           TO 'cliente_inmobiliaria'@'localhost';
    GRANT SELECT ON inmobiliaria_db.ciudad           TO 'cliente_inmobiliaria'@'localhost';

    INSERT INTO logs_cambios (Fecha_Cambio, Nombre_Cambio, Lugar_Cambio, Descripcion)
    VALUES (NOW(), 'PRIVILEGIOS CLIENTE', 'inmobiliaria_db.*',
            'cliente_inmobiliaria: SELECT solo en propiedad, tipopropiedad, estadopropiedad, barrio y ciudad');

END$$

DELIMITER ;

CALL sp_privilegios_cliente();


-- ============================================================
-- PASO 7: APLICAR CAMBIOS
-- ============================================================

FLUSH PRIVILEGES;


-- ============================================================
-- PASO 8: VERIFICAR PRIVILEGIOS
-- ============================================================

SHOW GRANTS FOR 'admin_inmobiliaria'@'localhost';
SHOW GRANTS FOR 'agente_inmobiliario'@'localhost';
SHOW GRANTS FOR 'contador_inmobiliaria'@'localhost';
SHOW GRANTS FOR 'cliente_inmobiliaria'@'localhost';


-- ============================================================
-- PASO 9: VERIFICAR LOGS
-- ============================================================

SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC;