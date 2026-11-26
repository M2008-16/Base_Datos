-- 1. Vista de experiencias disponibles para reserva inmediata
CREATE OR REPLACE VIEW v_available_web_experiences AS
SELECT 
    s.schedule_id AS `ID Programación`,
    e.title AS `Título de la Experiencia`,
    m.municipality_name AS `Municipio`,
    o.business_name AS `Nombre del Operador`,
    s.activity_date AS `Fecha`,
    s.start_time AS `Hora`,
    s.available_slots AS `Cupos Libres`
FROM Schedules s
INNER JOIN Experiences e ON s.experience_id = e.experience_id
INNER JOIN Operators o ON e.operator_id = o.operator_id
INNER JOIN Municipalities m ON e.municipality_id = m.municipality_id
WHERE s.activity_date >= CURRENT_DATE
  AND s.available_slots > 0
  AND e.status = 'ACTIVE'
ORDER BY s.activity_date ASC, s.start_time ASC;

SELECT * FROM v_available_web_experiences;

-- 2. Vista de resumen operativo por operador y fecha
CREATE OR REPLACE VIEW v_operator_operations_summary AS
SELECT 
    o.business_name AS `Nombre Comercial del Operador`,
    o.phone AS `Teléfono`,
    e.title AS `Título de la Experiencia`,
    s.activity_date AS `Fecha de la Actividad`,
    s.total_slots AS `Cupos Totales`,
    IFNULL(SUM(b.people_count), 0) AS `Cupos Reservados`,
    ROUND((IFNULL(SUM(b.people_count), 0) / s.total_slots) * 100, 2) AS `Porcentaje de Ocupación`
FROM Operators o
INNER JOIN Experiences e ON o.operator_id = e.operator_id
INNER JOIN Schedules s ON e.experience_id = s.experience_id
LEFT JOIN Bookings b 
    ON s.schedule_id = b.schedule_id 
    AND b.status <> 'CANCELLED'
GROUP BY 
    o.business_name, 
    o.phone, 
    e.title, 
    s.activity_date, 
    s.total_slots
ORDER BY s.activity_date ASC;

SELECT * FROM v_operator_operations_summary;

-- 3. Vista de indicadores clave de desempeño por experiencia
CREATE OR REPLACE VIEW v_experiences_performance_kpi AS
SELECT 
    e.experience_id AS `ID Experiencia`,
    e.title AS `Título de la Experiencia`,
    IFNULL(ROUND((SUM(b.people_count) / (COUNT(DISTINCT s.schedule_id) * e.max_capacity)) * 100, 2), 0) AS `Tasa de Ocupación Promedio (%)`,
    IFNULL(SUM(b.total_amount), 0) AS `Recaudo Total (COP)`,
    CASE 
        WHEN ROUND((SUM(b.people_count) / (COUNT(DISTINCT s.schedule_id) * e.max_capacity)) * 100, 2) >= 85 THEN 'EXCELENTE'
        WHEN ROUND((SUM(b.people_count) / (COUNT(DISTINCT s.schedule_id) * e.max_capacity)) * 100, 2) >= 50 THEN 'ACEPTABLE'
        ELSE 'BAJO_RENDIMIENTO'
    END AS `categoria_desempeno`
FROM Experiences e
LEFT JOIN Schedules s ON e.experience_id = s.experience_id
LEFT JOIN Bookings b 
    ON s.schedule_id = b.schedule_id 
    AND b.status IN ('CONFIRMED', 'COMPLETED')
GROUP BY e.experience_id, e.title, e.max_capacity
ORDER BY `Tasa de Ocupación Promedio (%)` DESC;

SELECT * FROM v_experiences_performance_kpi;
