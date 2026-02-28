DROP DATABASE IF EXISTS inmobiliaria_db;
CREATE DATABASE inmobiliaria_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE inmobiliaria_db;

-- ================================================================
-- BLOQUE 1: CATÁLOGOS BASE
-- Tablas sin dependencias externas — se crean primero
-- ================================================================

-- ------------------------------------------------------------
-- Ciudad
-- ------------------------------------------------------------
CREATE TABLE Ciudad (
    Ciudad_ID     VARCHAR(10)  NOT NULL,
    Nombre_Ciudad VARCHAR(100) NOT NULL,
    Departamento  VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Ciudad PRIMARY KEY (Ciudad_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Barrio
-- ------------------------------------------------------------
CREATE TABLE Barrio (
    Barrio_ID     VARCHAR(10)  NOT NULL,
    Nombre_Barrio VARCHAR(100) NOT NULL,
    Ciudad_ID     VARCHAR(10)  NOT NULL,
    CONSTRAINT PK_Barrio        PRIMARY KEY (Barrio_ID),
    CONSTRAINT FK_Barrio_Ciudad FOREIGN KEY (Ciudad_ID)
        REFERENCES Ciudad(Ciudad_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- TipoPropiedad
-- ------------------------------------------------------------
CREATE TABLE TipoPropiedad (
    TipoP_ID    VARCHAR(10) NOT NULL,
    Descripcion VARCHAR(50) NOT NULL,
    CONSTRAINT PK_TipoPropiedad PRIMARY KEY (TipoP_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- EstadoPropiedad
-- ------------------------------------------------------------
CREATE TABLE EstadoPropiedad (
    EstadoP_ID  VARCHAR(10) NOT NULL,
    Descripcion VARCHAR(50) NOT NULL,
    CONSTRAINT PK_EstadoPropiedad PRIMARY KEY (EstadoP_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- EstadoPago
-- ------------------------------------------------------------
CREATE TABLE EstadoPago (
    EstadoPago_ID VARCHAR(10) NOT NULL,
    Descripcion   VARCHAR(50) NOT NULL,
    CONSTRAINT PK_EstadoPago PRIMARY KEY (EstadoPago_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Rol
-- ------------------------------------------------------------
CREATE TABLE Rol (
    Rol_ID      VARCHAR(10)  NOT NULL,
    Nombre_Rol  VARCHAR(50)  NOT NULL,
    Descripcion VARCHAR(200) NOT NULL,
    CONSTRAINT PK_Rol PRIMARY KEY (Rol_ID)
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 2: ENTIDADES DE PERSONAS
-- ================================================================

-- ------------------------------------------------------------
-- Personas  (superentidad de Cliente y Agente)
-- ------------------------------------------------------------
CREATE TABLE Personas (
    Persona_ID VARCHAR(10)  NOT NULL,
    Nombre     VARCHAR(80)  NOT NULL,
    Apellido   VARCHAR(80)  NOT NULL,
    Telefono   VARCHAR(20)  NOT NULL,
    Email      VARCHAR(120) NOT NULL,
    CONSTRAINT PK_Personas       PRIMARY KEY (Persona_ID),
    CONSTRAINT UQ_Personas_Email UNIQUE (Email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Clientes
-- ------------------------------------------------------------
CREATE TABLE Clientes (
    Cliente_ID VARCHAR(10) NOT NULL,
    Persona_ID VARCHAR(10) NOT NULL,
    CONSTRAINT PK_Clientes          PRIMARY KEY (Cliente_ID),
    CONSTRAINT FK_Clientes_Personas FOREIGN KEY (Persona_ID)
        REFERENCES Personas(Persona_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT UQ_Clientes_Persona  UNIQUE (Persona_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Agentes
-- ------------------------------------------------------------
CREATE TABLE Agentes (
    Agente_ID    VARCHAR(10)  NOT NULL,
    Persona_ID   VARCHAR(10)  NOT NULL,
    Comision_Pct DECIMAL(5,2) NOT NULL COMMENT 'Porcentaje de comisión. Ejemplo: 5.00 = 5%',
    CONSTRAINT PK_Agentes          PRIMARY KEY (Agente_ID),
    CONSTRAINT FK_Agentes_Personas FOREIGN KEY (Persona_ID)
        REFERENCES Personas(Persona_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT UQ_Agentes_Persona  UNIQUE (Persona_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- UsuarioSistema
-- ------------------------------------------------------------
CREATE TABLE UsuarioSistema (
    Usuario_ID    VARCHAR(10) NOT NULL,
    Persona_ID    VARCHAR(10) NOT NULL,
    Rol_ID        VARCHAR(10) NOT NULL,
    NombreUsuario VARCHAR(60) NOT NULL,
    CONSTRAINT PK_UsuarioSistema       PRIMARY KEY (Usuario_ID),
    CONSTRAINT FK_Usuario_Personas     FOREIGN KEY (Persona_ID)
        REFERENCES Personas(Persona_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Usuario_Rol          FOREIGN KEY (Rol_ID)
        REFERENCES Rol(Rol_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT UQ_UsuarioSistema_Login UNIQUE (NombreUsuario)
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 3: PROPIEDADES
-- ================================================================

-- ------------------------------------------------------------
-- Propiedad
-- ------------------------------------------------------------
CREATE TABLE Propiedad (
    Propiedad_ID     VARCHAR(10)   NOT NULL,
    Direccion        VARCHAR(150)  NOT NULL,
    Precio_Propiedad DECIMAL(15,2) NOT NULL,
    TipoP_ID         VARCHAR(10)   NOT NULL,
    EstadoP_ID       VARCHAR(10)   NOT NULL,
    Barrio_ID        VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_Propiedad          PRIMARY KEY (Propiedad_ID),
    CONSTRAINT FK_Propiedad_Tipo     FOREIGN KEY (TipoP_ID)
        REFERENCES TipoPropiedad(TipoP_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Propiedad_Estado   FOREIGN KEY (EstadoP_ID)
        REFERENCES EstadoPropiedad(EstadoP_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Propiedad_Barrio   FOREIGN KEY (Barrio_ID)
        REFERENCES Barrio(Barrio_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 4: CONTRATOS
-- ================================================================

-- ------------------------------------------------------------
-- Contratos  (tabla central)
-- ------------------------------------------------------------
CREATE TABLE Contratos (
    Contrato_ID    VARCHAR(10)              NOT NULL,
    Fecha_Contrato DATE                     NOT NULL,
    Tipo_Contrato  ENUM('Arriendo','Venta') NOT NULL,
    Cliente_ID     VARCHAR(10)              NOT NULL,
    Agente_ID      VARCHAR(10)              NOT NULL,
    Propiedad_ID   VARCHAR(10)              NOT NULL,
    CONSTRAINT PK_Contratos           PRIMARY KEY (Contrato_ID),
    CONSTRAINT FK_Contratos_Cliente   FOREIGN KEY (Cliente_ID)
        REFERENCES Clientes(Cliente_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Contratos_Agente    FOREIGN KEY (Agente_ID)
        REFERENCES Agentes(Agente_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Contratos_Propiedad FOREIGN KEY (Propiedad_ID)
        REFERENCES Propiedad(Propiedad_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ContratoArriendo
-- ------------------------------------------------------------
CREATE TABLE ContratoArriendo (
    ContrArr_ID   VARCHAR(10)   NOT NULL,
    Contrato_ID   VARCHAR(10)   NOT NULL,
    Valor_Mensual DECIMAL(12,2) NOT NULL,
    Fecha_Inicio  DATE          NOT NULL,
    Fecha_Fin     DATE          NOT NULL,
    CONSTRAINT PK_ContratoArriendo   PRIMARY KEY (ContrArr_ID),
    CONSTRAINT FK_ContrArr_Contratos FOREIGN KEY (Contrato_ID)
        REFERENCES Contratos(Contrato_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT UQ_ContrArr_Contrato  UNIQUE (Contrato_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ContratoVenta
-- ------------------------------------------------------------
CREATE TABLE ContratoVenta (
    ContrVenta_ID   VARCHAR(10)   NOT NULL,
    Contrato_ID     VARCHAR(10)   NOT NULL,
    Precio_Venta    DECIMAL(15,2) NOT NULL,
    Comision_Venta  DECIMAL(15,2) NOT NULL,
    Fecha_Escritura DATE          NOT NULL,
    CONSTRAINT PK_ContratoVenta        PRIMARY KEY (ContrVenta_ID),
    CONSTRAINT FK_ContrVenta_Contratos FOREIGN KEY (Contrato_ID)
        REFERENCES Contratos(Contrato_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT UQ_ContrVenta_Contrato  UNIQUE (Contrato_ID)
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 5: PAGOS
-- ================================================================

-- ------------------------------------------------------------
-- Pagos
-- ------------------------------------------------------------
CREATE TABLE Pagos (
    Pago_ID       VARCHAR(10)   NOT NULL,
    Contrato_ID   VARCHAR(10)   NOT NULL,
    Fecha_Pago    DATE          NOT NULL,
    Monto_Pago    DECIMAL(12,2) NOT NULL,
    EstadoPago_ID VARCHAR(10)   NOT NULL,
    CONSTRAINT PK_Pagos            PRIMARY KEY (Pago_ID),
    CONSTRAINT FK_Pagos_Contratos  FOREIGN KEY (Contrato_ID)
        REFERENCES Contratos(Contrato_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Pagos_EstadoPago FOREIGN KEY (EstadoPago_ID)
        REFERENCES EstadoPago(EstadoPago_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 6: AUDITORÍA Y REPORTES
-- ================================================================

-- ------------------------------------------------------------
-- AuditoriaContrato
-- ------------------------------------------------------------
CREATE TABLE AuditoriaContrato (
    AuditCon_ID  VARCHAR(10)  NOT NULL,
    Contrato_ID  VARCHAR(10)  NOT NULL,
    Evento       VARCHAR(100) NOT NULL,
    Fecha_Evento DATE         NOT NULL,
    Usuario_ID   VARCHAR(10)  NOT NULL,
    Fecha_Hora   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_AuditoriaContrato  PRIMARY KEY (AuditCon_ID),
    CONSTRAINT FK_AuditCon_Contratos FOREIGN KEY (Contrato_ID)
        REFERENCES Contratos(Contrato_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_AuditCon_Usuario   FOREIGN KEY (Usuario_ID)
        REFERENCES UsuarioSistema(Usuario_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- AuditoriaPropiedad
-- ------------------------------------------------------------
CREATE TABLE AuditoriaPropiedad (
    Audit_ID        VARCHAR(10) NOT NULL,
    Propiedad_ID    VARCHAR(10) NOT NULL,
    Estado_Anterior VARCHAR(50) NOT NULL,
    Estado_Nuevo    VARCHAR(50) NOT NULL,
    Fecha_Cambio    DATE        NOT NULL,
    Usuario_ID      VARCHAR(10) NOT NULL,
    Fecha_Hora      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_AuditoriaPropiedad  PRIMARY KEY (Audit_ID),
    CONSTRAINT FK_AuditProp_Propiedad FOREIGN KEY (Propiedad_ID)
        REFERENCES Propiedad(Propiedad_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_AuditProp_Usuario   FOREIGN KEY (Usuario_ID)
        REFERENCES UsuarioSistema(Usuario_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- ReportePagos  (tabla destino del evento programado mensual)
-- ------------------------------------------------------------
CREATE TABLE ReportePagos (
    Reporte_ID      VARCHAR(10)   NOT NULL,
    Contrato_ID     VARCHAR(10)   NOT NULL,
    Fecha_Reporte   DATE          NOT NULL,
    Monto_Pendiente DECIMAL(12,2) NOT NULL,
    Descripcion     VARCHAR(200)  NOT NULL,
    Periodo         VARCHAR(7)    NOT NULL COMMENT 'Formato YYYY-MM',
    CONSTRAINT PK_ReportePagos      PRIMARY KEY (Reporte_ID),
    CONSTRAINT FK_Reporte_Contratos FOREIGN KEY (Contrato_ID)
        REFERENCES Contratos(Contrato_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ================================================================
-- BLOQUE 7: TABLAS DE LOGS (fuera de la normalización)
-- Sin FK hacia otras tablas — deben funcionar de forma autónoma
-- incluso cuando ocurren errores de integridad referencial
-- ================================================================

-- ------------------------------------------------------------
-- Logs_Errores
-- ------------------------------------------------------------
CREATE TABLE Logs_Errores (
    Log_ID       INT          NOT NULL AUTO_INCREMENT,
    Fecha_Error  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Nombre_Error VARCHAR(150) NOT NULL COMMENT 'Tipo o nombre del error. Ej: DUPLICATE_KEY, FK_VIOLATION',
    Lugar_Error  VARCHAR(200) NOT NULL COMMENT 'Tabla, trigger o procedimiento donde ocurrió',
    Detalle      TEXT                  COMMENT 'Mensaje completo del error (opcional)',
    CONSTRAINT PK_Logs_Errores PRIMARY KEY (Log_ID)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Logs_Cambios
-- ------------------------------------------------------------
CREATE TABLE Logs_Cambios (
    Log_ID        INT          NOT NULL AUTO_INCREMENT,
    Fecha_Cambio  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Nombre_Cambio VARCHAR(150) NOT NULL COMMENT 'Tipo de operación. Ej: INSERT, UPDATE, DELETE',
    Lugar_Cambio  VARCHAR(200) NOT NULL COMMENT 'Tabla o proceso donde se realizó el cambio',
    Descripcion   TEXT                  COMMENT 'Detalle del cambio: valores anteriores o nuevos (opcional)',
    CONSTRAINT PK_Logs_Cambios PRIMARY KEY (Log_ID)
) ENGINE=InnoDB;

-- ================================================================
-- NOTA: Los índices de optimización se encuentran en el script
-- optimizacion_eventos_inmobiliaria.sql
-- ================================================================

-- ================================================================
-- BLOQUE 9: DML — CATÁLOGOS BASE
-- ================================================================

INSERT INTO Ciudad (Ciudad_ID, Nombre_Ciudad, Departamento) VALUES
('CIU-01', 'Bucaramanga',  'Santander'),
('CIU-02', 'Medellín',     'Antioquia'),
('CIU-03', 'Bogotá',       'Cundinamarca'),
('CIU-04', 'Cali',         'Valle del Cauca'),
('CIU-05', 'Barranquilla', 'Atlántico');

INSERT INTO Barrio (Barrio_ID, Nombre_Barrio, Ciudad_ID) VALUES
('BAR-01', 'Cabecera',    'CIU-01'),
('BAR-02', 'El Poblado',  'CIU-02'),
('BAR-03', 'Florida',     'CIU-01'),
('BAR-04', 'Chapinero',   'CIU-03'),
('BAR-05', 'San Antonio', 'CIU-04'),
('BAR-06', 'El Prado',    'CIU-05');

INSERT INTO TipoPropiedad (TipoP_ID, Descripcion) VALUES
('TP-01', 'Apartamento'),
('TP-02', 'Casa'),
('TP-03', 'Local Comercial');

INSERT INTO EstadoPropiedad (EstadoP_ID, Descripcion) VALUES
('EP-01', 'Disponible'),
('EP-02', 'Arrendada'),
('EP-03', 'Vendida');

INSERT INTO EstadoPago (EstadoPago_ID, Descripcion) VALUES
('EPG-01', 'Pagado'),
('EPG-02', 'Pendiente'),
('EPG-03', 'Vencido');

INSERT INTO Rol (Rol_ID, Nombre_Rol, Descripcion) VALUES
('ROL-01', 'Administrador', 'Acceso total al sistema'),
('ROL-02', 'Agente',        'Gestión de contratos y propiedades'),
('ROL-03', 'Cliente',       'Consulta de propiedades disponibles'),
('ROL-04', 'Contador',      'Acceso a pagos y reportes financieros');

-- ================================================================
-- BLOQUE 10: DML — PERSONAS, CLIENTES, AGENTES Y USUARIOS
-- ================================================================

INSERT INTO Personas (Persona_ID, Nombre, Apellido, Telefono, Email) VALUES
('PER-01', 'Carlos', 'Ruiz',   '310-100', 'c.ruiz@mail.com'),
('PER-02', 'Ana',    'Torres', '311-200', 'a.torres@mail.com'),
('PER-03', 'Luis',   'Peña',   '312-300', 'l.pena@mail.com'),
('PER-04', 'Sara',   'Díaz',   '313-400', 's.diaz@mail.com'),
('PER-05', 'Diego',  'Mora',   '314-500', 'd.mora@mail.com'),
('PER-06', 'Elena',  'Cruz',   '315-600', 'e.cruz@mail.com'),
('PER-07', 'María',  'López',  '320-001', 'm.lopez@mail.com'),
('PER-08', 'Pedro',  'Gómez',  '320-002', 'p.gomez@mail.com'),
('PER-09', 'Juan',   'Ríos',   '320-003', 'j.rios@mail.com');

INSERT INTO Clientes (Cliente_ID, Persona_ID) VALUES
('CLI-01', 'PER-01'),
('CLI-02', 'PER-02'),
('CLI-03', 'PER-03'),
('CLI-04', 'PER-04'),
('CLI-05', 'PER-05'),
('CLI-06', 'PER-06');

INSERT INTO Agentes (Agente_ID, Persona_ID, Comision_Pct) VALUES
('AGE-01', 'PER-07', 5.00),
('AGE-02', 'PER-08', 3.00),
('AGE-03', 'PER-09', 3.00);

INSERT INTO UsuarioSistema (Usuario_ID, Persona_ID, Rol_ID, NombreUsuario) VALUES
('USR-01', 'PER-07', 'ROL-02', 'agente01'),
('USR-02', 'PER-08', 'ROL-02', 'agente02'),
('USR-03', 'PER-09', 'ROL-02', 'agente03'),
('USR-04', 'PER-01', 'ROL-03', 'cli_carlos'),
('USR-05', 'PER-02', 'ROL-03', 'cli_ana'),
('USR-06', 'PER-03', 'ROL-03', 'cli_luis'),
('USR-07', 'PER-04', 'ROL-03', 'cli_sara'),
('USR-08', 'PER-05', 'ROL-03', 'cli_diego'),
('USR-09', 'PER-06', 'ROL-03', 'cli_elena');

-- ================================================================
-- BLOQUE 11: DML — PROPIEDADES
-- ================================================================

INSERT INTO Propiedad (Propiedad_ID, Direccion, Precio_Propiedad, TipoP_ID, EstadoP_ID, Barrio_ID) VALUES
('PROP-01', 'Cra 10 #45-20',   250000000.00, 'TP-01', 'EP-02', 'BAR-01'),
('PROP-02', 'Calle 35 #12-05', 320000000.00, 'TP-02', 'EP-03', 'BAR-02'),
('PROP-03', 'Av 27 #60-15',    180000000.00, 'TP-03', 'EP-02', 'BAR-03'),
('PROP-04', 'Cra 52 #80-30',   450000000.00, 'TP-02', 'EP-03', 'BAR-04'),
('PROP-05', 'Calle 9 #22-10',  200000000.00, 'TP-01', 'EP-01', 'BAR-05'),
('PROP-06', 'Cra 15 #33-40',   280000000.00, 'TP-03', 'EP-03', 'BAR-06');

-- ================================================================
-- BLOQUE 12: DML — CONTRATOS, ARRIENDOS Y VENTAS
-- ================================================================

INSERT INTO Contratos (Contrato_ID, Fecha_Contrato, Tipo_Contrato, Cliente_ID, Agente_ID, Propiedad_ID) VALUES
('CON-001', '2024-01-15', 'Arriendo', 'CLI-01', 'AGE-01', 'PROP-01'),
('CON-002', '2024-02-01', 'Venta',    'CLI-02', 'AGE-02', 'PROP-02'),
('CON-003', '2024-03-10', 'Arriendo', 'CLI-03', 'AGE-01', 'PROP-03'),
('CON-004', '2024-04-05', 'Venta',    'CLI-04', 'AGE-03', 'PROP-04'),
('CON-005', '2024-05-20', 'Arriendo', 'CLI-05', 'AGE-02', 'PROP-05'),
('CON-006', '2024-06-12', 'Venta',    'CLI-06', 'AGE-01', 'PROP-06');

INSERT INTO ContratoArriendo (ContrArr_ID, Contrato_ID, Valor_Mensual, Fecha_Inicio, Fecha_Fin) VALUES
('CA-001', 'CON-001',  800000.00, '2024-01-15', '2025-01-15'),
('CA-002', 'CON-003', 1200000.00, '2024-03-10', '2025-03-10'),
('CA-003', 'CON-005',  950000.00, '2024-05-20', '2025-05-20');

INSERT INTO ContratoVenta (ContrVenta_ID, Contrato_ID, Precio_Venta, Comision_Venta, Fecha_Escritura) VALUES
('CV-001', 'CON-002', 320000000.00,  9600000.00, '2024-02-15'),
('CV-002', 'CON-004', 450000000.00, 13500000.00, '2024-04-20'),
('CV-003', 'CON-006', 280000000.00,  8400000.00, '2024-06-25');

-- ================================================================
-- BLOQUE 13: DML — PAGOS
-- ================================================================

INSERT INTO Pagos (Pago_ID, Contrato_ID, Fecha_Pago, Monto_Pago, EstadoPago_ID) VALUES
('PAG-001', 'CON-001', '2024-01-15',   800000.00, 'EPG-01'),
('PAG-002', 'CON-001', '2024-02-15',   800000.00, 'EPG-01'),
('PAG-003', 'CON-001', '2024-03-15',   800000.00, 'EPG-02'),
('PAG-004', 'CON-002', '2024-02-01',  9600000.00, 'EPG-01'),
('PAG-005', 'CON-003', '2024-03-10',  1200000.00, 'EPG-01'),
('PAG-006', 'CON-003', '2024-04-10',  1200000.00, 'EPG-02'),
('PAG-007', 'CON-004', '2024-04-05', 13500000.00, 'EPG-01'),
('PAG-008', 'CON-005', '2024-05-20',   950000.00, 'EPG-03'),
('PAG-009', 'CON-006', '2024-06-12',  8400000.00, 'EPG-01');

-- ================================================================
-- BLOQUE 14: DML — AUDITORÍA Y REPORTES
-- ================================================================

INSERT INTO AuditoriaContrato (AuditCon_ID, Contrato_ID, Evento, Fecha_Evento, Usuario_ID, Fecha_Hora) VALUES
('ACO-01', 'CON-001', 'Contrato creado', '2024-01-15', 'USR-01', '2024-01-15 09:00:00'),
('ACO-02', 'CON-002', 'Contrato creado', '2024-02-01', 'USR-02', '2024-02-01 10:00:00'),
('ACO-03', 'CON-003', 'Contrato creado', '2024-03-10', 'USR-01', '2024-03-10 11:00:00'),
('ACO-04', 'CON-004', 'Contrato creado', '2024-04-05', 'USR-03', '2024-04-05 14:00:00'),
('ACO-05', 'CON-005', 'Contrato creado', '2024-05-20', 'USR-02', '2024-05-20 09:30:00'),
('ACO-06', 'CON-006', 'Contrato creado', '2024-06-12', 'USR-01', '2024-06-12 16:00:00');

INSERT INTO AuditoriaPropiedad (Audit_ID, Propiedad_ID, Estado_Anterior, Estado_Nuevo, Fecha_Cambio, Usuario_ID, Fecha_Hora) VALUES
('AUD-01', 'PROP-01', 'Disponible', 'Arrendada',  '2024-01-15', 'USR-01', '2024-01-15 09:01:00'),
('AUD-02', 'PROP-02', 'Disponible', 'Vendida',    '2024-02-01', 'USR-02', '2024-02-01 10:01:00'),
('AUD-03', 'PROP-03', 'Disponible', 'Arrendada',  '2024-03-10', 'USR-01', '2024-03-10 11:01:00'),
('AUD-04', 'PROP-04', 'Disponible', 'Vendida',    '2024-04-05', 'USR-03', '2024-04-05 14:01:00'),
('AUD-05', 'PROP-05', 'Arrendada',  'Disponible', '2024-05-01', 'USR-02', '2024-05-01 08:00:00'),
('AUD-06', 'PROP-06', 'Disponible', 'Vendida',    '2024-06-12', 'USR-01', '2024-06-12 16:01:00');

INSERT INTO ReportePagos (Reporte_ID, Contrato_ID, Fecha_Reporte, Monto_Pendiente, Descripcion, Periodo) VALUES
('REP-001', 'CON-001', '2024-02-01',  800000.00, 'Pago mes 2 pendiente',   '2024-02'),
('REP-002', 'CON-003', '2024-04-01', 1200000.00, 'Pago mes 2 pendiente',   '2024-04'),
('REP-003', 'CON-001', '2024-03-01',  800000.00, 'Pago mes 3 pendiente',   '2024-03'),
('REP-004', 'CON-005', '2024-06-01',  950000.00, 'Pago vencido mayo 2024', '2024-06');