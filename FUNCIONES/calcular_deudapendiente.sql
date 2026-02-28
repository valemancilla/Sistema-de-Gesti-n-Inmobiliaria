USE inmobiliaria_db;

-- ================================================================
-- CONFIGURACIÓN PREVIA
-- ================================================================
SET GLOBAL log_bin_trust_function_creators = 1;


-- ================================================================
-- FUNCIÓN 2: calcular_deuda_pendiente
-- Calcula el total de pagos pendientes o vencidos de un contrato
-- Registra en logs_cambios la consulta realizada
-- Registra en logs_errores si ocurre un fallo
-- ================================================================
DROP FUNCTION IF EXISTS calcular_deuda_pendiente;

DELIMITER $$

CREATE FUNCTION calcular_deuda_pendiente(p_contrato_id VARCHAR(10))
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_deuda DECIMAL(12,2) DEFAULT 0.00;

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
            'ERROR EN FUNCIÓN: calcular_deuda_pendiente',
            'Función: calcular_deuda_pendiente',
            CONCAT('Parámetro recibido — Contrato_ID: ', COALESCE(p_contrato_id, 'NULL'))
        );
        RETURN NULL;
    END;

    -- Sumar pagos en estado Pendiente (EPG-02) o Vencido (EPG-03)
    SELECT COALESCE(SUM(p.Monto_Pago), 0.00)
    INTO   v_deuda
    FROM   pagos p
    WHERE  p.Contrato_ID   = p_contrato_id
      AND  p.EstadoPago_ID IN ('EPG-02', 'EPG-03');

    -- Registrar en logs_cambios
    INSERT INTO logs_cambios (
        Fecha_Cambio,
        Nombre_Cambio,
        Lugar_Cambio,
        Descripcion
    )
    VALUES (
        NOW(),
        'CÁLCULO DEUDA PENDIENTE',
        'Función: calcular_deuda_pendiente',
        CONCAT('Contrato_ID: ', p_contrato_id,
               ' | Deuda total pendiente/vencida: $', v_deuda)
    );

    RETURN v_deuda;
END$$

DELIMITER ;

-- Ejemplo de uso:
SELECT calcular_deuda_pendiente('CON-001');
SELECT calcular_deuda_pendiente('CON-005');


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