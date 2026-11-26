-- 1. Consultar cupos disponibles de una programación
DROP FUNCTION IF EXISTS fn_get_available_slots;

DELIMITER //

CREATE FUNCTION fn_get_available_slots(p_schedule_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_slots INT DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_slots = 0;

    SELECT available_slots
    INTO v_slots
    FROM Schedules
    WHERE schedule_id = p_schedule_id
      AND status = 'ACTIVE';

    RETURN IFNULL(v_slots, 0);
END //

DELIMITER ;

-- Prueba de ejecución:
SELECT fn_get_available_slots(22) AS `Cupos Disponibles`;


-- 2. Promedio de satisfacción por operador
DROP FUNCTION IF EXISTS fn_get_operator_avg_rating;

DELIMITER //

CREATE FUNCTION fn_get_operator_avg_rating(p_operator_id INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_avg_rating DECIMAL(3,2) DEFAULT 0.00;

    SELECT IFNULL(ROUND(AVG(r.star_rating), 2), 0.00)
    INTO v_avg_rating
    FROM Experiences e
    INNER JOIN Schedules s ON e.experience_id = s.experience_id
    INNER JOIN Bookings b ON s.schedule_id = b.schedule_id
    INNER JOIN Reviews r ON b.booking_id = r.booking_id
    WHERE e.operator_id = p_operator_id;

    RETURN v_avg_rating;
END //

DELIMITER ;

-- Prueba de ejecución:
SELECT fn_get_operator_avg_rating(1) AS `Promedio Satisfacción`;


-- 3. Evaluación de reembolso por cancelación
DROP FUNCTION IF EXISTS fn_evaluate_cancellation_refund;

DELIMITER //

CREATE FUNCTION fn_evaluate_cancellation_refund(p_booking_id INT)
RETURNS VARCHAR(30)
READS SQL DATA
BEGIN
    DECLARE v_activity_datetime DATETIME;
    DECLARE v_hours_in_advance INT;

    DECLARE EXIT HANDLER FOR NOT FOUND, SQLEXCEPTION
    BEGIN
        RETURN 'RESERVA_INVALIDA';
    END;

    SELECT TIMESTAMP(s.activity_date, s.start_time)
    INTO v_activity_datetime
    FROM Bookings b
    INNER JOIN Schedules s ON b.schedule_id = s.schedule_id
    WHERE b.booking_id = p_booking_id;

    SET v_hours_in_advance = TIMESTAMPDIFF(HOUR, NOW(), v_activity_datetime);

    IF v_hours_in_advance >= 48 THEN
        RETURN 'REEMBOLSO_TOTAL';
    ELSE
        RETURN 'SIN_REEMBOLSO';
    END IF;
END //

DELIMITER ;

-- Pruebas de ejecución:
SELECT fn_evaluate_cancellation_refund(60) AS `Política Reembolso`;
SELECT fn_evaluate_cancellation_refund(9999) AS `Reserva Inexistente`;

