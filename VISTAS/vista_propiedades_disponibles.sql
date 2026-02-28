USE inmobiliaria_db;

-- ================================================================
-- VISTA 3: vista_propiedades_disponibles
-- Muestra todas las propiedades en estado Disponible (EP-01)
-- con su tipo, ubicación completa y precio
-- Diseñada para que agentes y clientes vean el inventario disponible
-- ================================================================

DROP PROCEDURE IF EXISTS sp_crear_vista_propiedades;

DELIMITER $$

CREATE PROCEDURE sp_crear_vista_propiedades()
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
            'ERROR AL CREAR VISTA: vista_propiedades_disponibles',
            'Procedimiento: sp_crear_vista_propiedades',
            'Ocurrió un error al intentar crear la vista vista_propiedades_disponibles'
        );
    END;

    -- Eliminar la vista si ya existe
    DROP VIEW IF EXISTS vista_propiedades_disponibles;

    -- Crear la vista
    CREATE VIEW vista_propiedades_disponibles AS
    SELECT
        pr.Propiedad_ID         AS propiedad_id,
        pr.Direccion            AS direccion,
        tp.Descripcion          AS tipo_propiedad,
        ep.Descripcion          AS estado,
        pr.Precio_Propiedad     AS precio,
        b.Nombre_Barrio         AS barrio,
        ci.Nombre_Ciudad        AS ciudad,
        ci.Departamento         AS departamento
    FROM propiedad pr
    JOIN tipopropiedad   tp ON tp.TipoP_ID   = pr.TipoP_ID
    JOIN estadopropiedad ep ON ep.EstadoP_ID = pr.EstadoP_ID
    JOIN barrio          b  ON b.Barrio_ID   = pr.Barrio_ID
    JOIN ciudad          ci ON ci.Ciudad_ID  = b.Ciudad_ID
    WHERE pr.EstadoP_ID = 'EP-01';

    -- Registrar éxito en logs_cambios
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'VISTA CREADA: vista_propiedades_disponibles',
        'Procedimiento: sp_crear_vista_propiedades',
        'Vista vista_propiedades_disponibles creada exitosamente. Filtra EstadoP_ID = EP-01 (Disponible). Une: propiedad, tipopropiedad, estadopropiedad, barrio, ciudad.'
    );

END$$

DELIMITER ;

-- Ejecutar el procedimiento
CALL sp_crear_vista_propiedades();


-- ================================================================
-- EJEMPLOS DE USO
-- ================================================================

-- Ver todas las propiedades disponibles
SELECT * FROM vista_propiedades_disponibles;

-- Ver solo apartamentos disponibles
SELECT * FROM vista_propiedades_disponibles
WHERE tipo_propiedad = 'Apartamento';

-- Ver propiedades disponibles en Bucaramanga ordenadas por precio
SELECT * FROM vista_propiedades_disponibles
WHERE ciudad = 'Bucaramanga'
ORDER BY precio ASC;

-- Verificar logs
SELECT * FROM logs_cambios ORDER BY Fecha_Cambio DESC LIMIT 3;
SELECT * FROM logs_errores ORDER BY Fecha_Error  DESC LIMIT 3;