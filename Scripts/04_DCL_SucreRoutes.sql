-- 1. Rol de consulta para pasantes y consultores

CREATE ROLE 'rol_promotor_turistico';

GRANT SELECT ON db_SucreRoutes.Experiences TO 'rol_promotor_turistico';
GRANT SELECT ON db_SucreRoutes.Categories TO 'rol_promotor_turistico';
GRANT SELECT ON db_SucreRoutes.Schedules TO 'rol_promotor_turistico';

CREATE USER 'usr_promotor1'@'localhost' IDENTIFIED BY 'Promotor2026*';
GRANT 'rol_promotor_turistico' TO 'usr_promotor1'@'localhost';
SET DEFAULT ROLE ALL TO 'usr_promotor1'@'localhost';

-- Ejecutando sesión como 'usr_promotor1'@'localhost':
-- 1) Consulta exitosa:
SELECT experience_id, title, price, status 
FROM db_SucreRoutes.Experiences 
LIMIT 5;

-- 2) Operación denegada (genera ERROR 1142: DELETE command denied to user 'usr_promotor1'):
DELETE FROM db_SucreRoutes.Experiences 
WHERE experience_id = 1;

-- 2.Segregación de funciones entre reservas y administración de contenido

CREATE ROLE 'rol_agente_reservas', 'rol_admin_contenido';

GRANT INSERT, UPDATE ON db_SucreRoutes.Bookings TO 'rol_agente_reservas';
GRANT INSERT, UPDATE ON db_SucreRoutes.Payments TO 'rol_agente_reservas';

GRANT INSERT, UPDATE, DELETE ON db_SucreRoutes.Experiences TO 'rol_admin_contenido';
GRANT INSERT, UPDATE, DELETE ON db_SucreRoutes.Schedules TO 'rol_admin_contenido';
GRANT INSERT, UPDATE, DELETE ON db_SucreRoutes.Operators TO 'rol_admin_contenido';

CREATE USER 'usr_agente1'@'localhost' IDENTIFIED BY 'Agente2026*';
GRANT 'rol_agente_reservas' TO 'usr_agente1'@'localhost';
SET DEFAULT ROLE ALL TO 'usr_agente1'@'localhost';

CREATE USER 'usr_admin_contenido1'@'localhost' IDENTIFIED BY 'AdminCont2026*';
GRANT 'rol_admin_contenido' TO 'usr_admin_contenido1'@'localhost';
SET DEFAULT ROLE ALL TO 'usr_admin_contenido1'@'localhost';

-- Prueba A: Sesión iniciada como 'usr_agente1'@'localhost'
-- Permitida (registra una reserva en Bookings):
INSERT INTO db_SucreRoutes.Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
VALUES (NOW(), 2, 190000.00, 1, 4, 'CONFIRMED');

-- Denegada (ERROR 1142: UPDATE command denied on table 'Operators'):
UPDATE db_SucreRoutes.Operators 
SET phone = '+57 3000000000' 
WHERE operator_id = 1;

-- Prueba B: Sesión iniciada como 'usr_admin_contenido1'@'localhost'
-- Permitida (actualiza una experiencia en Experiences):
UPDATE db_SucreRoutes.Experiences 
SET status = 'ACTIVE' 
WHERE experience_id = 1;

-- Denegada (ERROR 1142: INSERT command denied on table 'Payments'):
INSERT INTO db_SucreRoutes.Payments (payment_amount, payment_date, payment_status, currency, booking_id, payment_method_id)
VALUES (190000.00, NOW(), 'APPROVED', 'COP', 1, 1);

-- 3. Revocación de borrado en reservas y verificación en diccionario de datos

REVOKE DELETE ON db_SucreRoutes.Bookings FROM 'rol_agente_reservas';
FLUSH PRIVILEGES;

SELECT 
    GRANTEE AS `Rol`,
    TABLE_SCHEMA AS `Base de Datos`,
    TABLE_NAME AS `Tabla`,
    PRIVILEGE_TYPE AS `Privilegio Vigente`
FROM information_schema.role_table_grants
WHERE GRANTEE = 'rol_agente_reservas'
  AND TABLE_SCHEMA = 'db_SucreRoutes'
  AND TABLE_NAME = 'Bookings';

-- Prueba de auditoría con sesión iniciada como 'usr_agente1'@'localhost':
-- Bloqueada (ERROR 1142: DELETE command denied to user 'usr_agente1' for table 'Bookings'):
DELETE FROM db_SucreRoutes.Bookings 
WHERE booking_id = 150;


-- Roles de Sistema

-- 1. Creación de roles
CREATE ROLE IF NOT EXISTS 
    'rol_visitante',
    'rol_operador_turistico',
    'rol_guia',
    'rol_administrador',
    'rol_responsable_reservas',
    'rol_aliado';

