-- ================================================================
--  SISTEMA DE GESTIÓN INMOBILIARIA
--  Punto 3 — Funciones Personalizadas (UDFs)
--  Motor: MySQL 8.0+
-- ================================================================

USE inmobiliaria_db;

-- ================================================================
-- CONFIGURACIÓN PREVIA
-- MySQL requiere este flag para permitir la creación de funciones
-- cuando el log binario está activo
-- ================================================================
SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

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
--
-- Ejemplo de uso:
--   SELECT calcular_comision('CON-002');
--   -- Resultado: 9600000.00  (3% de $320.000.000)
-- ================================================================
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
--
-- Ejemplo de uso:
--   SELECT calcular_deuda_pendiente('CON-001');
--   -- Resultado: 800000.00  (PAG-003 pendiente)
--
--   SELECT calcular_deuda_pendiente('CON-005');
--   -- Resultado: 950000.00  (PAG-008 vencido)
-- ================================================================
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
--
-- Ejemplo de uso:
--   SELECT total_disponibles_por_tipo('TP-01');
--   -- Resultado: 1  (solo PROP-05 está Disponible y es Apartamento)
--
--   SELECT total_disponibles_por_tipo('TP-02');
--   -- Resultado: 0  (las 2 casas están Vendidas)
-- ================================================================
CREATE FUNCTION total_disponibles_por_tipo(p_tipo_id VARCHAR(10))
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;

    SELECT COUNT(*)
    INTO   v_total
    FROM   Propiedad p
    WHERE  p.TipoP_ID  = p_tipo_id
      AND  p.EstadoP_ID = 'EP-01';   -- EP-01 = Disponible

    RETURN v_total;
END$$

DELIMITER ;

-- ================================================================
-- VERIFICACIÓN — Consultas de prueba para las 3 funciones
-- Ejecutar después de correr el script de creación completo
-- ================================================================

-- Prueba 1: calcular_comision
-- CON-002: Casa Medellín $320M × 3% (Pedro Gómez) = $9.600.000
-- CON-004: Casa Bogotá   $450M × 3% (Juan Ríos)   = $13.500.000
-- CON-006: Local Barranquilla $280M × 5% (María López) = $14.000.000 ← revisar
-- CON-001: Arriendo → debe retornar NULL
SELECT
    'calcular_comision'             AS funcion,
    'CON-002 (Venta $320M × 3%)'   AS descripcion,
    calcular_comision('CON-002')    AS resultado
UNION ALL
SELECT
    'calcular_comision',
    'CON-004 (Venta $450M × 3%)',
    calcular_comision('CON-004')
UNION ALL
SELECT
    'calcular_comision',
    'CON-006 (Venta $280M × 5%)',
    calcular_comision('CON-006')
UNION ALL
SELECT
    'calcular_comision',
    'CON-001 (Arriendo → NULL)',
    calcular_comision('CON-001');

-- Prueba 2: calcular_deuda_pendiente
-- CON-001: PAG-003 Pendiente $800.000 → deuda: $800.000
-- CON-003: PAG-006 Pendiente $1.200.000 → deuda: $1.200.000
-- CON-005: PAG-008 Vencido $950.000 → deuda: $950.000
-- CON-002: todos Pagados → deuda: $0
SELECT
    'calcular_deuda_pendiente'                  AS funcion,
    'CON-001 (1 pago pendiente)'                AS descripcion,
    calcular_deuda_pendiente('CON-001')         AS resultado
UNION ALL
SELECT
    'calcular_deuda_pendiente',
    'CON-003 (1 pago pendiente)',
    calcular_deuda_pendiente('CON-003')
UNION ALL
SELECT
    'calcular_deuda_pendiente',
    'CON-005 (1 pago vencido)',
    calcular_deuda_pendiente('CON-005')
UNION ALL
SELECT
    'calcular_deuda_pendiente',
    'CON-002 (todo pagado → 0)',
    calcular_deuda_pendiente('CON-002');

-- Prueba 3: total_disponibles_por_tipo
-- TP-01 Apartamento: PROP-05 Disponible → 1
-- TP-02 Casa: PROP-02 Vendida, PROP-04 Vendida → 0
-- TP-03 Local Comercial: PROP-03 Arrendada, PROP-06 Vendida → 0
SELECT
    'total_disponibles_por_tipo'            AS funcion,
    'TP-01 Apartamento'                     AS descripcion,
    total_disponibles_por_tipo('TP-01')     AS resultado
UNION ALL
SELECT
    'total_disponibles_por_tipo',
    'TP-02 Casa',
    total_disponibles_por_tipo('TP-02')
UNION ALL
SELECT
    'total_disponibles_por_tipo',
    'TP-03 Local Comercial',
    total_disponibles_por_tipo('TP-03');

-- ================================================================
-- CONSULTA RESUMEN — Ver todas las comisiones de ventas
-- ================================================================
SELECT
    c.Contrato_ID,
    CONCAT(p.Nombre, ' ', p.Apellido)   AS agente,
    a.Comision_Pct                      AS pct_comision,
    cv.Precio_Venta                     AS precio_venta,
    calcular_comision(c.Contrato_ID)    AS comision_calculada
FROM  Contratos c
JOIN  Agentes a        ON a.Agente_ID   = c.Agente_ID
JOIN  Personas p       ON p.Persona_ID  = a.Persona_ID
JOIN  ContratoVenta cv ON cv.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Venta';

-- ================================================================
-- CONSULTA RESUMEN — Ver deuda por contrato de arriendo
-- ================================================================
SELECT
    c.Contrato_ID,
    CONCAT(pc.Nombre, ' ', pc.Apellido)         AS cliente,
    ca.Valor_Mensual                             AS valor_mensual,
    calcular_deuda_pendiente(c.Contrato_ID)      AS deuda_pendiente
FROM  Contratos c
JOIN  Clientes cl         ON cl.Cliente_ID  = c.Cliente_ID
JOIN  Personas pc         ON pc.Persona_ID  = cl.Persona_ID
JOIN  ContratoArriendo ca ON ca.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Arriendo';