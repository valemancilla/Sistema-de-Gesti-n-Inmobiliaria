-- ============================================================
-- TRIGGERS - SISTEMA DE GESTIÓN INMOBILIARIA
-- ============================================================

USE inmobiliaria;

DELIMITER $$

-- ============================================================
-- TRIGGER 1: Cambio de estado de una propiedad
-- Registra en auditoriapropiedad cuando EstadoP_ID cambia
-- ============================================================

CREATE TRIGGER trg_after_update_estado_propiedad
AFTER UPDATE ON propiedad
FOR EACH ROW
BEGIN
    IF OLD.EstadoP_ID <> NEW.EstadoP_ID THEN
        INSERT INTO auditoriapropiedad (
            Audit_ID,
            Propiedad_ID,
            Estado_Anterior,
            Estado_Nuevo,
            Fecha_Cambio,
            Usuario_ID,
            Fecha_Hora
        )
        VALUES (
            CONCAT('AUD-', UUID_SHORT()),
            NEW.Propiedad_ID,
            OLD.EstadoP_ID,
            NEW.EstadoP_ID,
            CURDATE(),
            COALESCE(@usuario_actual, 'SISTEMA'),
            NOW()
        );
    END IF;
END$$

-- ============================================================
-- TRIGGER 2: Registro de un nuevo contrato
-- Registra en auditoriacontrato cuando se inserta un contrato
-- ============================================================

CREATE TRIGGER trg_after_insert_contrato
AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
    INSERT INTO auditoriacontrato (
        AuditCon_ID,
        Contrato_ID,
        Evento,
        Fecha_Evento,
        Usuario_ID,
        Fecha_Hora
    )
    VALUES (
        CONCAT('AC-', UUID_SHORT()),
        NEW.Contrato_ID,
        CONCAT(
            'NUEVO CONTRATO | Tipo: ', NEW.Tipo_Contrato,
            ' | Cliente_ID: ', NEW.Cliente_ID,
            ' | Agente_ID: ', NEW.Agente_ID,
            ' | Propiedad_ID: ', NEW.Propiedad_ID
        ),
        NEW.Fecha_Contrato,
        COALESCE(@usuario_actual, 'SISTEMA'),
        NOW()
    );
END$$

DELIMITER ;

-- ============================================================
-- NOTA: La aplicación debe ejecutar antes de operar:
--   SET @usuario_actual = 'USR-001';
-- ============================================================