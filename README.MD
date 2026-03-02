# 🏠 INMOBILIARIA DB — Sistema de Gestión Inmobiliaria en MySQL

> Base de datos relacional desarrollada en MySQL 8 para administrar el portafolio de propiedades, clientes, contratos y pagos de una inmobiliaria. El sistema está normalizado hasta 3FN e incluye funciones personalizadas, triggers de auditoría, seguridad por roles, optimización con índices, particionamiento, eventos programados, vistas y operaciones CRUD completas.

---

## 📌 TABLA DE CONTENIDO

1. [Requisitos](#requisitos)
2. [Estructura de Archivos](#estructura-de-archivos)
3. [Instrucciones de Instalación](#instrucciones-de-instalación)
4. [Explicación del Modelo](#explicación-del-modelo)
5. [Componentes del Sistema](#componentes-del-sistema)
6. [Usuarios y Privilegios](#usuarios-y-privilegios)
7. [Ejemplos de Consultas](#ejemplos-de-consultas)
8. [Decisiones de Diseño](#decisiones-de-diseño)

---

## ✅ REQUISITOS

| Requisito | Versión mínima |
|---|---|
| MySQL | 8.0 o superior |
| Cliente MySQL | Workbench, DBeaver o línea de comandos |
| Permisos | Usuario administrador para crear BD y usuarios |

---

## 📁 ESTRUCTURA DE ARCHIVOS

```
inmobiliaria_db/
│
├── 1_creacion_base_datos.sql              # DDL + DML: 20 tablas, PKs, FKs y datos de prueba
│
├── funciones/
│   ├── calcular_comision.sql              # UDF: comisión del agente en una venta
│   ├── calcular_deudapendiente.sql        # UDF: deuda pendiente en contratos de arriendo
│   └── obtener_total.sql                  # UDF: total de propiedades disponibles por tipo
│
├── triggers/
│   ├── validacion_disponibilidad_contrato.sql    # BEFORE INSERT: valida que la propiedad esté disponible
│   ├── Cambio_de_estado_de_una_propiedad.sql     # AFTER UPDATE: audita cambios de estado
│   ├── Registro_de_un_nuevo_contrato.sql         # AFTER INSERT: audita nuevos contratos
│   └── cambio_estado_pagos.sql                   # AFTER UPDATE: audita cambios de estado de pagos
│
├── seguridad/
│   └── seguridad_permisos.sql             # 4 usuarios MySQL con privilegios diferenciados
│
├── optimizacion/
│   ├── sp_eliminar_indices.sql            # Elimina los 12 índices (CONTINUE HANDLER)
│   ├── sp_crear_indices.sql               # Crea los 12 índices (EXIT HANDLER)
│   └── particiones.sql                    # Particionamiento RANGE por año en tabla ReportePagos
│
├── eventos/
│   └── evento_programado_mensual.sql      # Evento automático mensual de pagos pendientes
│
├── vistas/
│   ├── vista_contratos_completos.sql      # Une 9 tablas: contrato + cliente + agente + propiedad
│   ├── vista_pagos_pendientes.sql         # Pagos en estado Pendiente o Vencido
│   └── vista_propiedades_disponibles.sql  # Propiedades en estado Disponible
│
└── crud/
    ├── propiedad.sql                      # CREATE, READ, UPDATE, DELETE de propiedades
    ├── clientes.sql                       # CREATE, READ, UPDATE, DELETE de clientes
    ├── contratos.sql                      # CREATE, READ, UPDATE, DELETE de contratos
    └── pagos.sql                          # CREATE, READ, UPDATE, DELETE de pagos
```

---

## 🚀 INSTRUCCIONES DE INSTALACIÓN

> ⚠️ **MUY IMPORTANTE:** Ejecuta los scripts **estrictamente en este orden**. Cada script depende del anterior. Si se ejecutan en orden incorrecto, algunos fallarán porque las tablas o funciones que necesitan aún no existen.

---

### Paso 1 — Crear la base de datos

```sql
SOURCE 1_creacion_base_datos.sql;
```

Crea `inmobiliaria_db` con las 20 tablas, sus PKs, FKs y los datos de prueba iniciales (6 contratos, 9 pagos, 6 propiedades, 9 personas).

---

### Paso 2 — Crear las funciones UDF

```sql
SOURCE funciones/calcular_comision.sql;
SOURCE funciones/calcular_deudapendiente.sql;
SOURCE funciones/obtener_total.sql;
```

---

### Paso 3 — Crear los triggers

```sql
SOURCE triggers/validacion_disponibilidad_contrato.sql;
SOURCE triggers/Cambio_de_estado_de_una_propiedad.sql;
SOURCE triggers/Registro_de_un_nuevo_contrato.sql;
SOURCE triggers/cambio_estado_pagos.sql;
```

> ⚠️ El trigger `validacion_disponibilidad_contrato` debe crearse primero porque es un BEFORE INSERT. Si se crea después del AFTER INSERT, el orden de ejecución podría ser incorrecto.

---

### Paso 4 — Configurar seguridad y usuarios

```sql
SOURCE seguridad/seguridad_permisos.sql;
```

Crea y configura 4 usuarios MySQL (admin, agente, contador, cliente) con sus respectivos privilegios.

---

### Paso 5 — Crear índices de optimización

```sql
SOURCE optimizacion/sp_eliminar_indices.sql;
SOURCE optimizacion/sp_crear_indices.sql;
```

> El orden es obligatorio: primero eliminar, luego crear. Esto permite re-ejecutar sin errores de índice duplicado.

---

### Paso 6 — Activar el evento programado mensual

```sql
SOURCE eventos/evento_programado_mensual.sql;
```

---

### Paso 7 — Crear las vistas

```sql
SOURCE vistas/vista_contratos_completos.sql;
SOURCE vistas/vista_pagos_pendientes.sql;
SOURCE vistas/vista_propiedades_disponibles.sql;
```

---

### Paso 8 — Cargar los procedimientos CRUD

```sql
SOURCE crud/propiedad.sql;
SOURCE crud/clientes.sql;
SOURCE crud/contratos.sql;
SOURCE crud/pagos.sql;
```

---

### Paso 9 — Particionamiento (optimización avanzada)

```sql
SOURCE optimizacion/particiones.sql;
```

> ⚠️ Este script **elimina y recrea** la tabla `Pagos` con particionamiento RANGE por año. Las FK de Pagos se pierden por limitación de MySQL en tablas particionadas. Ejecutar solo si se desea esta optimización avanzada.

---

## 🗂️ EXPLICACIÓN DEL MODELO

El modelo parte de una **tabla sin normalizar de 27 columnas** con todo mezclado y llega a **20 tablas en 3FN**, organizadas en 7 grupos funcionales.

---

### Grupo 1 — Catálogos Base
> Son listas de valores válidos y controlados. Se crean primero porque todas las demás tablas los referencian.

| Tabla | Descripción |
|---|---|
| `Ciudad` | Ciudades donde opera la inmobiliaria |
| `Barrio` | Barrios por ciudad |
| `TipoPropiedad` | Apartamento, Casa, Local Comercial |
| `EstadoPropiedad` | Disponible, Arrendada, Vendida |
| `EstadoPago` | Pagado, Pendiente, Vencido |
| `Rol` | Administrador, Agente, Cliente, Contador |

---

### Grupo 2 — Personas
> Superentidad centralizada. Evita duplicar datos personales en múltiples tablas.

| Tabla | Descripción |
|---|---|
| `Personas` | Datos personales de cualquier persona del sistema |
| `Clientes` | Personas que son clientes de la inmobiliaria |
| `Agentes` | Personas que son agentes, con su porcentaje de comisión |
| `UsuarioSistema` | Cuentas de acceso vinculadas a personas y roles |

---

### Grupo 3 — Propiedades

| Tabla | Descripción |
|---|---|
| `Propiedad` | Inventario de propiedades con tipo, estado y ubicación |

---

### Grupo 4 — Contratos
> Patrón de especialización para eliminar columnas N/A entre arriendos y ventas.

| Tabla | Descripción |
|---|---|
| `Contratos` | Datos comunes a cualquier contrato (fecha, cliente, agente, propiedad) |
| `ContratoArriendo` | Datos exclusivos de arriendo: valor mensual, fecha inicio y fin |
| `ContratoVenta` | Datos exclusivos de venta: precio, comisión y fecha de escritura |

---

### Grupo 5 — Pagos

| Tabla | Descripción |
|---|---|
| `Pagos` | Historial de pagos individuales por contrato. |

---

### Grupo 6 — Auditoría y Reportes
> Tablas destino de los triggers y del evento programado.

| Tabla | Descripción |
|---|---|
| `AuditoriaPropiedad` | Historial automático de cambios de estado de propiedades |
| `AuditoriaContrato` | Historial automático de creación de contratos |
| `ReportePagos` | Reportes mensuales automáticos de pagos pendientes |

---

### Grupo 7 — Logs de Infraestructura
> Sin FK hacia otras tablas. Funcionan de forma autónoma e incondicional.

| Tabla | Descripción |
|---|---|
| `Logs_Errores` | Registro automático de errores del sistema |
| `Logs_Cambios` | Registro automático de operaciones exitosas |

---

## ⚙️ COMPONENTES DEL SISTEMA

| Componente | Cantidad | Detalle |
|---|---|---|
| Tablas | 20 | Normalizadas hasta 3FN |
| Funciones UDF | 3 | Cálculos de negocio: comisión, deuda, disponibles |
| Triggers | 4 | 2 obligatorios + 2 inferidos |
| Usuarios MySQL | 4 | Con privilegios diferenciados por rol |
| Índices | 12 | En las tablas más consultadas |
| Evento programado | 1 | Reporte mensual automático |
| Vistas | 3 | Interfaz simplificada para consultas |
| Procedimientos CRUD | 16 | 4 operaciones × 4 entidades principales |
| Particiones | 5 | RANGE por año en tabla ReportePagos |

---

## 👥 USUARIOS Y PRIVILEGIOS

| Usuario MySQL | Rol | Privilegios |
|---|---|---|
| `admin_inmobiliaria` | Administrador | ALL PRIVILEGES + WITH GRANT OPTION |
| `agente_inmobiliario` | Agente | SELECT, INSERT, UPDATE en propiedades, contratos y clientes |
| `contador_inmobiliaria` | Contador | SELECT, INSERT, UPDATE en pagos y reportes |
| `cliente_inmobiliaria` | Cliente | SELECT en propiedades disponibles |

**Contraseñas:**

| Usuario | Contraseña |
|---|---|
| admin_inmobiliaria | `Admin#Inmo2024` |
| agente_inmobiliario | `Agente#Inmo2024` |
| contador_inmobiliaria | `Contador#Inmo2024` |
| cliente_inmobiliaria | `Cliente#Inmo2024` |

---

## 🔍 EJEMPLOS DE CONSULTAS

### Consultas con vistas

```sql
-- Ver todas las propiedades disponibles
SELECT * FROM vista_propiedades_disponibles;

-- Filtrar por tipo de propiedad
SELECT * FROM vista_propiedades_disponibles
WHERE tipo_propiedad = 'Apartamento';

-- Propiedades disponibles ordenadas por precio
SELECT * FROM vista_propiedades_disponibles
WHERE ciudad = 'Bucaramanga'
ORDER BY precio ASC;

-- Ver todos los contratos con información completa
SELECT * FROM vista_contratos_completos;

-- Ver solo contratos de arriendo
SELECT * FROM vista_contratos_completos
WHERE tipo_contrato = 'Arriendo';

-- Ver pagos pendientes y vencidos
SELECT * FROM vista_pagos_pendientes;

-- Deuda total por cliente
SELECT nombre_cliente, SUM(monto_pendiente) AS deuda_total
FROM vista_pagos_pendientes
GROUP BY nombre_cliente
ORDER BY deuda_total DESC;
```

---

### Consultas con funciones UDF

```sql
-- Calcular comisión de un agente para una venta específica
SELECT calcular_comision('CON-002');

-- Ver comisiones de todas las ventas
SELECT
    c.Contrato_ID,
    CONCAT(p.Nombre, ' ', p.Apellido)  AS agente,
    cv.Precio_Venta,
    calcular_comision(c.Contrato_ID)   AS comision_calculada
FROM contratos c
JOIN agentes a        ON a.Agente_ID    = c.Agente_ID
JOIN personas p       ON p.Persona_ID   = a.Persona_ID
JOIN contratoventa cv ON cv.Contrato_ID = c.Contrato_ID
WHERE c.Tipo_Contrato = 'Venta';

-- Calcular deuda pendiente de un contrato de arriendo
SELECT calcular_deuda_pendiente('CON-001');

-- Deuda pendiente de todos los arriendos
SELECT
    c.Contrato_ID,
    CONCAT(pc.Nombre, ' ', pc.Apellido)     AS cliente,
    calcular_deuda_pendiente(c.Contrato_ID)  AS deuda_pendiente
FROM contratos c
JOIN clientes cl         ON cl.Cliente_ID  = c.Cliente_ID
JOIN personas pc         ON pc.Persona_ID  = cl.Persona_ID
WHERE c.Tipo_Contrato = 'Arriendo';

-- Propiedades disponibles por tipo
SELECT
    tp.Descripcion                            AS tipo_propiedad,
    total_disponibles_por_tipo(tp.TipoP_ID)   AS disponibles
FROM tipopropiedad tp;
```

---

### Consultas con procedimientos CRUD

```sql
-- Registrar una nueva propiedad
CALL sp_insertar_propiedad('PROP-10', 'Cra 15 #30-45', 180000000.00, 'TP-01', 'EP-01', 'BAR-02');

-- Cambiar estado de una propiedad (activa trigger de auditoría automáticamente)
SET @usuario_actual = 'USR-01';
CALL sp_actualizar_estado_propiedad('PROP-10', 'EP-02');

-- Registrar un nuevo cliente
CALL sp_insertar_cliente('PER-20', 'Laura', 'Martínez', '315-555-0001', 'laura.m@email.com', 'CLI-10');

-- Registrar un nuevo contrato (activa triggers de validación y auditoría)
SET @usuario_actual = 'USR-01';
CALL sp_insertar_contrato('CON-010', '2025-03-01', 'Arriendo', 'CLI-01', 'AGE-01', 'PROP-05');

-- Registrar un pago
CALL sp_insertar_pago('PAG-010', 'CON-001', '2025-03-15', 800000.00, 'EPG-02');

-- Marcar un pago como pagado (activa trigger de auditoría de pagos)
SET @usuario_actual = 'USR-04';
CALL sp_actualizar_estado_pago('PAG-010', 'EPG-01');
```

---

### Consultas de auditoría y logs

```sql
-- Historial de cambios de estado de propiedades
SELECT * FROM AuditoriaPropiedad ORDER BY Fecha_Hora DESC;

-- Historial de contratos creados
SELECT * FROM AuditoriaContrato ORDER BY Fecha_Hora DESC;

-- Últimos errores del sistema
SELECT * FROM Logs_Errores ORDER BY Fecha_Error DESC LIMIT 10;

-- Últimas operaciones exitosas
SELECT * FROM Logs_Cambios ORDER BY Fecha_Cambio DESC LIMIT 10;

-- Reportes mensuales generados por el evento
SELECT * FROM ReportePagos ORDER BY Periodo DESC;
```

---

### Consultas de verificación del sistema

```sql
-- Verificar triggers activos
SHOW TRIGGERS FROM inmobiliaria_db;

-- Verificar funciones creadas
SHOW FUNCTION STATUS WHERE Db = 'inmobiliaria_db';

-- Verificar evento activo
SHOW EVENTS FROM inmobiliaria_db;

-- Verificar índices
SHOW INDEX FROM contratos;

SHOW INDEX FROM propiedad;

-- Verificar particiones de Pagos
SELECT PARTITION_NAME, PARTITION_DESCRIPTION, TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'inmobiliaria_db'
  AND TABLE_NAME   = 'reportepagos'
ORDER BY PARTITION_ORDINAL_POSITION;

-- Verificar privilegios de usuarios
SHOW GRANTS FOR 'admin_inmobiliaria'@'localhost';
SHOW GRANTS FOR 'agente_inmobiliario'@'localhost';
SHOW GRANTS FOR 'contador_inmobiliaria'@'localhost';
SHOW GRANTS FOR 'cliente_inmobiliaria'@'localhost';
```

---

## 🧠 DECISIONES DE DISEÑO

### Contexto

Una inmobiliaria maneja diariamente información crítica: propiedades, clientes, agentes, contratos y pagos. Si esa información se almacena de forma desordenada, redundante o inconsistente, el negocio enfrenta riesgos reales: cobros duplicados, estados de propiedad incorrectos, comisiones mal calculadas o contratos sin trazabilidad.

Este modelo partió de una **tabla sin normalizar con 27 columnas** que mezclaba todo en una sola estructura, y fue llevado paso a paso hasta la **Tercera Forma Normal**, resultando en 20 tablas organizadas, cada una con una responsabilidad clara y sin redundancia de datos.

---

### 🔴 Primera Forma Normal (1FN) — Atomicidad de los datos

**Problema:** La tabla original almacenaba múltiples pagos de un contrato en una sola celda separados por comas:

```
Fechas_Pagos  → "2024-01-15, 2024-02-15, 2024-03-15"
Montos_Pagos  → "$800.000, $800.000, $800.000"
Estados_Pagos → "Pagado, Pagado, Pendiente"
```

**Solución:** Cada pago pasó a tener su propia fila con un `Pago_ID` único. El campo `Nombre_Cliente` se separó en `Nombre` y `Apellido`.

**Resultado:** El sistema puede consultar, filtrar y reportar cada pago individualmente. El contador puede marcar un pago como pagado sin afectar los demás.

---

### 🟡 Segunda Forma Normal (2FN) — Eliminar dependencias parciales

**Problema:** Con clave primaria compuesta `Contrato_ID + Pago_ID`, columnas como `Nombre_Cliente`, `Tel_Agente` y `Direccion_Propiedad` dependían solo del `Contrato_ID`. Eso es una dependencia parcial. El contrato CON-001 con 3 pagos repetía los datos del cliente en 3 filas idénticas.

**Solución:** Se crearon tablas independientes: `Personas`, `Clientes`, `Agentes`, `Rol` y `UsuarioSistema`. Los datos personales viven una sola vez en `Personas` y todas las demás tablas los referencian con FK.

**Resultado:** Si un cliente cambia su correo, se modifica en un solo registro y todos sus contratos lo reflejan automáticamente.

---

### 🟢 Tercera Forma Normal (3FN) — Eliminar dependencias transitivas

**Problema:** Existían cadenas de dependencias indirectas:

- `Contrato → Propiedad → Ciudad → Barrio` — la ciudad no pertenece al contrato
- `Propiedad → TipoPropiedad` — "Apartamento" es una categoría, no un dato de la propiedad
- `Pago → EstadoPago` — "Pagado" es un valor de catálogo, no un dato libre

Además, contratos de Venta tenían `N/A` en columnas de arriendo y viceversa.

**Solución:** Se crearon catálogos controlados (`Ciudad`, `Barrio`, `TipoPropiedad`, `EstadoPropiedad`, `EstadoPago`, `Rol`) y se implementó especialización de contratos: tabla base `Contratos` + tablas especializadas `ContratoArriendo` y `ContratoVenta`.

**Resultado:** Los catálogos eliminan errores de digitación. La especialización elimina columnas vacías y hace el modelo honesto: un arriendo no tiene precio de escritura porque ese concepto no aplica.

---

### 🔵 Tablas de Auditoría

`AuditoriaPropiedad` y `AuditoriaContrato` son las tablas destino de los triggers. Cada cambio de estado de una propiedad o cada nuevo contrato se registra automáticamente con el estado anterior, el estado nuevo, la fecha exacta y el usuario responsable. Nadie escribe aquí manualmente — solo los triggers.

`ReportePagos` es la tabla destino del evento mensual. Su campo `Periodo` en formato `YYYY-MM` permite identificar cada ejecución y comparar la deuda mes a mes sin sobrescribir datos históricos.

---

### ⚫ Tablas de Log — Decisión de infraestructura

`Logs_Errores` y `Logs_Cambios` no tienen FK hacia ninguna tabla. Esta decisión es intencional: si el sistema intenta registrar un error causado por una violación de integridad referencial, y el log también exige integridad referencial, el log nunca podría escribirse. Al no tener FK, estas tablas funcionan de forma **autónoma e incondicional**, siempre disponibles sin importar el estado del resto de la base de datos.

---

### Conclusión

Cada tabla del modelo resolvió un problema concreto del diseño original: redundancia, inconsistencia, datos mezclados, columnas N/A o dependencias incorrectas. El resultado es un modelo de 20 tablas que puede escalar, mantenerse y auditarse con confianza, y que establece las bases exactas para todos los componentes del sistema sin necesidad de modificar la estructura:

- Las funciones UDF operan sobre `ContratoVenta`, `ContratoArriendo` y `Pagos`
- Los triggers escriben en `AuditoriaPropiedad` y `AuditoriaContrato`
- El evento mensual inserta en `ReportePagos`
- La seguridad se implementa sobre `Rol` y `UsuarioSistema`

---

## 📌 NOTAS FINALES

- Antes de operar con triggers de auditoría, definir el usuario de sesión: `SET @usuario_actual = 'USR-XX';`
- El evento mensual requiere: `SET GLOBAL event_scheduler = ON;`
- Para re-ejecutar cualquier script sin errores, cada uno incluye `DROP IF EXISTS` antes de crear
- El particionamiento de ReportePagos elimina su FK hacia Contratos — limitación documentada de MySQL con tablas particionadas. La integridad se garantiza desde el evento programado que solo inserta contratos válidos.


## AUTORA 
- valentina mancilla