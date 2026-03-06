

USE inmobiliaria_db;

-- ================================================================
-- CONSULTA 1: Precio promedio, máximo y mínimo de propiedades 
--              agrupadas por ciudad.
-- ================================================================
-- Utiliza: AVG, MAX, MIN, GROUP BY
-- ================================================================

SELECT 
    c.Nombre_Ciudad AS Ciudad,
    ROUND(AVG(p.Precio_Propiedad), 2) AS Precio_Promedio,
    MAX(p.Precio_Propiedad) AS Precio_Maximo,
    MIN(p.Precio_Propiedad) AS Precio_Minimo
FROM Propiedad p
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
GROUP BY c.Ciudad_ID, c.Nombre_Ciudad
ORDER BY c.Nombre_Ciudad;


-- ================================================================
-- CONSULTA 2: Listar las propiedades disponibles para arriendo 
--             cuyo precio esté entre 800000 y 2000000.
-- ================================================================
-- Utiliza: BETWEEN, WHERE, AND
-- ================================================================

SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    ep.Descripcion AS Estado,
    b.Nombre_Barrio AS Barrio,
    c.Nombre_Ciudad AS Ciudad
FROM Propiedad p
INNER JOIN EstadoPropiedad ep ON p.EstadoP_ID = ep.EstadoP_ID
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
WHERE p.EstadoP_ID = 'EP-01' 
  AND p.Precio_Propiedad BETWEEN 800000 AND 2000000
ORDER BY p.Precio_Propiedad;


-- ================================================================
-- CONSULTA 3: Mostrar las propiedades que incluyen la palabra 
--             "Parque" en su dirección.
-- ================================================================
-- Utiliza: LIKE '%Parque%'
-- ================================================================

SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    tp.Descripcion AS Tipo_Propiedad,
    ep.Descripcion AS Estado,
    b.Nombre_Barrio AS Barrio,
    c.Nombre_Ciudad AS Ciudad
FROM Propiedad p
INNER JOIN TipoPropiedad tp ON p.TipoP_ID = tp.TipoP_ID
INNER JOIN EstadoPropiedad ep ON p.EstadoP_ID = ep.EstadoP_ID
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
WHERE p.Direccion LIKE '%Parque%';


-- ================================================================
-- CONSULTA 4: Listar el nombre del agente inmobiliario, la cantidad 
--             de propiedades que administra y la ciudad principal 
--             donde las tiene.
-- ================================================================
-- Utiliza: JOIN, GROUP BY, ORDER BY
-- ================================================================

SELECT 
    per.Nombre AS Nombre_Agente,
    per.Apellido AS Apellido_Agente,
    COUNT(p.Propiedad_ID) AS Cantidad_Propiedades,
    c.Nombre_Ciudad AS Ciudad_Principal
FROM Agentes age
INNER JOIN Personas per ON age.Persona_ID = per.Persona_ID
INNER JOIN Contratos con ON age.Agente_ID = con.Agente_ID
INNER JOIN Propiedad p ON con.Propiedad_ID = p.Propiedad_ID
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
GROUP BY age.Agente_ID, per.Nombre, per.Apellido, c.Nombre_Ciudad
ORDER BY Cantidad_Propiedades DESC, c.Nombre_Ciudad;


-- ================================================================
-- CONSULTA 5: Obtener las 5 propiedades más costosas y su 
--             respectivo cliente si ya fueron arrendadas.
-- ================================================================
-- Utiliza: JOIN, ORDER BY DESC, LIMIT 5
-- ================================================================

SELECT 
    p.Propiedad_ID,
    p.Direccion,
    p.Precio_Propiedad,
    con.Tipo_Contrato,
    per_cli.Nombre AS Nombre_Cliente,
    per_cli.Apellido AS Apellido_Cliente,
    per_cli.Email AS Email_Cliente,
    con.Fecha_Contrato
FROM Propiedad p
INNER JOIN Contratos con ON p.Propiedad_ID = con.Propiedad_ID
INNER JOIN Clientes cli ON con.Cliente_ID = cli.Cliente_ID
INNER JOIN Personas per_cli ON cli.Persona_ID = per_cli.Persona_ID
WHERE con.Tipo_Contrato = 'Arriendo'
ORDER BY p.Precio_Propiedad DESC
LIMIT 5;


-- ================================================================
-- VISTA 1: vista_propiedades_por_ciudad
-- Muestra propiedades agrupadas por ciudad con precio promedio
-- Uso: Consulta de inventario por ubicación geográfica
-- ================================================================

DROP VIEW IF EXISTS vista_propiedades_por_ciudad;

CREATE VIEW vista_propiedades_por_ciudad AS
SELECT 
    c.Nombre_Ciudad AS ciudad,
    c.Departamento AS departamento,
    COUNT(p.Propiedad_ID) AS total_propiedades,
    ROUND(AVG(p.Precio_Propiedad), 2) AS precio_promedio,
    MAX(p.Precio_Propiedad) AS precio_maximo,
    MIN(p.Precio_Propiedad) AS precio_minimo
FROM Propiedad p
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
GROUP BY c.Ciudad_ID, c.Nombre_Ciudad, c.Departamento;


-- ================================================================
-- VISTA 2: vista_agentes_propiedades
-- Muestra información de agentes con propiedades administradas
-- Uso: Reporte de agentes y sus propiedades
-- ================================================================

DROP VIEW IF EXISTS vista_agentes_propiedades;

CREATE VIEW vista_agentes_propiedades AS
SELECT 
    per.Nombre AS nombre_agente,
    per.Apellido AS apellido_agente,
    COUNT(p.Propiedad_ID) AS cantidad_propiedades,
    c.Nombre_Ciudad AS ciudad_principal
FROM Agentes age
INNER JOIN Personas per ON age.Persona_ID = per.Persona_ID
INNER JOIN Contratos con ON age.Agente_ID = con.Agente_ID
INNER JOIN Propiedad p ON con.Propiedad_ID = p.Propiedad_ID
INNER JOIN Barrio b ON p.Barrio_ID = b.Barrio_ID
INNER JOIN Ciudad c ON b.Ciudad_ID = c.Ciudad_ID
GROUP BY age.Agente_ID, per.Nombre, per.Apellido, c.Nombre_Ciudad;


-- ================================================================
-- ÍNDICES DE OPTIMIZACIÓN
-- Índices simples y compuestos para mejorar rendimiento
-- ================================================================

-- Índice compuesto: propiedades por ciudad y estado
CREATE INDEX idx_prop_ciudad_estado 
ON Propiedad (Barrio_ID, EstadoP_ID);

-- Índice compuesto: contratos por tipo y fecha
CREATE INDEX idx_contrato_tipo_fecha 
ON Contratos (Tipo_Contrato, Fecha_Contrato);

-- Índice simple: pagos por contrato
CREATE INDEX idx_pagos_contrato 
ON Pagos (Contrato_ID);

-- Índice simple: propiedades por estado
CREATE INDEX idx_propiedad_estado 
ON Propiedad (EstadoP_ID);





