-- 1. Registro validado de nuevas experiencias
DROP PROCEDURE IF EXISTS sp_register_experience;

DELIMITER //

CREATE PROCEDURE sp_register_experience(
    IN p_operator_id INT,
    IN p_category_id INT,
    IN p_title VARCHAR(150),
    IN p_municipality VARCHAR(100),
    IN p_duration INT,
    IN p_price DECIMAL(12,2),
    IN p_max_capacity INT
)
BEGIN
    DECLARE v_municipality_id INT DEFAULT NULL;

    -- Validaciones de coherencia de datos
    IF p_price IS NULL OR p_price <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error de validación: El precio debe ser mayor a 0.';
    END IF;

    IF p_duration IS NULL OR p_duration <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error de validación: La duración debe ser mayor a 0.';
    END IF;

    IF p_max_capacity IS NULL OR p_max_capacity <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error de validación: La capacidad máxima debe ser mayor a 0.';
    END IF;

    -- Obtener el ID del municipio (admite tanto el nombre como el ID)
    SELECT municipality_id INTO v_municipality_id
    FROM Municipalities
    WHERE municipality_name = p_municipality
       OR CAST(municipality_id AS CHAR) = p_municipality
    LIMIT 1;

    IF v_municipality_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error de validación: El municipio especificado no existe.';
    END IF;

    INSERT INTO Experiences (
        title, 
        description, 
        price, 
        duration, 
        max_capacity, 
        publication_date, 
        status, 
        operator_id, 
        category_id, 
        municipality_id
    )
    VALUES (
        p_title,
        CONCAT('Experiencia turística: ', p_title),
        p_price,
        p_duration,
        p_max_capacity,
        CURRENT_DATE,
        'ACTIVE',
        p_operator_id,
        p_category_id,
        v_municipality_id
    );

    SELECT 
        LAST_INSERT_ID() AS `ID Experiencia`, 
        'Experiencia turística registrada exitosamente.' AS `Mensaje`;
END //

DELIMITER ;

-- Prueba exitosa:
CALL sp_register_experience(1, 2, 'Avistamiento de Aves en Ciénaga de la Caimanera', 'Coveñas', 4, 120000.00, 15);

-- Prueba de validación fallida (aborta con Error 1644):
CALL sp_register_experience(1, 2, 'Tour Inválido', 'Sincelejo', 3, -50000.00, 10);


-- 2. Procesamiento sincronizado de reserva y descuento de cupos
DROP PROCEDURE IF EXISTS sp_process_booking;

DELIMITER //

CREATE PROCEDURE sp_process_booking(
    IN p_client_id INT,
    IN p_schedule_id INT,
    IN p_people_count INT
)
BEGIN
    DECLARE v_available_slots INT DEFAULT NULL;
    DECLARE v_unit_price DECIMAL(12,2) DEFAULT 0.00;

    IF p_people_count IS NULL OR p_people_count <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cantidad de personas debe ser mayor a 0.';
    END IF;

    START TRANSACTION;

    SELECT s.available_slots, e.price
    INTO v_available_slots, v_unit_price
    FROM Schedules s
    INNER JOIN Experiences e ON s.experience_id = e.experience_id
    WHERE s.schedule_id = p_schedule_id
    FOR UPDATE;

    IF v_available_slots IS NULL THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La programación seleccionada no existe.';
    END IF;

    IF p_people_count > v_available_slots THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: La cantidad solicitada supera los cupos disponibles.';
    END IF;

    INSERT INTO Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
    VALUES (NOW(), p_people_count, v_unit_price * p_people_count, p_schedule_id, p_client_id, 'CONFIRMED');

    UPDATE Schedules
    SET available_slots = available_slots - p_people_count
    WHERE schedule_id = p_schedule_id;

    COMMIT;

    SELECT 
        LAST_INSERT_ID() AS `ID Reserva`, 
        'Reserva registrada y cupos descontados correctamente.' AS `Mensaje`;
