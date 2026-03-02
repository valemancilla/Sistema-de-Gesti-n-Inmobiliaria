USE inmobiliaria_db;

-- ================================================================
-- PARTICIONAMIENTO DE LA TABLA REPORTEPAGOS
-- Tipo: PARTITION BY RANGE (YEAR(Fecha_Reporte))
-- Justificación: ReportePagos es la tabla más adecuada para
-- particionar porque no tiene claves foráneas — MySQL permite
-- particionarla sin sacrificar integridad referencial.
-- Crece mensualmente de forma indefinida con cada ejecución
-- del evento programado, y las consultas siempre filtran
-- por periodo o fecha, haciendo el particionamiento por año
-- directo y eficiente.
-- ================================================================

-- ================================================================
-- PASO 1: Eliminar la tabla existente
-- ================================================================
DROP TABLE IF EXISTS ReportePagos;

-- ================================================================
-- PASO 2: Recrear con particionamiento RANGE por año
-- ================================================================
CREATE TABLE ReportePagos (
    Reporte_ID      VARCHAR(10)   NOT NULL,
    Contrato_ID     VARCHAR(10)   NOT NULL,
    Fecha_Reporte   DATE          NOT NULL,
    Monto_Pendiente DECIMAL(12,2) NOT NULL,
    Descripcion     VARCHAR(200),
    Periodo         VARCHAR(7)    NOT NULL,
    PRIMARY KEY     (Reporte_ID, Fecha_Reporte)
) PARTITION BY RANGE (YEAR(Fecha_Reporte)) (
    PARTITION p2023    VALUES LESS THAN (2024),
    PARTITION p2024    VALUES LESS THAN (2025),
    PARTITION p2025    VALUES LESS THAN (2026),
    PARTITION p2026    VALUES LESS THAN (2027),
    PARTITION p_futuro VALUES LESS THAN MAXVALUE
);

-- ================================================================
-- PASO 3: Reinsertar datos de prueba
-- ================================================================
INSERT INTO ReportePagos (Reporte_ID, Contrato_ID, Fecha_Reporte, Monto_Pendiente, Descripcion, Periodo) VALUES
('REP-001', 'CON-001', '2024-03-01',  800000.00, 'Reporte mensual automático | Contrato: CON-001 | Pagos pendientes/vencidos: 1', '2024-03'),
('REP-002', 'CON-003', '2024-04-01', 1200000.00, 'Reporte mensual automático | Contrato: CON-003 | Pagos pendientes/vencidos: 1', '2024-04'),
('REP-003', 'CON-005', '2024-05-01',  950000.00, 'Reporte mensual automático | Contrato: CON-005 | Pagos pendientes/vencidos: 1', '2024-05');

-- ================================================================
-- VERIFICACIONES FINALES
-- ================================================================

-- Ver cuántas filas hay en cada partición
SELECT
    PARTITION_NAME        AS particion,
    PARTITION_DESCRIPTION AS limite_superior,
    TABLE_ROWS            AS filas
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'inmobiliaria_db'
  AND TABLE_NAME   = 'reportepagos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- Consultar solo los reportes de la partición 2024
SELECT * FROM ReportePagos PARTITION (p2024);