-- 1. Listado consolidado de visitantes y tours adquiridos en Sucre
SELECT 
    CONCAT(c.first_names, ' ', c.last_names) AS `Nombre del Visitante`,
    c.email AS `Email`,
    e.title AS `Título de la Experiencia`,
    m.municipality_name AS `Municipio de Ubicación`,
    s.activity_date AS `Fecha de la Actividad`,
    b.total_amount AS `Monto Total Pagado`
FROM Clients c
INNER JOIN Bookings b ON c.client_id = b.client_id
INNER JOIN Schedules s ON b.schedule_id = s.schedule_id
INNER JOIN Experiences e ON s.experience_id = e.experience_id
INNER JOIN Municipalities m ON e.municipality_id = m.municipality_id
INNER JOIN Departments d ON m.department_id = d.department_id
WHERE d.department_name = 'Sucre'
  AND b.status IN ('CONFIRMED', 'COMPLETED')
ORDER BY s.activity_date DESC;

-- 2. Reporte de acogida por operador y experiencia en el último trimestre
SELECT 
    o.business_name AS `Operador Turístico`,
    e.title AS `Título de la Experiencia`,
    COUNT(b.booking_id) AS `Total de Reservas Registradas`,
    SUM(b.people_count) AS `Personas Totales Acumuladas`,
    SUM(b.total_amount) AS `Ingreso Bruto Generado`
FROM Operators o
INNER JOIN Experiences e ON o.operator_id = e.operator_id
INNER JOIN Schedules s ON e.experience_id = s.experience_id
INNER JOIN Bookings b ON s.schedule_id = b.schedule_id
WHERE b.booking_date >= DATE_SUB((SELECT MAX(booking_date) FROM Bookings), INTERVAL 3 MONTH)
  AND b.status <> 'CANCELLED'
GROUP BY o.operator_id, o.business_name, e.experience_id, e.title
ORDER BY `Ingreso Bruto Generado` DESC;

-- 3. Demanda turística y calidad del servicio por municipio
SELECT 
    m.municipality_name AS `Municipio de Localizacion`,
    COUNT(DISTINCT b.booking_id) AS `Reservas Total Confirmadas`,
    SUM(b.people_count) AS `Total Visistantes`,
    ROUND(AVG(r.star_rating), 2) AS `Promedio de Estrellas`
FROM Municipalities m
INNER JOIN Experiences e ON m.municipality_id = e.municipality_id
INNER JOIN Operators o ON e.operator_id = o.operator_id
INNER JOIN Schedules s ON e.experience_id = s.experience_id
INNER JOIN Bookings b ON s.schedule_id = b.schedule_id
LEFT JOIN Reviews r ON b.booking_id = r.booking_id
WHERE b.status IN ('CONFIRMED', 'COMPLETED')
GROUP BY m.municipality_id, m.municipality_name
ORDER BY `Promedio de Estrellas` DESC;