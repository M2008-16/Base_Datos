-- 1. Descuento automático de cupos tras una reserva
DROP TRIGGER IF EXISTS trg_update_slots_after_booking;

DELIMITER //

CREATE TRIGGER trg_update_slots_after_booking
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
    IF NEW.status <> 'CANCELLED' THEN
        UPDATE Schedules
        SET available_slots = available_slots - NEW.people_count
        WHERE schedule_id = NEW.schedule_id;
    END IF;
END //

DELIMITER ;

-- Prueba de ejecución (inserta una reserva de 2 personas y verifica el descuento):
INSERT INTO Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
VALUES (NOW(), 2, 190000.00, 56, 1, 'CONFIRMED');

SELECT schedule_id, total_slots, available_slots 
FROM Schedules 
WHERE schedule_id = 56;


-- 2. Prevención de sobreventa y cupos negativos
DROP TRIGGER IF EXISTS trg_prevent_slots_overbooking;

DELIMITER //

CREATE TRIGGER trg_prevent_slots_overbooking
BEFORE UPDATE ON Schedules
FOR EACH ROW
BEGIN
    IF NEW.available_slots < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error de sobreventa: Los cupos disponibles en la programación no pueden ser menores a 0.';
    END IF;
END //

DELIMITER ;

-- Prueba 1: Actualización directa inválida (aborta con Error 1644)
UPDATE Schedules 
SET available_slots = -3 
WHERE schedule_id = 56;

-- Prueba 2: Reserva que excede los cupos (dispara el Trigger 1 y este Trigger 2 revierte todo)
INSERT INTO Bookings (booking_date, people_count, total_amount, schedule_id, client_id, status)
VALUES (NOW(), 500, 47500000.00, 56, 1, 'CONFIRMED');


-- 3. Tabla de auditoría y registro automático de cancelaciones
DROP TRIGGER IF EXISTS trg_audit_booking_cancellation;

DELIMITER //

CREATE TRIGGER trg_audit_booking_cancellation
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
    DECLARE v_reason VARCHAR(255);

    -- Solo se ejecuta si el estado anterior NO era 'CANCELLED' y el nuevo SÍ es 'CANCELLED'
    IF OLD.status <> 'CANCELLED' AND NEW.status = 'CANCELLED' THEN
        
        -- Busca si existe un motivo detallado en la tabla Cancellations; si no, usa remarks de Bookings
        SELECT reason INTO v_reason
        FROM Cancellations
        WHERE booking_id = NEW.booking_id
        LIMIT 1;

        INSERT INTO Cancellation_Audits (
            booking_id,
            cancellation_date,
            db_user,
            lost_amount_cop,
            reason
        )
        VALUES (
            NEW.booking_id,
            NOW(),
            USER(),
            NEW.total_amount,
            COALESCE(v_reason, NEW.remarks, 'Reserva cancelada desde actualización de estado')
        );
    END IF;
END //

DELIMITER ;

-- Prueba de ejecución:
UPDATE Bookings 
SET status = 'CANCELLED', 
    remarks = 'Solicitud de cancelación por cambio de itinerario del cliente'
WHERE booking_id = 1;

SELECT * FROM Cancellation_Audits;