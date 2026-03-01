USE inmobiliaria_db;

-- ============================================================
-- TRIGGER 4: Validación de disponibilidad antes de crear contrato
-- Verifica que la propiedad esté en estado Disponible (EP-01)
-- antes de permitir el INSERT en contratos.
-- Si no está disponible cancela la operación con SIGNAL
-- y registra el intento en logs_errores
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_before_insert_contrato_disponibilidad
BEFORE INSERT ON contratos
FOR EACH ROW
BEGIN
    DECLARE v_estado_propiedad VARCHAR(10);

    -- Manejador de errores: si algo falla, registra en logs_errores
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
            'ERROR EN TRIGGER: trg_before_insert_contrato_disponibilidad',
            'Tabla: contratos | Trigger: BEFORE INSERT',
            CONCAT('Contrato_ID: ', NEW.Contrato_ID,
                   ' | Propiedad_ID: ', NEW.Propiedad_ID)
        );
    END;

    -- Obtener el estado actual de la propiedad
    SELECT EstadoP_ID
    INTO   v_estado_propiedad
    FROM   Propiedad
    WHERE  Propiedad_ID = NEW.Propiedad_ID;

    -- Si la propiedad NO está disponible, cancelar el INSERT
    IF v_estado_propiedad <> 'EP-01' THEN

        INSERT INTO logs_errores (
            Fecha_Error,
            Nombre_Error,
            Lugar_Error,
            Detalle
        )
        VALUES (
            NOW(),
            'CONTRATO RECHAZADO — PROPIEDAD NO DISPONIBLE',
            'Tabla: contratos | Trigger: trg_before_insert_contrato_disponibilidad',
            CONCAT('Contrato_ID: ', NEW.Contrato_ID,
                   ' | Propiedad_ID: ', NEW.Propiedad_ID,
                   ' | Estado actual: ', v_estado_propiedad,
                   ' | Se requiere EP-01 (Disponible)')
        );

        -- Cancelar el INSERT con error personalizado
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede crear el contrato: la propiedad no está disponible.';

    END IF;

END$$

DELIMITER ;

-- ============================================================
-- NOTA: La aplicación debe ejecutar antes de operar:
--   SET @usuario_actual = 'USR-001';
-- ============================================================

-- ============================================================
-- Ejemplo de prueba: intentar crear contrato sobre
-- propiedad ya arrendada (PROP-01 está en EP-02)
-- Debe fallar y registrar en logs_errores
-- ============================================================
INSERT INTO Contratos (Contrato_ID, Fecha_Contrato, Tipo_Contrato, Cliente_ID, Agente_ID, Propiedad_ID)
VALUES ('CON-TEST', '2025-01-01', 'Arriendo', 'CLI-01', 'AGE-01', 'PROP-01');

-- Ver el error registrado
SELECT * FROM logs_errores ORDER BY Log_ID DESC LIMIT 1;