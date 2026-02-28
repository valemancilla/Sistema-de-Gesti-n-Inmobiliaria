USE inmobiliaria_db;

-- ============================================================
-- TRIGGER 1: Cambio de estado de una propiedad
-- Registra en auditoriapropiedad cuando EstadoP_ID cambia
-- Registra en logs_cambios el evento
-- Registra en logs_errores si ocurre un fallo
-- ============================================================

DELIMITER $$

CREATE TRIGGER trg_after_update_estado_propiedad
AFTER UPDATE ON propiedad
FOR EACH ROW
BEGIN
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
            'ERROR EN TRIGGER: trg_after_update_estado_propiedad',
            'Tabla: propiedad | Trigger: AFTER UPDATE',
            CONCAT('Propiedad_ID: ', NEW.Propiedad_ID,
                   ' | Estado anterior: ', OLD.EstadoP_ID,
                   ' | Estado nuevo: ', NEW.EstadoP_ID)
        );
    END;

    -- Solo actúa si el estado realmente cambió
    IF OLD.EstadoP_ID <> NEW.EstadoP_ID THEN

        -- 1. Registrar en tabla de auditoría de propiedad
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

        -- 2. Registrar en logs_cambios
        INSERT INTO logs_cambios (
            Fecha_Cambio,
            Nombre_Cambio,
            Lugar_Cambio,
            Descripcion
        )
        VALUES (
            NOW(),
            'CAMBIO ESTADO PROPIEDAD',
            'Tabla: propiedad | Trigger: trg_after_update_estado_propiedad',
            CONCAT('Propiedad_ID: ', NEW.Propiedad_ID,
                   ' | Estado anterior: ', OLD.EstadoP_ID,
                   ' | Estado nuevo: ', NEW.EstadoP_ID,
                   ' | Usuario: ', COALESCE(@usuario_actual, 'SISTEMA'))
        );

    END IF;
END$$

DELIMITER ;

-- ============================================================
-- NOTA: La aplicación debe ejecutar antes de operar:
--   SET @usuario_actual = 'USR-001';
-- ============================================================