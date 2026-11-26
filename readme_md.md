# Sabores y Rutas de Sucre (`db_SucreRoutes`)

Plataforma integral de gestión turística, gastronómica y cultural para el departamento de Sucre, Colombia. Diseñada bajo una arquitectura de **persistencia políglota (híbrida)** que garantiza consistencia transaccional estricta (ACID) para reservas y pagos, flexibilidad documental para catálogos dinámicos y búsqueda semántica en lenguaje natural.

Este proyecto está alineado con el **Objetivo de Desarrollo Sostenible 9 (ODS 9)** —Metas 9.1, 9.3 y 9.5—, promoviendo infraestructuras resilientes, inclusión económica de operadores locales y adopción de tecnologías emergentes.

---

## Arquitectura del Sistema

El ecosistema de datos se divide en tres motores especializados sincronizados mediante correlación de identificadores (`experience_id`):

1. **Núcleo Relacional (`MySQL 8` / `MariaDB` en AWS RDS):**
   * Esquema normalizado en Tercera Forma Normal (**3FN**) compuesto por **32 tablas** distribuidas en 7 módulos funcionales.
   * Control estricto de cupos, reservas, pagos, cancelaciones, auditoría y control de acceso basado en roles (DCL).
   * Lógica de negocio encapsulada en **Vistas**, **Funciones**, **Procedimientos Almacenados** y **Triggers**.
2. **Catálogo Dinámico NoSQL (`MongoDB` - `db_SucreRoutes_NoSQL`):**
   * Colección `experiencias_catalogo` con documentos BSON polimórficos para atributos variables (itinerarios por horas, menús, equipo recomendado, restricciones climáticas y coordenadas GeoJSON).
   * Escalabilidad horizontal configurada mediante *Shard Key* compuesta `{ municipio: 1, experience_id_sql: "hashed" }`.
3. **Motor de Búsqueda Semántica (`Qdrant` Vector Database):**
   * Indexación de descripciones turísticas mediante *embeddings* y recuperación por similitud de coseno para consultas en lenguaje natural.

---

## Estructura de Scripts SQL

El despliegue del esquema relacional sigue un orden secuencial estricto para respetar las dependencias referenciales:

```text
sql/
├── 01_DDL_SucreRoutes.sql         # Creación de esquema, 32 tablas, PK, FK, CHECK e índices
├── 02_DML_JOIN_SucreRoutes.sql    # Consultas analíticas y reportes operativos (JOINs)
├── 03_DML_SUBQUERIES_SucreRoutes.sql # Subconsultas escalares, correlacionadas y NOT EXISTS
├── 04_DCL_SucreRoutes.sql         # Creación de roles, usuarios y privilegios mínimos
├── 05_TCL_SucreRoutes.sql         # Flujos transaccionales (COMMIT, ROLLBACK, SAVEPOINT)
├── 06_VIEWS_SucreRoutes.sql       # Vistas de disponibilidad web, operación y KPIs
├── 07_FUNCTIONS_SucreRoutes.sql   # Funciones escalares de cupos, calificaciones y reembolsos
├── 08_PROCEDURES_SucreRoutes.sql  # Procedimientos almacenados con manejo de excepciones
└── 09_TRIGGERS_SucreRoutes.sql    # Disparadores automáticos de inventario y auditoría
```

---

## Instrucciones de Despliegue

### 1. Requisitos Previos
* **Motor Relacional:** MySQL 8.0+ o MariaDB 10.6+
* **Cliente SQL:** MySQL Workbench 8.0+ o cliente CLI `mysql`
* **NoSQL (Opcional para módulo híbrido):** MongoDB Community / MongoDB Atlas 6.0+
* **Motor Vectorial (Opcional para módulo semántico):** Qdrant (Docker o Cloud)

### 2. Despliegue Local (MySQL 8 / MariaDB)

1. Clona o descarga los scripts SQL del repositorio.
2. Inicia sesión en tu instancia local como usuario administrador (`root`):
   ```bash
   mysql -u root -p
   ```
3. Crea la base de datos y selecciona el esquema:
   ```sql
   CREATE DATABASE IF NOT EXISTS db_SucreRoutes
   CHARACTER SET utf8mb4
   COLLATE utf8mb4_unicode_ci;
   USE db_SucreRoutes;
   ```
