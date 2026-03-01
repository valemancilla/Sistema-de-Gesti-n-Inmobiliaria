USE inmobiliaria_db;

-- ============================================================
-- PROCEDIMIENTO 1: sp_eliminar_indices
-- Solo elimina índices — usa CONTINUE HANDLER para ignorar
-- el error si el índice no existe (error 1091)
-- ============================================================

DROP PROCEDURE IF EXISTS sp_eliminar_indices;

DELIMITER $$

CREATE PROCEDURE sp_eliminar_indices()
BEGIN
    -- Ignora si el índice no existe al intentar eliminarlo
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    DROP INDEX idx_contratos_tipo            ON contratos;
    DROP INDEX idx_contratos_cliente         ON contratos;
    DROP INDEX idx_contratos_propiedad       ON contratos;
    DROP INDEX idx_contratos_agente          ON contratos;

    DROP INDEX idx_pagos_contrato            ON pagos;
    DROP INDEX idx_pagos_estado              ON pagos;
    DROP INDEX idx_pagos_fecha               ON pagos;

    DROP INDEX idx_propiedad_estado          ON propiedad;
    DROP INDEX idx_propiedad_tipo            ON propiedad;

    DROP INDEX idx_reportepagos_contrato     ON reportepagos;
    DROP INDEX idx_reportepagos_periodo      ON reportepagos;

    DROP INDEX idx_contratoarriendo_contrato ON contratoarriendo;

END$$

DELIMITER ;

-- Ejecutar solo este procedimiento
CALL sp_eliminar_indices();