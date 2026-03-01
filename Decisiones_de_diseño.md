# Decisiones de Diseño — Sistema de Gestión Inmobiliaria

---

### Contexto del Proyecto

Una inmobiliaria maneja diariamente información crítica: propiedades, clientes, agentes, contratos y pagos. Si esa información se almacena de forma desordenada, redundante o inconsistente, el negocio enfrenta riesgos reales: cobros duplicados, estados de propiedad incorrectos, comisiones mal calculadas o contratos sin trazabilidad. La normalización no es un ejercicio académico, es la base técnica que garantiza que el sistema sea confiable, escalable y mantenible en el tiempo.

Este modelo partió de una tabla sin normalizar con 27 columnas que mezclaba absolutamente todo en una sola estructura, y fue llevado paso a paso hasta la Tercera Forma Normal, resultando en 20 tablas organizadas, cada una con una responsabilidad clara y sin redundancia de datos.

El modelo está compuesto por 20 tablas organizadas en 7 grupos funcionales: catálogos base (Ciudad, Barrio, TipoPropiedad, EstadoPropiedad, EstadoPago, Rol), personas (Personas, Clientes, Agentes, UsuarioSistema), propiedades (Propiedad), contratos (Contratos, ContratoArriendo, ContratoVenta), pagos (Pagos), auditoría (AuditoriaPropiedad, AuditoriaContrato, ReportePagos), y logs de infraestructura (Logs_Errores, Logs_Cambios).

---

### Primera Forma Normal (1FN) — Garantizar la atomicidad de los datos

**Problema encontrado:**

La tabla original almacenaba múltiples pagos de un mismo contrato dentro de una sola celda, separados por comas:

- Fechas_Pagos → "2024-01-15, 2024-02-15, 2024-03-15"
- Montos_Pagos → "$800.000, $800.000, $800.000"
- Estados_Pagos → "Pagado, Pagado, Pendiente"

Este diseño hace técnicamente imposible responder preguntas básicas del negocio como ¿cuáles pagos están pendientes este mes? o ¿cuánto debe el cliente del contrato CON-001? sin recurrir a procesamiento de texto dentro de la base de datos, lo cual es una práctica completamente inaceptable en un sistema de producción.

**Solución aplicada:**

Se atomizaron los grupos repetidos. Cada pago pasó a ocupar su propia fila con un identificador único Pago_ID. Adicionalmente, el campo Nombre_Cliente que contenía nombre y apellido juntos se separó en Nombre y Apellido, porque son dos datos independientes que pueden necesitarse por separado en reportes, búsquedas o comunicaciones con el cliente.

**Impacto en el negocio:**

Con 1FN aplicada, el sistema puede consultar, filtrar, actualizar y reportar cada pago de forma individual. El contador puede generar un listado de pagos vencidos con una consulta simple. El agente puede marcar un pago específico como pagado sin afectar los demás. Esto es el mínimo requerido para que la base de datos sea funcional.

**Lo que quedó pendiente para 2FN:**

Aunque los datos ya son atómicos, la información del cliente, el agente y la propiedad sigue repitiéndose en cada fila del contrato. Si el agente "María López" actualiza su número de teléfono, hay que modificar manualmente todas las filas donde aparece. Ese problema de redundancia y actualización en cascada manual es exactamente lo que resuelve la 2FN.

---

### Segunda Forma Normal (2FN) — Eliminar dependencias parciales

**Problema encontrado:**

Después de aplicar 1FN, la tabla tenía una clave primaria compuesta por Contrato_ID + Pago_ID. La regla de 2FN establece que cada columna debe depender de la clave completa, no de una parte de ella. Sin embargo, columnas como Nombre_Cliente, Tel_Agente, Direccion_Propiedad o Comision_%_Agente dependían únicamente del Contrato_ID, sin importar el Pago_ID. Eso es una dependencia parcial y constituye una violación directa de 2FN.

El efecto práctico de esta violación era la redundancia masiva: en el contrato CON-001 con tres pagos, los datos de Carlos Ruiz, María López y la propiedad de Cabecera se repetían en tres filas idénticas. Si la propiedad cambiaba de estado, había que actualizarla en tres lugares simultáneamente, con el riesgo real de que quedaran inconsistentes.