4. Ejecuta los scripts en orden numérico desde MySQL Workbench o vía terminal:
   ```bash
   mysql -u root -p db_SucreRoutes < 01_DDL_SucreRoutes.sql
   # Cargar datos maestros (DML inicial) antes de ejecutar vistas y pruebas
   mysql -u root -p db_SucreRoutes < 04_DCL_SucreRoutes.sql
   mysql -u root -p db_SucreRoutes < 06_VIEWS_SucreRoutes.sql
   mysql -u root -p db_SucreRoutes < 07_FUNCTIONS_SucreRoutes.sql
   mysql -u root -p db_SucreRoutes < 08_PROCEDURES_SucreRoutes.sql
   mysql -u root -p db_SucreRoutes < 09_TRIGGERS_SucreRoutes.sql
   ```

### 3. Despliegue en la Nube (AWS RDS - MariaDB)

1. **Aprovisionamiento en AWS:**
   * En la consola de **Amazon RDS**, crea una instancia con motor **MariaDB** (plantilla Capa Gratuita `db.t4g.micro`).
   * Configura el *Security Group* permitiendo tráfico entrante TCP en el puerto **`3306`** desde las direcciones IP autorizadas.
2. **Adaptación de Intercalación (*Collation*):**
   * Si migras desde un volcado (*dump*) generado en MySQL 8, reemplaza las referencias de intercalación `utf8mb4_0900_ai_ci` por `utf8mb4_unicode_ci` para garantizar compatibilidad total con MariaDB.
3. **Importación del Esquema y Datos:**
   * Conéctate desde MySQL Workbench usando el *Endpoint* proporcionado por AWS RDS:
     * **Hostname:** `maridbparcial.cfyuwu4gc1ht.us-east-2.rds.amazonaws.com` *(o el endpoint de tu instancia)*
     * **Port:** `3306`
     * **Username:** `admin`
   * Ve a **Server → Data Import**, selecciona el archivo `.sql` autocontenido (`Dump Structure and Data`) e importa sobre el esquema destino.
4. **Verificación Post-Despliegue:**
   * Comprueba que las **32 tablas**, vistas (`v_available_web_experiences`, `v_operator_operations_summary`, `v_experiences_performance_kpi`), procedimientos almacenados y triggers estén activos.

### 4. Despliegue del Catálogo NoSQL (MongoDB)

1. Conéctate a tu instancia de MongoDB (`mongosh`) y selecciona la base de datos:
   ```javascript
   use db_SucreRoutes_NoSQL;
   ```
2. Inserta los documentos iniciales en la colección `experiencias_catalogo` vinculando el campo `experience_id_sql` con los IDs generados en la tabla `Experiences` de MariaDB/MySQL.
3. *(Opcional para clústeres)* Habilita el particionado en la colección:
   ```javascript
   sh.enableSharding("db_SucreRoutes_NoSQL");
   sh.shardCollection("db_SucreRoutes_NoSQL.experiencias_catalogo", { municipio: 1, experience_id_sql: "hashed" });
   ```

---

## Credenciales de Prueba y Roles (DCL)

Para validar el principio de **mínimo privilegio** y la segregación de funciones configurada en `04_DCL_SucreRoutes.sql`, utiliza las siguientes cuentas de prueba:

| Usuario MySQL/MariaDB | Contraseña | Rol Asignado | Permisos Habilitados | Restricciones de Seguridad |
| :--- | :--- | :--- | :--- | :--- |
| `usr_promotor1`@`localhost` | `Promotor2026*` | `rol_promotor_turistico` | `SELECT` en `Experiences`, `Categories`, `Schedules` | Denegado `INSERT`, `UPDATE`, `DELETE` en todo el esquema. |
| `usr_agente1`@`localhost` | `Agente2026*` | `rol_agente_reservas` | `INSERT`, `UPDATE` en `Bookings`, `Payments` | Revocado `DELETE` en `Bookings`; sin acceso de escritura a catálogo u operadores. |
| `usr_admin_contenido1`@`localhost` | `AdminCont2026*` | `rol_admin_contenido` | `INSERT`, `UPDATE`, `DELETE` en `Experiences`, `Schedules`, `Operators` | Sin acceso de escritura a tablas financieras (`Payments`, `Refunds`). |

> **Nota de Seguridad:** Estas credenciales están destinadas exclusivamente a entornos académicos y de pruebas funcionales. En entornos de producción se recomienda rotar las claves y gestionar secretos mediante **AWS Secrets Manager**.

---

## Autores y Créditos

* **Equipo de Desarrollo:**
  * Álvarez Lyons Juan David
  * Contreras Pacheco Isaac David
  * Farfan Canchila Joseph
  * Jimenez Rocha Martin Fernando
  * Pérez Rivera Isaias Andrés
* **Docente:** María Angelica García Medina
* **Institución:** Corporación Universitaria del Caribe – CECAR (Facultad de Ciencias Básicas e Ingeniería – Ingeniería de Sistemas, Sincelejo, Sucre, 2026-II)