-- 2. Asignación de privilegios a cada rol
-- Visitante
GRANT SELECT ON db_SucreRoutes.Experiences TO 'rol_visitante';
GRANT SELECT ON db_SucreRoutes.Schedules TO 'rol_visitante';
GRANT SELECT ON db_SucreRoutes.Categories TO 'rol_visitante';
GRANT SELECT ON db_SucreRoutes.Attractions TO 'rol_visitante';
GRANT SELECT ON db_SucreRoutes.Municipalities TO 'rol_visitante';
GRANT SELECT, INSERT ON db_SucreRoutes.Bookings TO 'rol_visitante';
GRANT SELECT, INSERT ON db_SucreRoutes.Payments TO 'rol_visitante';
GRANT SELECT, INSERT ON db_SucreRoutes.Reviews TO 'rol_visitante';

-- Operador turístico
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Experiences TO 'rol_operador_turistico';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Schedules TO 'rol_operador_turistico';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_SucreRoutes.Experience_Attractions TO 'rol_operador_turistico';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_SucreRoutes.Experience_Services TO 'rol_operador_turistico';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_SucreRoutes.Ally_Experiences TO 'rol_operador_turistico';
GRANT SELECT, INSERT, UPDATE, DELETE ON db_SucreRoutes.Guide_Schedules TO 'rol_operador_turistico';
GRANT SELECT ON db_SucreRoutes.Bookings TO 'rol_operador_turistico';
GRANT SELECT ON db_SucreRoutes.Guides TO 'rol_operador_turistico';
GRANT SELECT ON db_SucreRoutes.Allies TO 'rol_operador_turistico';

-- Guía
GRANT SELECT ON db_SucreRoutes.Guide_Schedules TO 'rol_guia';
GRANT SELECT ON db_SucreRoutes.Schedules TO 'rol_guia';
GRANT SELECT ON db_SucreRoutes.Experiences TO 'rol_guia';
GRANT SELECT ON db_SucreRoutes.Attractions TO 'rol_guia';
GRANT SELECT ON db_SucreRoutes.Municipalities TO 'rol_guia';

-- Administrador
GRANT ALL PRIVILEGES ON db_SucreRoutes.* TO 'rol_administrador';

-- Responsable de reservas
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Bookings TO 'rol_responsable_reservas';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Clients TO 'rol_responsable_reservas';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Payments TO 'rol_responsable_reservas';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Payment_Transactions TO 'rol_responsable_reservas';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Cancellations TO 'rol_responsable_reservas';
GRANT SELECT, INSERT, UPDATE ON db_SucreRoutes.Refunds TO 'rol_responsable_reservas';
GRANT SELECT, UPDATE ON db_SucreRoutes.Schedules TO 'rol_responsable_reservas';
GRANT SELECT ON db_SucreRoutes.Experiences TO 'rol_responsable_reservas';
GRANT SELECT ON db_SucreRoutes.Payment_Methods TO 'rol_responsable_reservas';

-- Restaurante o aliado
GRANT SELECT, UPDATE ON db_SucreRoutes.Allies TO 'rol_aliado';
GRANT SELECT, UPDATE ON db_SucreRoutes.Ally_Experiences TO 'rol_aliado';
GRANT SELECT ON db_SucreRoutes.Experiences TO 'rol_aliado';
GRANT SELECT ON db_SucreRoutes.Schedules TO 'rol_aliado';

-- 3. Creación de usuarios
CREATE USER IF NOT EXISTS 'usr_visitante1'@'localhost' IDENTIFIED BY 'Visitante2026*';
CREATE USER IF NOT EXISTS 'usr_operador1'@'localhost' IDENTIFIED BY 'Operador2026*';
CREATE USER IF NOT EXISTS 'usr_guia1'@'localhost' IDENTIFIED BY 'Guia2026*';
CREATE USER IF NOT EXISTS 'usr_admin1'@'localhost' IDENTIFIED BY 'Admin2026*';
CREATE USER IF NOT EXISTS 'usr_reservas1'@'localhost' IDENTIFIED BY 'Reservas2026*';
CREATE USER IF NOT EXISTS 'usr_aliado1'@'localhost' IDENTIFIED BY 'Aliado2026*';

-- 4. Asignación de roles a los usuarios
GRANT 'rol_visitante' TO 'usr_visitante1'@'localhost';
GRANT 'rol_operador_turistico' TO 'usr_operador1'@'localhost';
GRANT 'rol_guia' TO 'usr_guia1'@'localhost';
GRANT 'rol_administrador' TO 'usr_admin1'@'localhost';
GRANT 'rol_responsable_reservas' TO 'usr_reservas1'@'localhost';
GRANT 'rol_aliado' TO 'usr_aliado1'@'localhost';

-- 5. Activación de roles por defecto
SET DEFAULT ROLE ALL TO 
    'usr_visitante1'@'localhost',
    'usr_operador1'@'localhost',
    'usr_guia1'@'localhost',
    'usr_admin1'@'localhost',
    'usr_reservas1'@'localhost',
    'usr_aliado1'@'localhost';

FLUSH PRIVILEGES;

-- 6. Verificación de permisos
SELECT 
    GRANTEE AS `Rol`,
    TABLE_NAME AS `Tabla`,
    PRIVILEGE_TYPE AS `Privilegio`
FROM information_schema.TABLE_PRIVILEGES
WHERE TABLE_SCHEMA = 'db_SucreRoutes'
  AND GRANTEE LIKE '%rol_%'
ORDER BY GRANTEE, TABLE_NAME, PRIVILEGE_TYPE;