
USE inmobiliaria_db;

-- ================================================================
-- CONFIGURACIÓN PREVIA
-- MySQL requiere este flag para permitir la creación de funciones
-- cuando el log binario está activo
-- ================================================================
SET GLOBAL log_bin_trust_function_creators = 1;


-- ================================================================
-- FUNCIÓN 1: calcular_comision
-- Calcula la comisión que gana un agente en un contrato de venta
--
-- Lógica:
--   Busca el Precio_Venta en ContratoVenta para ese contrato,
--   luego busca el Comision_Pct del agente en Agentes,
--   y retorna: Precio_Venta * (Comision_Pct / 100)
--
-- Parámetro: p_contrato_id — ID del contrato de venta (ej: 'CON-002')
-- Retorna:   DECIMAL(15,2) — monto de la comisión en pesos
--            NULL si el contrato no existe o no es de tipo Venta
-- ================================================================
DROP FUNCTION IF EXISTS calcular_comision;

DELIMITER $$

CREATE FUNCTION calcular_comision(p_contrato_id VARCHAR(10))
RETURNS DECIMAL(15,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_precio_venta  DECIMAL(15,2) DEFAULT 0;
    DECLARE v_comision_pct  DECIMAL(5,2)  DEFAULT 0;
    DECLARE v_agente_id     VARCHAR(10)   DEFAULT NULL;
    DECLARE v_resultado     DECIMAL(15,2) DEFAULT NULL;

    -- Verificar que el contrato existe y es de tipo Venta
    SELECT c.Agente_ID
    INTO   v_agente_id
    FROM   Contratos c
    WHERE  c.Contrato_ID   = p_contrato_id
      AND  c.Tipo_Contrato = 'Venta'
    LIMIT 1;

    -- Si no encontró el contrato o no es Venta, retornar NULL
    IF v_agente_id IS NULL THEN
        RETURN NULL;
    END IF;

    -- Obtener el precio de venta del contrato
    SELECT cv.Precio_Venta
    INTO   v_precio_venta
    FROM   ContratoVenta cv
    WHERE  cv.Contrato_ID = p_contrato_id
    LIMIT 1;

    -- Obtener el porcentaje de comisión del agente
    SELECT a.Comision_Pct
    INTO   v_comision_pct
    FROM   Agentes a
    WHERE  a.Agente_ID = v_agente_id
    LIMIT 1;

    -- Calcular: precio_venta × (comision_pct / 100)
    SET v_resultado = v_precio_venta * (v_comision_pct / 100);

    RETURN v_resultado;
END$$

DELIMITER ;

-- =====================
-- Ejemplo de uso:
-- =====================
SELECT calcular_comision('CON-002');


-- ================================================================
-- FUNCIÓN 2: calcular_deuda_pendiente
-- Calcula el total de dinero pendiente de pago en un contrato
-- de arriendo: suma todos los pagos con estado 'Pendiente' o
-- 'Vencido' para ese contrato
--
-- Lógica:
--   Suma Monto_Pago de todos los registros en Pagos donde
--   Contrato_ID = p_contrato_id y EstadoPago_ID IN ('EPG-02','EPG-03')
--   EPG-02 = Pendiente, EPG-03 = Vencido
--
-- Parámetro: p_contrato_id — ID del contrato de arriendo (ej: 'CON-001')
-- Retorna:   DECIMAL(12,2) — suma total de pagos no saldados
--            0.00 si no hay pagos pendientes
-- ================================================================
DROP FUNCTION IF EXISTS calcular_deuda_pendiente;

DELIMITER $$

CREATE FUNCTION calcular_deuda_pendiente(p_contrato_id VARCHAR(10))
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_deuda DECIMAL(12,2) DEFAULT 0.00;

    -- Sumar todos los pagos en estado Pendiente (EPG-02) o Vencido (EPG-03)
    SELECT COALESCE(SUM(p.Monto_Pago), 0.00)
    INTO   v_deuda
    FROM   Pagos p
    WHERE  p.Contrato_ID   = p_contrato_id
      AND  p.EstadoPago_ID IN ('EPG-02', 'EPG-03');

    RETURN v_deuda;
END$$

DELIMITER ;

-- =====================
-- Ejemplo de uso:
-- =====================
SELECT calcular_deuda_pendiente('CON-001');
SELECT calcular_deuda_pendiente('CON-005');


-- ================================================================
-- FUNCIÓN 3: total_disponibles_por_tipo
-- Cuenta cuántas propiedades están disponibles para un tipo dado
--
-- Lógica:
--   Cuenta registros en Propiedad donde
--   TipoP_ID = p_tipo_id y EstadoP_ID = 'EP-01' (Disponible)
--
-- Parámetro: p_tipo_id — ID del tipo de propiedad
--            'TP-01' = Apartamento
--            'TP-02' = Casa
--            'TP-03' = Local Comercial
-- Retorna:   INT — cantidad de propiedades disponibles de ese tipo
-- ================================================================
DROP FUNCTION IF EXISTS total_disponibles_por_tipo;

DELIMITER $$

CREATE FUNCTION total_disponibles_por_tipo(p_tipo_id VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO   v_total
    FROM   Propiedad p
    WHERE  p.TipoP_ID   = p_tipo_id
      AND  p.EstadoP_ID = 'EP-01';   -- EP-01 = Disponible

    RETURN v_total;
END$$

DELIMITER ;

-- =====================
-- Ejemplo de uso:
-- =====================
SELECT total_disponibles_por_tipo('TP-01');
SELECT total_disponibles_por_tipo('TP-02');


-- ================================================================
-- CONSULTA RESUMEN — Ver todas las comisiones de ventas
-- Muestra: contrato, tipo, agente, porcentaje, precio y comisión
-- ================================================================
SELECT
    c.Contrato_ID,
    c.Tipo_Contrato,
    CONCAT(p.Nombre, ' ', p.Apellido)   AS agente,
    a.Comision_Pct                      AS pct_comision,
    cv.Precio_Venta                     AS precio_venta,
    calcular_comision(c.Contrato_ID)    AS comision_calculada
FROM  Contratos c
JOIN  Agentes a        ON a.Agente_ID    = c.Agente_ID
JOIN  Personas p       ON p.Persona_ID   = a.Persona_ID
JOIN  ContratoVenta cv ON cv.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Venta';

-- ================================================================
-- CONSULTA RESUMEN — Ver deuda por contrato de arriendo
-- Muestra: contrato, tipo, cliente, valor mensual y deuda total
-- ================================================================
SELECT
    c.Contrato_ID,
    c.Tipo_Contrato,
    CONCAT(pc.Nombre, ' ', pc.Apellido)     AS cliente,
    ca.Valor_Mensual                         AS valor_mensual,
    calcular_deuda_pendiente(c.Contrato_ID)  AS deuda_pendiente
FROM  Contratos c
JOIN  Clientes cl         ON cl.Cliente_ID  = c.Cliente_ID
JOIN  Personas pc         ON pc.Persona_ID  = cl.Persona_ID
JOIN  ContratoArriendo ca ON ca.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Arriendo';

-- ================================================================
-- CONSULTA RESUMEN — Ver disponibles por tipo de propiedad
-- Muestra el nombre del tipo en lugar del código
-- ================================================================
SELECT
    tp.Descripcion                           AS tipo_propiedad,
    total_disponibles_por_tipo(tp.TipoP_ID)  AS disponibles
FROM TipoPropiedad tp;