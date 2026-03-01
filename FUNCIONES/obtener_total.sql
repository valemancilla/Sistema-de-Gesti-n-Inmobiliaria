USE inmobiliaria_db;

-- ================================================================
-- CONFIGURACIÓN PREVIA
-- ================================================================
SET GLOBAL log_bin_trust_function_creators = 1;


-- ================================================================
-- FUNCIÓN 3: total_disponibles_por_tipo
-- Cuenta propiedades disponibles por tipo
-- Registra en logs_cambios la consulta realizada
-- Registra en logs_errores si ocurre un fallo
-- ================================================================
DROP FUNCTION IF EXISTS total_disponibles_por_tipo;

DELIMITER $$

CREATE FUNCTION total_disponibles_por_tipo(p_tipo_id VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    -- Manejador de errores
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
            'ERROR EN FUNCIÓN: total_disponibles_por_tipo',
            'Función: total_disponibles_por_tipo',
            CONCAT('Parámetro recibido — TipoP_ID: ', COALESCE(p_tipo_id, 'NULL'))
        );
        RETURN NULL;
    END;

    -- Contar propiedades disponibles del tipo indicado
    SELECT COUNT(*)
    INTO   v_total
    FROM   propiedad p
    WHERE  p.TipoP_ID   = p_tipo_id
      AND  p.EstadoP_ID = 'EP-01';   -- EP-01 = Disponible

    -- Registrar en logs_cambios
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'CONSULTA PROPIEDADES DISPONIBLES',
        'Función: total_disponibles_por_tipo',
        CONCAT('TipoP_ID consultado: ', p_tipo_id,
               ' | Total disponibles encontradas: ', v_total)
    );

    RETURN v_total;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT total_disponibles_por_tipo('TP-01');
SELECT total_disponibles_por_tipo('TP-02');

-- ================================================================
-- CONSULTA RESUMEN — propiedades disponibles por tipo
-- ================================================================
SELECT
    tp.Descripcion                            AS tipo_propiedad,
    total_disponibles_por_tipo(tp.TipoP_ID)   AS disponibles
FROM tipopropiedad tp;