USE inmobiliaria_db;

-- ================================================================
-- VISTA 1: vista_contratos_completos
-- Muestra toda la información de un contrato en una sola consulta:
-- datos del contrato, cliente, agente y propiedad
-- ================================================================

DROP VIEW IF EXISTS vista_contratos_completos;

CREATE VIEW vista_contratos_completos AS
SELECT
    c.Contrato_ID                               AS contrato_id,
    c.Fecha_Contrato                            AS fecha_contrato,
    c.Tipo_Contrato                             AS tipo_contrato,
    CONCAT(pc.Nombre, ' ', pc.Apellido)         AS nombre_cliente,
    pc.Telefono                                 AS telefono_cliente,
    pc.Email                                    AS email_cliente,
    CONCAT(pa.Nombre, ' ', pa.Apellido)         AS nombre_agente,
    a.Comision_Pct                              AS comision_agente_pct,
    pr.Direccion                                AS direccion_propiedad,
    pr.Precio_Propiedad                         AS precio_propiedad,
    tp.Descripcion                              AS tipo_propiedad,
    ep.Descripcion                              AS estado_propiedad,
    b.Nombre_Barrio                             AS barrio,
    ci.Nombre_Ciudad                            AS ciudad
FROM contratos c
JOIN clientes cl        ON cl.Cliente_ID   = c.Cliente_ID
JOIN personas pc        ON pc.Persona_ID   = cl.Persona_ID
JOIN agentes a          ON a.Agente_ID     = c.Agente_ID
JOIN personas pa        ON pa.Persona_ID   = a.Persona_ID
JOIN propiedad pr       ON pr.Propiedad_ID = c.Propiedad_ID
JOIN tipopropiedad tp   ON tp.TipoP_ID     = pr.TipoP_ID
JOIN estadopropiedad ep ON ep.EstadoP_ID   = pr.EstadoP_ID
JOIN barrio b           ON b.Barrio_ID     = pr.Barrio_ID
JOIN ciudad ci          ON ci.Ciudad_ID    = b.Ciudad_ID;

-- ================================================================
-- EJEMPLOS DE USO
-- ================================================================

-- Ver todos los contratos completos
SELECT * FROM vista_contratos_completos;

-- Ver solo los contratos de arriendo
SELECT * FROM vista_contratos_completos
WHERE tipo_contrato = 'Arriendo';

-- Ver contratos de una ciudad específica
SELECT * FROM vista_contratos_completos
WHERE ciudad = 'Bucaramanga';