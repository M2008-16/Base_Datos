-- 1. Reserva web y pago como unidad atómica

START TRANSACTION;

-- 1. Obtener la programación y el precio de la experiencia solicitada
SELECT s.schedule_id, e.price
INTO @v_schedule_id, @v_precio_unitario
FROM Schedules s
INNER JOIN Experiences e ON s.experience_id = e.experience_id
WHERE e.title = 'Ruta Gastronómica del Mote de Queso en Sincelejo'
LIMIT 1;

-- Respaldo por si el título en los datos de prueba tiene alguna variación
SET @v_schedule_id = IFNULL(@v_schedule_id, 1);
SET @v_precio_unitario = IFNULL(@v_precio_unitario, 95000.00);

SET @v_personas = 2;
SET @v_monto_total = @v_precio_unitario * @v_personas;

-- 2. Insertar la reserva
INSERT INTO Bookings (booking_date, people_count, total_amount, remarks, schedule_id, client_id, status)
VALUES (NOW(), @v_personas, @v_monto_total, 'Reserva web directa', @v_schedule_id, 1, 'CONFIRMED');

SET @v_booking_id = LAST_INSERT_ID();

-- 3. Insertar el pago asociado en la misma unidad atómica
INSERT INTO Payments (payment_amount, payment_date, payment_status, currency, booking_id, payment_method_id)
VALUES (@v_monto_total, NOW(), 'APPROVED', 'COP', @v_booking_id, 1);

-- 4. Confirmar ambas operaciones de forma permanente
COMMIT;

-- 5. Consulta de verificación de persistencia en ambas tablas
SELECT 
    b.booking_id AS `ID Reserva`,
    e.title AS `Experiencia`,
    b.people_count AS `Personas`,
    b.total_amount AS `Monto Reserva`,
    b.status AS `Estado Reserva`,
    p.payment_id AS `ID Pago`,
    p.payment_amount AS `Monto Pagado`,
    p.payment_status AS `Estado Pago`
FROM Bookings b
INNER JOIN Schedules s ON b.schedule_id = s.schedule_id
INNER JOIN Experiences e ON s.experience_id = e.experience_id
INNER JOIN Payments p ON b.booking_id = p.booking_id
WHERE b.booking_id = @v_booking_id;

-- 2. Validación de cupos disponibles y reversión forzada
DROP PROCEDURE IF EXISTS sp_registrar_reserva_validada;

DELIMITER //

CREATE PROCEDURE sp_registrar_reserva_validada(
    IN p_client_id INT,
    IN p_schedule_id INT,
    IN p_people_count INT
)
BEGIN
    DECLARE v_available_slots INT DEFAULT NULL;
    DECLARE v_unit_price DECIMAL(12,2) DEFAULT 0.00;

    START TRANSACTION;

    -- Bloquea la fila de la programación para evitar sobreventa concurrente
    SELECT s.available_slots, e.price
    INTO v_available_slots, v_unit_price
    FROM Schedules s
    INNER JOIN Experiences e ON s.experience_id = e.experience_id
    WHERE s.schedule_id = p_schedule_id
    FOR UPDATE;

    -- Evaluar si la cantidad solicitada supera los cupos disponibles
    IF v_available_slots IS NULL OR p_people_count > v_available_slots THEN
        ROLLBACK;
        SELECT CONCAT(
            'OPERACIÓN REVERTIDA (ROLLBACK): La cantidad solicitada (', p_people_count, 
            ' personas) supera los cupos disponibles en la programación (', IFNULL(v_available_slots, 0), ' cupos).'
        ) AS `Mensaje del Sistema`;
    ELSE
        INSERT INTO Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
        VALUES (NOW(), p_people_count, v_unit_price * p_people_count, p_schedule_id, p_client_id, 'CONFIRMED');

        -- Nota: Si ya tienes activo el trigger trg_actualizar_cupos_despues_reserva, 
        -- omite este UPDATE para evitar descontar los cupos dos veces.
        UPDATE Schedules
        SET available_slots = available_slots - p_people_count
        WHERE schedule_id = p_schedule_id;

        COMMIT;
        SELECT 'OPERACIÓN EXITOSA (COMMIT): Reserva confirmada y cupos actualizados.' AS `Mensaje del Sistema`;
    END IF;
END //

DELIMITER ;

-- Prueba forzando el exceso de cupos (ejecuta ROLLBACK y emite el mensaje):
CALL sp_registrar_reserva_validada(1, 1, 500);


-- 3. Reversión parcial ante fallo de pago
START TRANSACTION;

-- 1. Registrar la reserva con estado 'PENDIENTE' ('PENDING' según el CHECK de Bookings)
INSERT INTO Bookings (booking_date, people_count, total_amount, remarks, schedule_id, client_id, status)
VALUES (NOW(), 12, 1440000.00, 'Paquete turístico masivo - pendiente de pago', 1, 2, 'PENDING');

SET @v_reserva_masiva_id = LAST_INSERT_ID();

-- 2. Crear punto de restauración tras asegurar la reserva
SAVEPOINT sp_reserva_creada;

-- 3. Intentar registrar el pago con monto erróneo/rechazado
INSERT INTO Payments (payment_amount, payment_date, payment_status, currency, booking_id, payment_method_id)
VALUES (0.00, NOW(), 'REJECTED', 'COP', @v_reserva_masiva_id, 1);

-- 4. Revertir únicamente el intento de pago fallido manteniendo la reserva
ROLLBACK TO SAVEPOINT sp_reserva_creada;

-- 5. Confirmar la transacción para conservar la reserva en estado pendiente
COMMIT;

-- Consulta de verificación: la reserva persiste en 'PENDING' y sin el pago erróneo
SELECT 
    b.booking_id AS `ID Reserva`,
    b.people_count AS `Personas`,
    b.total_amount AS `Monto Total`,
    b.status AS `Estado Reserva`,
    COUNT(p.payment_id) AS `Pagos Asociados`
FROM Bookings b
LEFT JOIN Payments p ON b.booking_id = p.booking_id
WHERE b.booking_id = @v_reserva_masiva_id
GROUP BY b.booking_id, b.people_count, b.total_amount, b.status;