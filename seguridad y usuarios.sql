CREATE USER 'admin_inmobiliaria'@'localhost' IDENTIFIED BY 'Admin2024*';
GRANT ALL PRIVILEGES ON inmobiliaria_db.* TO 'admin_inmobiliaria'@'localhost';

CREATE USER 'agente_inmobiliaria'@'localhost' IDENTIFIED BY 'Agente2024*';
GRANT SELECT, INSERT, UPDATE ON inmobiliaria_db.* TO 'agente_inmobiliaria'@'localhost';

CREATE USER 'contador_inmobiliaria'@'localhost' IDENTIFIED BY 'Contador2024*';
GRANT SELECT ON inmobiliaria_db.Pagos TO 'contador_inmobiliaria'@'localhost';
GRANT SELECT ON inmobiliaria_db.ReportePagos TO 'contador_inmobiliaria'@'localhost';
GRANT SELECT ON inmobiliaria_db.ContratoVenta TO 'contador_inmobiliaria'@'localhost';