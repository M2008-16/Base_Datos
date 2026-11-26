-- Creacion de la BD
DROP DATABASE IF EXISTS db_SucreRoutes;
CREATE DATABASE IF NOT EXISTS db_SucreRoutes;

-- Usar BD
USE db_SucreRoutes;

-- 1. Gestion de Roles y Usuarios
CREATE TABLE Roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL
)  COMMENT='Almacena los roles de acceso del sistema';

-- 2. TABLE: USERS
-- Entidad central que almacena las credenciales de acceso a la plataforma
CREATE TABLE Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE' , 'INACTIVE', 'BLOCKED')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)  COMMENT='Almacena las credenciales y el estado de la cuenta del usuario';

-- 3. INTERMEDIATE TABLE: USER_ROLES
-- Relación N:M entre Usuarios y Roles (Relación Otorgar)
CREATE TABLE User_Roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES Users (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (role_id)
        REFERENCES Roles (role_id)
        ON DELETE CASCADE ON UPDATE CASCADE
)  COMMENT='Relación N:M (Otorgar) entre Usuarios y Roles';

-- 4. TABLE: COUNTRIES
-- Información general de los países registrados
CREATE TABLE Countries (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL UNIQUE
) COMMENT='Almacena la información de los países';

-- 5. TABLE: DEPARTMENTS
-- Información de los departamentos o provincias pertenecientes a un país
CREATE TABLE Departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    country_id INT NOT NULL,

    -- Relación: Vincula el departamento con el país al que pertenece (Tabla Countries)
    FOREIGN KEY (country_id) 
    REFERENCES Countries(country_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Almacena los departamentos de un país (Relación Pertenecer)';

-- 6. TABLE: MUNICIPALITIES
-- Información de las ciudades o municipios pertenecientes a un departamento
CREATE TABLE Municipalities (
    municipality_id INT AUTO_INCREMENT PRIMARY KEY,
    municipality_name VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,

    -- Relación: Vincula el municipio con el departamento al que pertenece (Tabla Departments)
    FOREIGN KEY (department_id) 
    REFERENCES Departments(department_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Almacena los municipios de un departamento (Relación Pertenecer)';


-- 3. Actores de Sistema

-- 7. TABLE: CLIENT_TYPES
-- Clasificación o tipos de cliente/turista (Local, Extranjero, Corporativo, etc.)
CREATE TABLE Client_Types (
    client_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE
) COMMENT='Tipos de cliente (Tabla Tipo_Cliente)';

-- 8. TABLE: CLIENTS
-- Perfiles de los clientes/visitantes registrados en la plataforma
CREATE TABLE Clients (
    client_id INT AUTO_INCREMENT PRIMARY KEY,
    first_names VARCHAR(100) NOT NULL,
    last_names VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT UNIQUE NULL,
    client_type_id INT NOT NULL,

    -- Relación: Hereda/Conecta de manera 1:1 con la cuenta de usuario (Tabla Users)
    FOREIGN KEY (user_id) 
    REFERENCES Users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,

    -- Relación: Clasifica el cliente según su categoría (Tabla Client_Types)
    FOREIGN KEY (client_type_id) 
    REFERENCES Client_Types(client_type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Perfil de clientes/turistas';

-- 9. TABLE: OPERATORS
-- Entidad que representa a los operadores turísticos locales
CREATE TABLE Operators (
    operator_id INT AUTO_INCREMENT PRIMARY KEY,
    business_name VARCHAR(150) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(150) NOT NULL,
    user_id INT UNIQUE NULL,
    municipality_id INT NOT NULL,
    FOREIGN KEY (user_id)
        REFERENCES Users (user_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (municipality_id)
        REFERENCES Municipalities (municipality_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
)  COMMENT='Información del operador turístico';

-- 10. TABLE: GUIDES
-- Información de los guías turísticos disponibles para acompañar actividades
CREATE TABLE Guides (
    guide_id INT AUTO_INCREMENT PRIMARY KEY,
    first_names VARCHAR(100) NOT NULL,
    last_names VARCHAR(100) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_number VARCHAR(50) NOT NULL UNIQUE,
    phone VARCHAR(30),
    email VARCHAR(150) NOT NULL,
    specialty VARCHAR(100),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    user_id INT UNIQUE NULL,

    -- Relación: Conecta de manera 1:1 con la cuenta de usuario (Tabla Users)
    FOREIGN KEY (user_id) 
    REFERENCES Users(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT='Perfil del guía turístico';

-- 11. TABLE: ALLY_TYPES
-- Categorías o clases de aliados comerciales (Restaurantes, Hoteles, Transporte)
CREATE TABLE Ally_Types (
    ally_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) COMMENT='Tipos de socios o aliados comerciales';

-- 12. TABLE: ALLIES
-- Prestadores de servicios asociados y aliados de la región
CREATE TABLE Allies (
    ally_id INT AUTO_INCREMENT PRIMARY KEY,
    trade_name VARCHAR(150) NOT NULL,
    document_number VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(150) NOT NULL,
    remarks TEXT,
    user_id INT UNIQUE NULL,
    ally_type_id INT NOT NULL,

    -- Relación: Conecta de manera 1:1 con la cuenta de usuario (Tabla Users)
    FOREIGN KEY (user_id) 
    REFERENCES Users(user_id) ON DELETE SET NULL ON UPDATE CASCADE,

    -- Relación: Clasifica el aliado dentro de un tipo comercial (Tabla Ally_Types)
    FOREIGN KEY (ally_type_id) 
    REFERENCES Ally_Types(ally_type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Perfil del aliado comercial';


-- 4. ATRACTIVOS, CATEGORÍAS Y SERVICIOS

-- 13. TABLE: ATTRACTION_TYPES
-- Tipos de atractivos turísticos (Natural, Cultural, Religioso, Histórico, etc.)
CREATE TABLE Attraction_Types (
    attraction_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) COMMENT='Tipos de atractivos turísticos';

-- 14. TABLE: ATTRACTIONS
-- Sitios o atractivos turísticos representativos de los municipios
CREATE TABLE Attractions (
    attraction_id INT AUTO_INCREMENT PRIMARY KEY,
    attraction_name VARCHAR(150) NOT NULL,
    description TEXT,
    location VARCHAR(255),
    importance_level VARCHAR(100),
    attraction_type_id INT NOT NULL,
    municipality_id INT NOT NULL,

    -- Relación: Clasifica el atractivo por su tipo (Tabla Attraction_Types)
    FOREIGN KEY (attraction_type_id) 
    REFERENCES Attraction_Types(attraction_type_id) ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relación: Ubica el atractivo dentro de un municipio (Tabla Municipalities)
    FOREIGN KEY (municipality_id) 
    REFERENCES Municipalities(municipality_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Atractivos turísticos locales';

-- 15. TABLE: CATEGORIES
-- Categorización global de las experiencias ofrecidas
CREATE TABLE Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) COMMENT='Categorías de las experiencias turísticas';

-- 16. TABLE: SERVICE_TYPES
-- Tipos de servicios complementarios (Gastronomía, Logística, Equipamiento)
CREATE TABLE Service_Types (
    service_type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
) COMMENT='Clasificación de servicios';

-- 17. TABLE: SERVICES
-- Catálogo de servicios ofertables para integrar en las experiencias
CREATE TABLE Services (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(150) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    service_type_id INT NOT NULL,

    -- Relación: Clasifica el servicio dentro de un tipo de servicio (Tabla Service_Types)
    FOREIGN KEY (service_type_id) 
    REFERENCES Service_Types(service_type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Catálogo general de servicios (Tabla Servicios)';


-- 5. Experiencias y Relaciones

-- 18. TABLE: EXPERIENCES
-- Catálogo de paquetes/rutas turísticas diseñadas y publicadas por los operadores
CREATE TABLE Experiences (
    experience_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL CHECK (price >= 0),
    duration VARCHAR(50) NOT NULL,
    max_capacity INT NOT NULL CHECK (max_capacity > 0),
    publication_date DATE DEFAULT (CURRENT_DATE),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    participation_conditions TEXT,
    characteristics TEXT,
    operator_id INT NOT NULL,
    category_id INT NOT NULL,
    municipality_id INT,
    

    -- Relación: Identifica qué operador publica la experiencia (Tabla Operators)
    FOREIGN KEY (operator_id) 
    REFERENCES Operators(operator_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Relación: Identificar las experiencias en un municipio
    FOREIGN KEY (municipality_id) 
    REFERENCES Municipalities(municipality_id) ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relación: Clasifica la experiencia en una categoría específica (Tabla Categories)
    FOREIGN KEY (category_id) 
    REFERENCES Categories(category_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Paquetes y experiencias turísticas publicadas';

-- 19. INTERMEDIATE TABLE: EXPERIENCE_ATTRACTIONS
-- Relación N:M entre Atractivos y Experiencias (Relación Tener)
CREATE TABLE Experience_Attractions (
    attraction_id INT NOT NULL,
    experience_id INT NOT NULL,

    -- Relación: Asocia el atractivo que forma parte de la experiencia (Tabla Attractions)
    FOREIGN KEY (attraction_id) 
    REFERENCES Attractions(attraction_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Asocia la experiencia con sus atractivos incluidos (Tabla Experiences)
    FOREIGN KEY (experience_id) 
    REFERENCES Experiences(experience_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Relación N:M (Tener) entre Atractivos y Experiencias';

-- 20. INTERMEDIATE TABLE: EXPERIENCE_SERVICES
-- Relación N:M entre Servicios y Experiencias (Relación Aportar)
CREATE TABLE Experience_Services (
    resource_id INT NOT NULL,
    experience_id INT NOT NULL,
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    remarks TEXT,

    -- Relación: Asocia el servicio que complementa la experiencia (Tabla Services)
    FOREIGN KEY (resource_id) 
    REFERENCES Services(resource_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Asocia la experiencia con sus servicios incluidos (Tabla Experiences)
    FOREIGN KEY (experience_id) 
    REFERENCES Experiences(experience_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Relación N:M (Aportar) entre Servicios y Experiencias';

-- 21. INTERMEDIATE TABLE: ALLY_EXPERIENCES
-- Relación N:M entre Aliados y Experiencias (Relación Tener)
CREATE TABLE Ally_Experiences (
    ally_id INT NOT NULL,
    experience_id INT NOT NULL,
    service_detail VARCHAR(150),
    remarks TEXT,

    -- Relación: Identifica qué aliado provee servicios a la experiencia (Tabla Allies)
    FOREIGN KEY (ally_id) 
    REFERENCES Allies(ally_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Asocia la experiencia con los aliados participantes (Tabla Experiences)
    FOREIGN KEY (experience_id) 
    REFERENCES Experiences(experience_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Relación N:M (Tener) entre Aliados y Experiencias';


-- 6. Programaciones, Rservas y Auditoria

-- 22. TABLE: SCHEDULES
-- Salidas o fechas concretas programadas para ofertar una experiencia
CREATE TABLE Schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    activity_date DATE NOT NULL,
    start_time TIME NOT NULL,
    total_slots INT NOT NULL CHECK (total_slots > 0),
    available_slots INT NOT NULL CHECK (available_slots >= 0),
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
    experience_id INT NOT NULL,

    -- Relación: Asocia la salida programada con su experiencia original (Tabla Experiences)
    FOREIGN KEY (experience_id) 
    REFERENCES Experiences(experience_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Fechas y horarios disponibles (Tabla Programaciones)';

-- 23. INTERMEDIATE TABLE: GUIDE_SCHEDULES
-- Relación N:M entre Guías y Programaciones (Relación Participar)
CREATE TABLE Guide_Schedules (
    guide_id INT NOT NULL,
    schedule_id INT NOT NULL,
    remarks TEXT,

    -- Relación: Asocia el guía con la salida específica asignada (Tabla Guides)
    FOREIGN KEY (guide_id) 
    REFERENCES Guides(guide_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Asocia la programación con el guía encargado (Tabla Schedules)
    FOREIGN KEY (schedule_id) 
    REFERENCES Schedules(schedule_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Relación N:M (Participar) entre Guías y Programaciones';

-- 24. TABLE: BOOKINGS
-- Transacción de reserva efectuada por un cliente para una salida específica
CREATE TABLE Bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    people_count INT NOT NULL CHECK (people_count > 0),
    total_amount DECIMAL(12, 2) NOT NULL CHECK (total_amount >= 0),
    remarks TEXT,
    schedule_id INT NOT NULL,
    client_id INT NOT NULL,

    -- Relación: Enlaza la reserva con la salida/programación elegida (Tabla Schedules)
    FOREIGN KEY (schedule_id) 
    REFERENCES Schedules(schedule_id) ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relación: Identifica al cliente/turista que realiza la reserva (Tabla Clients)
    FOREIGN KEY (client_id) 
    REFERENCES Clients(client_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Registro general de reservas (Tabla Reservas)';

-- Agregaer la comula status con una constrain
ALTER TABLE Bookings 
ADD COLUMN status VARCHAR(20) DEFAULT 'PENDING',
ADD CONSTRAINT chk_bookings_status 
    CHECK (status IN ('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED'));

-- 25. TABLE: REVIEWS
-- Calificación y comentario sobre la experiencia al completar una reserva
CREATE TABLE Reviews (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    star_rating INT NOT NULL CHECK (star_rating BETWEEN 1 AND 5),
    comment TEXT,
    review_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    booking_id INT UNIQUE NOT NULL,
    experience_id INT NOT NULL,

    -- Relación: Garantiza que la reseña pertenezca a una reserva realizada (Tabla Bookings)
    FOREIGN KEY (booking_id) 
    REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Asocia la reseña con la experiencia evaluada (Tabla Experiences)
    FOREIGN KEY (experience_id) 
    REFERENCES Experiences(experience_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Valoraciones de los usuarios sobre las actividades (Tabla Valoraciones)';

-- 26. TABLE: BOOKING_HISTORY
-- Registro de trazabilidad/auditoría sobre cambios de estado en las reservas
CREATE TABLE Booking_History (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    description TEXT,
    event_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    previous_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    booking_id INT NOT NULL,
    user_id INT NULL,

    -- Relación: Vincula el log de auditoría con la reserva implicada (Tabla Bookings)
    FOREIGN KEY (booking_id) 
    REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,

    -- Relación: Identifica el usuario que produjo el cambio o evento (Tabla Users)
    FOREIGN KEY (user_id) 
    REFERENCES Users(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) COMMENT='Histórico de eventos y estados de las reservas (Tabla Historial_Reservas)';

-- 27. TABLE: CANCELLATIONS
-- Registro administrativo de las cancelaciones efectivas de reservas
CREATE TABLE Cancellations (
    cancellation_id INT AUTO_INCREMENT PRIMARY KEY,
    cancellation_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    reason TEXT NOT NULL,
    requested_by VARCHAR(100) NOT NULL,
    applies_fee BOOLEAN DEFAULT FALSE,
    booking_id INT UNIQUE NOT NULL,

    -- Relación: Enlaza la solicitud directamente a la reserva cancelada (Tabla Bookings)
    FOREIGN KEY (booking_id) 
    REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Información de cancelaciones (Tabla Cancelacion)';

-- 28. TABLE: CANCELLATION_AUDITS
-- Auditoría contable/financiera de los cobros o pérdidas por cancelación
CREATE TABLE Cancellation_Audits (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    cancellation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    db_user VARCHAR(100) NOT NULL,
    lost_amount_cop DECIMAL(10,2) NOT NULL,
    reason VARCHAR(255),
    
    -- Relación: Enlaza el informe contable con la reserva origen (Tabla Bookings)
    FOREIGN KEY (booking_id) 
    REFERENCES Bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Auditoría de pérdidas por cancelación (Tabla Auditoria_cancelacion)';


-- 7. Pagos

-- 29. TABLE: PAYMENT_METHODS
-- Canales o pasarelas de pago admitidas (Tarjetas, PSE, Efectivo, Transferencia)
CREATE TABLE Payment_Methods (
    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE'))
) COMMENT='Métodos de pago aceptados (Tabla Metodo_Pago)';

-- 30. TABLE: PAYMENTS
-- Registro del cobro principal o pago asociado a una reserva
CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    payment_amount DECIMAL(12, 2) NOT NULL CHECK (payment_amount >= 0),
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    currency VARCHAR(10) DEFAULT 'COP',
    booking_id INT NOT NULL,
    payment_method_id INT NOT NULL,

    -- Relación: Asocia la transacción monetaria con la reserva (Tabla Bookings)
    FOREIGN KEY (booking_id) 
    REFERENCES Bookings(booking_id) ON DELETE RESTRICT ON UPDATE CASCADE,

    -- Relación: Asocia la transacción con la pasarela o forma elegida (Tabla Payment_Methods)
    FOREIGN KEY (payment_method_id) 
    REFERENCES Payment_Methods(payment_method_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Registro de pagos (Tabla Pagos)';

-- 31. TABLE: PAYMENT_TRANSACTIONS
-- Comprobantes o referencias técnicas reportadas por la entidad financiera
CREATE TABLE Payment_Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_reference VARCHAR(100) NOT NULL UNIQUE,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
    transaction_type VARCHAR(50) NOT NULL,
    transaction_status VARCHAR(20) DEFAULT 'SUCCESS' CHECK (transaction_status IN ('PENDING', 'SUCCESS', 'FAILED')),
    payment_id INT NOT NULL,

    -- Relación: Asocia la referencia técnica con su registro contable principal (Tabla Payments)
    FOREIGN KEY (payment_id) 
    REFERENCES Payments(payment_id) ON DELETE CASCADE ON UPDATE CASCADE
) COMMENT='Detalles bancarios de la pasarela (Tabla Transacion_Pago)';

-- 32. TABLE: REFUNDS
-- Registro contable de devoluciones de dinero por cancelaciones aplicables
CREATE TABLE Refunds (
    refund_id INT AUTO_INCREMENT PRIMARY KEY,
    request_reference VARCHAR(100) NOT NULL,
    refund_amount DECIMAL(12, 2) NOT NULL CHECK (refund_amount >= 0),
    refund_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    reason TEXT NOT NULL,
    refund_status VARCHAR(20) DEFAULT 'PENDING' CHECK (refund_status IN ('PENDING', 'COMPLETED', 'REJECTED')),
    payment_id INT UNIQUE NOT NULL,

    -- Relación: Asocia el reembolso directamente al pago original (Tabla Payments)
    FOREIGN KEY (payment_id) 
    REFERENCES Payments(payment_id) ON DELETE RESTRICT ON UPDATE CASCADE
) COMMENT='Registro de reembolsos efectuados (Tabla Rembolso)';


-- 33. CLAVES PRIMARIAS COMPUESTAS PARA TABLAS INTERMEDIAS
-- Evitan que se registren relaciones N:M duplicadas.

-- Relacion entre usuarios y roles.
ALTER TABLE User_Roles
ADD CONSTRAINT pk_user_roles
PRIMARY KEY (user_id, role_id);

-- Relacion entre atractivos y experiencias.
ALTER TABLE Experience_Attractions
ADD CONSTRAINT pk_experience_attractions
PRIMARY KEY (experience_id, attraction_id);

-- Relacion entre servicios y experiencias.
ALTER TABLE Experience_Services
ADD CONSTRAINT pk_experience_services
PRIMARY KEY (experience_id, resource_id);

-- Relacion entre aliados y experiencias.
ALTER TABLE Ally_Experiences
ADD CONSTRAINT pk_ally_experiences
PRIMARY KEY (experience_id, ally_id);

-- Relacion entre guias y programaciones.
ALTER TABLE Guide_Schedules
ADD CONSTRAINT pk_guide_schedules
PRIMARY KEY (schedule_id, guide_id);


-- 34. INDICES Y RESTRICCIONES GEOGRAFICAS
-- Evitan duplicidad de departamentos y municipios.

-- Evita registrar departamentos con el mismo nombre
-- dentro de un mismo pais.
ALTER TABLE Departments
ADD CONSTRAINT uq_department_country
UNIQUE (country_id, department_name);

-- Evita registrar municipios con el mismo nombre
-- dentro de un mismo departamento.
ALTER TABLE Municipalities
ADD CONSTRAINT uq_municipality_department
UNIQUE (department_id, municipality_name);


-- 35. INDICES PARA CLIENTES Y ACTORES DEL SISTEMA
-- Facilitan las busquedas de perfiles y clasificaciones.

-- Buscar clientes mediante su correo electronico.
CREATE INDEX idx_clients_email
ON Clients (email);

-- Consultar clientes segun su fecha de registro.
CREATE INDEX idx_clients_registration
ON Clients (registration_date);

-- Buscar operadores segun su municipio.
CREATE INDEX idx_operators_municipality
ON Operators (municipality_id);

-- Filtrar guias segun su estado.
CREATE INDEX idx_guides_status
ON Guides (status);

-- Consultar aliados segun su tipo comercial.
CREATE INDEX idx_allies_type
ON Allies (ally_type_id);


-- 36. INDICES PARA EXPERIENCIAS Y ATRACTIVOS TURISTICOS
-- Optimizan las busquedas y filtros de experiencias.

-- Buscar experiencias por operador y estado.
CREATE INDEX idx_experiences_operator_status
ON Experiences (operator_id, status);

-- Buscar experiencias por categoria y estado.
CREATE INDEX idx_experiences_category_status
ON Experiences (category_id, status);

-- Buscar experiencias por municipio y estado.
CREATE INDEX idx_experiences_municipality_status
ON Experiences (municipality_id, status);

-- Buscar atractivos por municipio y tipo de atractivo.
CREATE INDEX idx_attractions_municipality_type
ON Attractions (municipality_id, attraction_type_id);

-- Buscar servicios por tipo y estado.
CREATE INDEX idx_services_type_status
ON Services (service_type_id, status);



-- 37. INDICES PARA PROGRAMACIONES
-- Optimizan la consulta de salidas y fechas disponibles.

-- Consultar programaciones de una experiencia
-- ordenadas por fecha y estado.
CREATE INDEX idx_schedules_experience_date_status
ON Schedules (experience_id, activity_date, status);

-- Consultar programaciones segun fecha y estado.
CREATE INDEX idx_schedules_date_status
ON Schedules (activity_date, status);

-- Evitar programar dos salidas de la misma experiencia
-- en la misma fecha y hora.
ALTER TABLE Schedules
ADD CONSTRAINT uq_schedule_experience_datetime
UNIQUE (experience_id, activity_date, start_time);



-- 38. INDICES PARA RESERVAS
-- Facilitan el control y seguimiento de las reservas.

-- Consultar reservas segun la programacion y su estado.
CREATE INDEX idx_bookings_schedule_status
ON Bookings (schedule_id, status);

-- Consultar el historial de reservas de cada cliente
-- utilizando su identificador y fecha de reserva.
CREATE INDEX idx_bookings_client_date
ON Bookings (client_id, booking_date);

-- 39. INDICES PARA PAGOS Y TRANSACCIONES FINANCIERAS
-- Optimizan las consultas relacionadas con los pagos.

-- Consultar pagos asociados a una reserva y su estado.
CREATE INDEX idx_payments_booking_status
ON Payments (booking_id, payment_status);

-- Consultar pagos segun su fecha de realizacion.
CREATE INDEX idx_payments_date
ON Payments (payment_date);

-- Consultar transacciones segun el pago y su estado.
CREATE INDEX idx_transactions_payment_status
ON Payment_Transactions (payment_id, transaction_status);


-- 40. INDICES PARA HISTORIAL Y AUDITORIA
-- Facilitan el seguimiento de eventos y cancelaciones.

-- Consultar el historial de una reserva por fecha.
CREATE INDEX idx_booking_history_booking_date
ON Booking_History (booking_id, event_date);

-- Consultar auditorias de cancelaciones asociadas a reservas.
CREATE INDEX idx_cancellation_audits_booking
ON Cancellation_Audits (booking_id);


-- 41. INDICES PARA VALORACIONES
-- Facilitan la consulta de opiniones por experiencia.

-- Consultar las valoraciones correspondientes a una experiencia.
CREATE INDEX idx_reviews_experience
ON Reviews (experience_id);


-- 42. VERIFICACION DE LOS INDICES CREADOS
-- Permite comprobar los indices desde MySQL Workbench.

-- Verificar indices de reservas.
SHOW INDEX FROM Bookings;

-- Verificar indices de experiencias.
SHOW INDEX FROM Experiences;

-- Verificar indices de programaciones.
SHOW INDEX FROM Schedules;

-- Verificar indices de pagos.
SHOW INDEX FROM Payments;

-- Verificar indices de transacciones.
SHOW INDEX FROM Payment_Transactions;

-- Verificar indices de clientes.
SHOW INDEX FROM Clients;

-- Verificar indices de relaciones intermedias.
SHOW INDEX FROM User_Roles;
SHOW INDEX FROM Experience_Attractions;
SHOW INDEX FROM Experience_Services;
SHOW INDEX FROM Ally_Experiences;
SHOW INDEX FROM Guide_Schedules;

 