**Solución aplicada:**

Se extrajeron todas las entidades que tenían existencia propia e independiente del contrato. Se crearon las tablas Personas, Clientes y Agentes. Los datos personales de nombre, apellido, teléfono y email se centralizaron en Personas como superentidad, y tanto Clientes como Agentes la referencian mediante una clave foránea. Esta decisión fue especialmente importante porque un agente como María López gestionó tres contratos distintos y sus datos deben vivir en un único registro, no repetirse tres veces.

También se crearon en esta etapa las tablas Rol y UsuarioSistema. Rol centraliza los cuatro tipos de acceso del sistema — Administrador, Agente, Contador y Cliente — como un catálogo controlado. UsuarioSistema vincula cada persona con su rol de acceso, permitiendo que el sistema sepa no solo quién realizó una acción, sino con qué nivel de privilegio lo hizo en ese momento. Esta decisión fue clave para que las tablas de auditoría pudieran registrar el usuario responsable de cada cambio con trazabilidad real.

**Impacto en el negocio:**

Con 2FN aplicada se logra la única fuente de verdad. Si un cliente cambia su correo electrónico, se modifica en un solo registro de la tabla Personas y automáticamente todos sus contratos reflejan el dato actualizado. Esto elimina por completo los errores de inconsistencia por actualización parcial, que en un sistema real pueden traducirse en comunicaciones enviadas a correos incorrectos o comisiones calculadas con porcentajes desactualizados.

**Lo que quedó pendiente para 3FN:**

Aun después de eliminar las dependencias parciales, persisten las dependencias transitivas. Por ejemplo, el nombre de la ciudad no depende directamente del contrato, depende de la propiedad, que a su vez depende del contrato. La regla de 3FN prohíbe exactamente ese tipo de cadena indirecta entre atributos no clave.

---

### Tercera Forma Normal (3FN) — Eliminar dependencias transitivas

**Problema encontrado:**

Una dependencia transitiva ocurre cuando un atributo no clave depende de otro atributo no clave en lugar de depender directamente de la clave primaria. En la tabla en 2FN existían múltiples cadenas de este tipo:

- Contrato → Propiedad → Ciudad → Barrio: la ciudad y el barrio no pertenecen al contrato, pertenecen a la propiedad y a la ciudad respectivamente.
- Propiedad → TipoPropiedad: "Apartamento" no es un dato de una propiedad específica, es una categoría de un catálogo.
- Propiedad → EstadoPropiedad: "Disponible", "Arrendada" o "Vendida" son estados de un conjunto cerrado y controlado.
- Pago → EstadoPago: "Pagado", "Pendiente" o "Vencido" son categorías que deben existir como catálogo.
- UsuarioSistema → Rol: el nombre del rol no depende del usuario, depende de una definición centralizada.

Adicionalmente existía un problema estructural grave: los contratos de tipo Venta tenían valores N/A en Valor_Mensual, Fecha_Inicio y Fecha_Fin, columnas que solo aplican a arriendos. Y los contratos de tipo Arriendo tenían N/A en Precio_Venta, Comision_Venta y Fecha_Escritura. Estos N/A no son datos válidos, son síntomas de un diseño que forzó entidades distintas a convivir en la misma tabla.

**Solución aplicada:**

Se crearon catálogos independientes para cada conjunto controlado de valores: Ciudad, Barrio, TipoPropiedad, EstadoPropiedad, EstadoPago y Rol. Cada catálogo tiene su propia clave primaria y las tablas que los usan los referencian mediante FK, garantizando que solo puedan ingresarse valores válidos y predefinidos.

Para resolver los N/A estructurales se implementó un patrón de especialización de entidades: se creó una tabla base Contratos con los atributos comunes a cualquier tipo de contrato — fecha, tipo, cliente, agente, propiedad — y dos tablas especializadas ContratoArriendo y ContratoVenta, cada una con exclusivamente los atributos que le corresponden. Ambas tienen una restricción UNIQUE sobre Contrato_ID para garantizar que un contrato solo pueda tener una especialización, nunca las dos.

