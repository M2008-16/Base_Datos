-- 1. Experiencias publicadas sin reservas activas
SELECT 
    e.experience_id AS `ID Experiencia`,
    e.title AS `Título de la Experiencia`,
    m.municipality_name AS `Municipio`,
    e.price AS `Precio Base`
FROM Experiences e
INNER JOIN Municipalities m ON e.municipality_id = m.municipality_id
WHERE e.status = 'ACTIVE'
  AND NOT EXISTS (
      SELECT 1
      FROM Schedules s
      INNER JOIN Bookings b ON s.schedule_id = b.schedule_id
      WHERE s.experience_id = e.experience_id
        AND b.status <> 'CANCELLED'
  )
ORDER BY e.experience_id ASC;

-- 2. Experiencias destacadas por encima del promedio departamental
SELECT 
    e.title AS `Título de la Experiencia`,
    SUM(b.people_count) AS `Total de Visitantes`
FROM Experiences e
INNER JOIN Municipalities m ON e.municipality_id = m.municipality_id
INNER JOIN Departments d ON m.department_id = d.department_id
INNER JOIN Schedules s ON e.experience_id = s.experience_id
INNER JOIN Bookings b ON s.schedule_id = b.schedule_id
WHERE d.department_name = 'Sucre'
  AND b.status IN ('CONFIRMED', 'COMPLETED')
GROUP BY e.experience_id, e.title
HAVING SUM(b.people_count) > (
    SELECT AVG(sub.total_visitantes)
    FROM (
        SELECT SUM(b2.people_count) AS total_visitantes
        FROM Experiences e2
        INNER JOIN Municipalities m2 ON e2.municipality_id = m2.municipality_id
        INNER JOIN Departments d2 ON m2.department_id = d2.department_id
        INNER JOIN Schedules s2 ON e2.experience_id = s2.experience_id
        INNER JOIN Bookings b2 ON s2.schedule_id = b2.schedule_id
        WHERE d2.department_name = 'Sucre'
          AND b2.status IN ('CONFIRMED', 'COMPLETED')
        GROUP BY e2.experience_id
    ) AS sub
)
ORDER BY `Total de Visitantes` DESC;


-- 3. Experiencias que superan el promedio de su propia categoría
SELECT 
    e1.experience_id AS id_experiencia,
    e1.title AS titulo_experiencia,
    c.category_name AS categoria,
    SUM(b1.people_count) AS total_personas_atendidas
FROM Experiences e1
INNER JOIN Categories c ON e1.category_id = c.category_id
INNER JOIN Schedules s1 ON e1.experience_id = s1.experience_id
INNER JOIN Bookings b1 ON s1.schedule_id = b1.schedule_id
GROUP BY e1.experience_id, e1.title, c.category_name, e1.category_id
HAVING SUM(b1.people_count) > (
    -- Subconsulta correlacionada: calcula el promedio de personas atendidas solo para la categoría actual (e1.category_id)
    SELECT AVG(cat_totals.personas_experiencia)
    FROM (
        SELECT SUM(b2.people_count) AS personas_experiencia
        FROM Experiences e2
        INNER JOIN Schedules s2 ON e2.experience_id = s2.experience_id
        INNER JOIN Bookings b2 ON s2.schedule_id = b2.schedule_id
        WHERE e2.category_id = e1.category_id -- <--- Relación de correlación externa / interna
        GROUP BY e2.experience_id
    ) AS cat_totals
)
ORDER BY c.category_name ASC, total_personas_atendidas DESC;