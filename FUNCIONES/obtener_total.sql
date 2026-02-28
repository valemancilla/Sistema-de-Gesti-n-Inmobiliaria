
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
-- CONSULTAS RESUMEN
-- ================================================================

-- Ver todas las comisiones de ventas
SELECT
    c.Contrato_ID,
    c.Tipo_Contrato,
    CONCAT(p.Nombre, ' ', p.Apellido)   AS agente,
    a.Comision_Pct                      AS pct_comision,
    cv.Precio_Venta                     AS precio_venta,
    calcular_comision(c.Contrato_ID)    AS comision_calculada
FROM  contratos c
JOIN  agentes a          ON a.Agente_ID    = c.Agente_ID
JOIN  personas p         ON p.Persona_ID   = a.Persona_ID
JOIN  contratoventa cv   ON cv.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Venta';

-- Ver deuda por contrato de arriendo
SELECT
    c.Contrato_ID,
    c.Tipo_Contrato,
    CONCAT(pc.Nombre, ' ', pc.Apellido)      AS cliente,
    ca.Valor_Mensual                          AS valor_mensual,
    calcular_deuda_pendiente(c.Contrato_ID)   AS deuda_pendiente
FROM  contratos c
JOIN  clientes cl           ON cl.Cliente_ID  = c.Cliente_ID
JOIN  personas pc           ON pc.Persona_ID  = cl.Persona_ID
JOIN  contratoarriendo ca   ON ca.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Arriendo';

-- Ver disponibles por tipo de propiedad
SELECT
    tp.Descripcion                            AS tipo_propiedad,
    total_disponibles_por_tipo(tp.TipoP_ID)   AS disponibles
FROM tipopropiedad tp;