**Impacto en el negocio:**

Los catálogos controlados eliminan errores de digitación. Sin catálogo, un agente podría escribir "disponible", "Disponible" o "DISPONIBLE" y el sistema los trataría como tres estados distintos, rompiendo los filtros y reportes. Con el catálogo, el único valor aceptable es el que existe en EstadoPropiedad, y cualquier intento de ingresar otro es rechazado por la base de datos antes de llegar a la aplicación.

La especialización de contratos elimina columnas vacías y hace el modelo más honesto: un contrato de arriendo no tiene precio de escritura porque ese concepto no aplica a su naturaleza, no porque se desconozca el dato.

---

### Tablas de Auditoría — Base para los Triggers del Sistema

Las tablas AuditoriaPropiedad y AuditoriaContrato fueron diseñadas específicamente como tablas destino de los triggers del sistema. Cada vez que cambia el estado de una propiedad — de Disponible a Arrendada o Vendida — el trigger escribe automáticamente un registro en AuditoriaPropiedad con el estado anterior, el estado nuevo, la fecha exacta y el usuario responsable del cambio. De igual forma, cada vez que se registra un nuevo contrato, el trigger escribe en AuditoriaContrato sin intervención manual.

Esta decisión de diseño garantiza trazabilidad completa: el administrador puede consultar en cualquier momento quién cambió el estado de una propiedad, cuándo ocurrió y desde qué estado partió. Gracias a que UsuarioSistema vincula cada usuario con su rol, la auditoría no solo registra un nombre de usuario sino que permite saber si el cambio lo hizo un Agente, un Administrador o un Contador, lo cual es esencial para cualquier investigación de seguridad o inconsistencia en los datos.

La tabla ReportePagos fue diseñada como destino del evento programado mensual. Su campo Periodo en formato YYYY-MM permite identificar cada ejecución automática y comparar el estado de pagos pendientes mes a mes sin sobrescribir datos históricos.

---

### Tablas de Log — Una Decisión de Infraestructura Consciente

Logs_Errores y Logs_Cambios fueron diseñadas deliberadamente fuera de la normalización del dominio del negocio. No tienen claves foráneas hacia ninguna otra tabla. Esta decisión tiene una justificación técnica sólida: si el sistema intenta registrar un error que ocurrió precisamente porque falló una operación de integridad referencial, y la tabla de logs también exige integridad referencial, el log del error nunca podría escribirse, perdiendo la trazabilidad en el momento más crítico.

Al ser tablas de infraestructura transversal con AUTO_INCREMENT y DEFAULT CURRENT_TIMESTAMP, funcionan de forma autónoma e incondicional. Son la bitácora técnica del sistema y deben estar disponibles siempre, independientemente del estado del resto de la base de datos.

---

### Conclusión

La normalización de este sistema no fue un proceso mecánico de aplicar reglas. Fue una serie de decisiones de diseño argumentadas en la realidad del negocio inmobiliario. Cada tabla que se creó resolvió un problema concreto: redundancia, inconsistencia, datos mezclados, N/A estructurales o dependencias incorrectas.

El resultado es un modelo de 20 tablas que puede escalar, mantenerse y auditarse con confianza. Más importante aún, este modelo no solo resuelve los problemas del diseño original — también establece las bases exactas para implementar los componentes restantes del sistema sin necesidad de modificar la estructura de las tablas:

- Las funciones personalizadas de cálculo de comisiones y deuda pendiente operan directamente sobre ContratoVenta, ContratoArriendo y Pagos.
- Los triggers de auditoría escriben en AuditoriaPropiedad y AuditoriaContrato, tablas diseñadas para ese propósito.
- El evento programado mensual inserta en ReportePagos usando el campo Periodo para identificar cada ejecución.
- El sistema de roles y privilegios se implementa sobre Rol y UsuarioSistema, que ya contienen los cuatro roles requeridos: Administrador, Agente, Contador y Cliente.