END //

DELIMITER ;

-- Prueba de ejecución:
CALL sp_process_booking(1, 56, 1);


-- 3. Confirmación integral con manejo de excepciones y código de respuesta
DROP PROCEDURE IF EXISTS sp_confirm_full_booking;

DELIMITER //

CREATE PROCEDURE sp_confirm_full_booking(
    IN p_client_id INT,
    IN p_schedule_id INT,
    IN p_people_count INT,
    IN p_payment_method_id INT,
    IN p_paid_amount DECIMAL(12,2),
    OUT p_response_code INT
)
proc_block: BEGIN
    DECLARE v_client_exists INT DEFAULT 0;
    DECLARE v_available_slots INT DEFAULT NULL;
    DECLARE v_unit_price DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_booking_total DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_valid_method INT DEFAULT 0;
    DECLARE v_booking_id INT DEFAULT 0;

    -- Manejador equivalente a EXCEPTION WHEN OTHERS
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_response_code = -3;
    END;

    START TRANSACTION;

    -- 1. Validar existencia del visitante
    SELECT COUNT(*) INTO v_client_exists
    FROM Clients
    WHERE client_id = p_client_id;

    IF v_client_exists = 0 THEN
        ROLLBACK;
        SET p_response_code = -3;
        LEAVE proc_block;
    END IF;

    -- 2. Validar disponibilidad de cupos
    SELECT s.available_slots, e.price
    INTO v_available_slots, v_unit_price
    FROM Schedules s
    INNER JOIN Experiences e ON s.experience_id = e.experience_id
    WHERE s.schedule_id = p_schedule_id
    FOR UPDATE;

    IF v_available_slots IS NULL OR p_people_count <= 0 OR p_people_count > v_available_slots THEN
        ROLLBACK;
        SET p_response_code = -1;
        LEAVE proc_block;
    END IF;

    -- 3. Validar método y monto del pago
    SET v_booking_total = v_unit_price * p_people_count;

    SELECT COUNT(*) INTO v_valid_method
    FROM Payment_Methods
    WHERE payment_method_id = p_payment_method_id
      AND status = 'ACTIVE';

    IF v_valid_method = 0 OR p_paid_amount IS NULL OR p_paid_amount <= 0 OR p_paid_amount <> v_booking_total THEN
        ROLLBACK;
        SET p_response_code = -2;
        LEAVE proc_block;
    END IF;

    -- 4. Insertar reserva, registrar pago y actualizar disponibilidad
    INSERT INTO Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
    VALUES (NOW(), p_people_count, v_booking_total, p_schedule_id, p_client_id, 'CONFIRMED');

    SET v_booking_id = LAST_INSERT_ID();

    INSERT INTO Payments (payment_amount, payment_date, payment_status, currency, booking_id, payment_method_id)
    VALUES (p_paid_amount, NOW(), 'APPROVED', 'COP', v_booking_id, p_payment_method_id);

    UPDATE Schedules
    SET available_slots = available_slots - p_people_count
    WHERE schedule_id = p_schedule_id;

    COMMIT;
    SET p_response_code = 0;
END proc_block //

DELIMITER ;

-- Pruebas de los códigos de respuesta:
-- Caso -1 (Cupos insuficientes):
CALL sp_confirm_full_booking(1, 56, 999, 1, 100000.00, @codigo);
SELECT @codigo AS `Código (-1 = Cupos Insuficientes)`;

-- Caso -2 (Error en el pago: monto no coincide o método inválido):
CALL sp_confirm_full_booking(1, 56, 1, 1, 1.00, @codigo);
SELECT @codigo AS `Código (-2 = Error en el Pago)`;

-- Caso -3 (Error inesperado: visitante inexistente):
CALL sp_confirm_full_booking(99999, 56, 1, 1, 95000.00, @codigo);
SELECT @codigo AS `Código (-3 = Error Inesperado)`;