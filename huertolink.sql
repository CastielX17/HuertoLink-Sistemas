-- ============================================================
-- HUERTOLINK MVP — Base de Datos MySQL
-- Archivo  : /db/huertolink.sql
-- Proyecto : Desarrollo de Soluciones Tecnológicas Asistidas por IA
-- UCN Ciencias Empresariales · Ingeniería Comercial
-- Profesores: Boris Bugueño – Alejandro Paolini
-- Caso 05  : Huerto Herido — La frustración del Huerto Urbano
-- ============================================================
-- Versión  : 1.0.0  |  Fecha: 2026-06-18
-- ============================================================
-- DESCRIPCIÓN:
--   Script DDL + DML completo para el MVP de HuertoLink.
--   Incluye estructura relacional normalizada, restricciones
--   de integridad referencial, índices optimizados para el
--   dashboard y dataset de prueba para todos los módulos.
--
-- MÓDULOS CUBIERTOS:
--   ✓ Gestión de usuarios y roles (gobernanza policéntrica)
--   ✓ Catálogo de cultivos con color para mapa 2D
--   ✓ Parcelas — cuadrícula Square Foot Gardening 4×5
--   ✓ Siembras — previene doble siembra (conflicto del caso)
--   ✓ Turnos de riego y confirmaciones (soporte Offline-First)
--   ✓ Cosechas y distribución comunitaria
--   ✓ Notificaciones (reemplaza grupo de WhatsApp)
--   ✓ Historial de auditoría (trazabilidad total)
--   ✓ Observaciones e incidencias
--
-- DASHBOARD RESPONDE LAS 3 PREGUNTAS DEL CASO:
--   1. ¿Qué parcelas necesitan riego hoy y quién es responsable?
--   2. ¿Cuánto se cosechó este mes y cómo se reparte?
--   3. ¿Qué vecinos están más activos y cuáles no cumplen?
--
-- CONTRASEÑA DE PRUEBA: "Huerto2026!" (hash bcrypt factor 10)
--   CAMBIAR ANTES DE PRODUCCIÓN.
-- ============================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET time_zone = '-04:00';

-- ============================================================
-- SECCIÓN 1: BASE DE DATOS
-- ============================================================
DROP DATABASE IF EXISTS huertolink;
CREATE DATABASE huertolink
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci
    COMMENT 'HuertoLink — Gestión Digital de Huertos Urbanos Comunitarios';
USE huertolink;

-- ============================================================
-- SECCIÓN 2: DDL — TABLAS MAESTRAS
-- ============================================================

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: roles                                            │
-- │  Arquitectura policéntrica: Coordinadora > Vecino        │
-- │  Colaborador > Voluntario Ocasional                      │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE roles (
    id_rol       TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(50)      NOT NULL,
    descripcion  VARCHAR(255)     NOT NULL,
    nivel_acceso TINYINT UNSIGNED NOT NULL
                 COMMENT '1=Coordinadora  2=Vecino Colaborador  3=Voluntario Ocasional',
    activo       TINYINT(1)       NOT NULL DEFAULT 1,
    PRIMARY KEY  (id_rol),
    UNIQUE KEY   uq_roles_nombre (nombre),
    CONSTRAINT   chk_roles_nivel CHECK (nivel_acceso BETWEEN 1 AND 3)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Roles y niveles de acceso del sistema HuertoLink';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: cultivos                                         │
-- │  Catálogo de especies vegetales. El campo color_mapa     │
-- │  alimenta el mapa 2D interactivo del huerto.             │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE cultivos (
    id_cultivo            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    nombre_comun          VARCHAR(100)      NOT NULL,
    nombre_cientifico     VARCHAR(150)      NULL
                          COMMENT 'Mostrar solo con imagen adjunta (estándar UX inclusivo)',
    descripcion           TEXT              NULL,
    frecuencia_riego_dias TINYINT UNSIGNED  NOT NULL DEFAULT 2
                          COMMENT 'Cada cuántos días se debe regar',
    dias_hasta_cosecha    SMALLINT UNSIGNED NOT NULL DEFAULT 60
                          COMMENT 'Días aprox. desde siembra hasta cosecha',
    unidad_medida         VARCHAR(20)       NOT NULL DEFAULT 'kg'
                          COMMENT 'kg | unidad | manojo | litros',
    color_mapa            VARCHAR(7)        NOT NULL DEFAULT '#4CAF50'
                          COMMENT 'Color hexadecimal para representar en el mapa 2D',
    imagen_url            VARCHAR(500)      NULL,
    activo                TINYINT(1)        NOT NULL DEFAULT 1,
    creado_en             TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cultivo),
    UNIQUE KEY  uq_cultivos_nombre (nombre_comun)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de cultivos disponibles en el huerto comunitario';

-- ============================================================
-- SECCIÓN 3: DDL — TABLAS PRINCIPALES
-- ============================================================

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: usuarios                                         │
-- │  19 miembros: Doña Carmen + 18 vecinos.                  │
-- │  puntos_reputacion y logro_titulo implementan            │
-- │  gamificación cívica (Mentor, Historiador, Héroe).       │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE usuarios (
    id_usuario        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    nombre            VARCHAR(100)     NOT NULL,
    apellido          VARCHAR(100)     NOT NULL,
    email             VARCHAR(150)     NOT NULL,
    password_hash     VARCHAR(255)     NOT NULL
                      COMMENT 'Hash bcrypt de la contraseña (factor >= 10)',
    telefono          VARCHAR(20)      NULL,
    id_rol            TINYINT UNSIGNED NOT NULL DEFAULT 2,
    activo            TINYINT(1)       NOT NULL DEFAULT 1,
    puntos_reputacion INT UNSIGNED     NOT NULL DEFAULT 0
                      COMMENT 'Puntos acumulados por riegos, cosechas y jornadas',
    logro_titulo      VARCHAR(50)      NULL
                      COMMENT 'Título honorífico: Mentor | Historiador | Héroe de la Sequía',
    avatar_url        VARCHAR(500)     NULL,
    fecha_registro    TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso     TIMESTAMP        NULL,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY  uq_usuarios_email (email),
    INDEX idx_usuarios_rol     (id_rol),
    INDEX idx_usuarios_activo  (activo),
    INDEX idx_usuarios_puntos  (puntos_reputacion DESC)
          COMMENT 'Ranking de vecinos más activos en el dashboard',
    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (id_rol) REFERENCES roles (id_rol)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Vecinos registrados en HuertoLink (Coordinadora + 18 colaboradores)';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: parcelas                                         │
-- │  Mapa 2D del huerto: cuadrícula 4×5 (fila + columna).   │
-- │  Estado 'regalo' = Theft Plot anti-robo.                 │
-- │  Colores del dashboard (lógica backend):                 │
-- │    Azul=riego urgente  Verde=saludable  Amarillo=cosecha │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE parcelas (
    id_parcela          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    codigo              VARCHAR(20)   NOT NULL COMMENT 'Ej: P-01, P-02',
    nombre              VARCHAR(100)  NOT NULL,
    ubicacion_fila      TINYINT UNSIGNED NOT NULL COMMENT 'Eje Y de la cuadrícula',
    ubicacion_columna   TINYINT UNSIGNED NOT NULL COMMENT 'Eje X de la cuadrícula',
    area_m2             DECIMAL(5,2)  NOT NULL DEFAULT 1.00,
    estado              ENUM('disponible','ocupada','mantenimiento','abandonada','regalo')
                        NOT NULL DEFAULT 'disponible',
    id_usuario_asignado INT UNSIGNED  NULL,
    fecha_asignacion    DATE          NULL,
    es_publica          TINYINT(1)    NOT NULL DEFAULT 0
                        COMMENT '1=parcela comunitaria accesible a todos los miembros',
    descripcion         TEXT          NULL,
    creado_en           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_parcela),
    UNIQUE KEY  uq_parcelas_codigo   (codigo),
    UNIQUE KEY  uq_parcelas_posicion (ubicacion_fila, ubicacion_columna)
                COMMENT 'Impide dos parcelas en la misma celda del mapa',
    INDEX idx_parcelas_estado  (estado),
    INDEX idx_parcelas_usuario (id_usuario_asignado),
    CONSTRAINT fk_parcelas_usuarios
        FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Parcelas del huerto — cuadrícula 4×5 del mapa 2D interactivo';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: siembras                                         │
-- │  Registro de qué cultivo hay en cada parcela.            │
-- │  Previene la doble siembra: "dos personas sembraron      │
-- │  tomates el mismo día en el mismo espacio" (el caso).    │
-- │  Backend debe validar siembra activa antes de insertar.  │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE siembras (
    id_siembra             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_parcela             INT UNSIGNED NOT NULL,
    id_cultivo             INT UNSIGNED NOT NULL,
    id_usuario             INT UNSIGNED NOT NULL COMMENT 'Vecino que realizó la siembra',
    fecha_siembra          DATE         NOT NULL,
    fecha_estimada_cosecha DATE         NOT NULL,
    estado                 ENUM('en_preparacion','activa','cosechada','perdida')
                           NOT NULL DEFAULT 'activa',
    cantidad_sembrada      DECIMAL(8,2) NOT NULL DEFAULT 1.00,
    unidad_cantidad        VARCHAR(20)  NOT NULL DEFAULT 'plantas'
                           COMMENT 'plantas | semillas | m2 | gramos',
    notas                  TEXT         NULL,
    creado_en              TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_siembra),
    INDEX idx_siembras_parcela        (id_parcela),
    INDEX idx_siembras_cultivo        (id_cultivo),
    INDEX idx_siembras_usuario        (id_usuario),
    INDEX idx_siembras_estado         (estado),
    INDEX idx_siembras_parcela_estado (id_parcela, estado)
          COMMENT 'Qué hay sembrado ACTUALMENTE en una parcela (para validar doble siembra)',
    CONSTRAINT fk_siembras_parcelas
        FOREIGN KEY (id_parcela) REFERENCES parcelas (id_parcela)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_siembras_cultivos
        FOREIGN KEY (id_cultivo) REFERENCES cultivos (id_cultivo)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_siembras_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Historial de siembras — previene duplicación y da trazabilidad de cultivos';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: turnos_riego                                     │
-- │  Agenda de responsabilidades.                            │
-- │  Dashboard pregunta 1: "¿Quién riega hoy?"              │
-- │  Índice compuesto idx_turnos_dashboard optimiza la       │
-- │  consulta principal de la vista de inicio.               │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE turnos_riego (
    id_turno            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_parcela          INT UNSIGNED NOT NULL,
    id_usuario_asignado INT UNSIGNED NOT NULL,
    fecha_turno         DATE         NOT NULL,
    hora_inicio         TIME         NOT NULL DEFAULT '08:00:00',
    hora_fin            TIME         NOT NULL DEFAULT '09:00:00',
    estado              ENUM('pendiente','completado','omitido','cancelado')
                        NOT NULL DEFAULT 'pendiente',
    notas               TEXT         NULL,
    creado_en           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_turno),
    INDEX idx_turnos_parcela   (id_parcela),
    INDEX idx_turnos_usuario   (id_usuario_asignado),
    INDEX idx_turnos_fecha     (fecha_turno),
    INDEX idx_turnos_estado    (estado),
    INDEX idx_turnos_dashboard (fecha_turno, estado)
          COMMENT 'Índice compuesto — consulta principal del dashboard (turnos pendientes hoy)',
    CONSTRAINT fk_turnos_parcelas
        FOREIGN KEY (id_parcela) REFERENCES parcelas (id_parcela)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_turnos_usuarios
        FOREIGN KEY (id_usuario_asignado) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Programación de turnos de riego por parcela y vecino responsable';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: registro_riego                                   │
-- │  Confirmación efectiva del riego.                        │
-- │  Campo sincronizado soporta paradigma Offline-First:     │
-- │  0 = registrado sin señal (Background Sync pendiente)    │
-- │  1 = sincronizado con el servidor                        │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE registro_riego (
    id_registro      INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    id_turno         INT UNSIGNED   NOT NULL,
    id_usuario       INT UNSIGNED   NOT NULL
                     COMMENT 'Puede diferir del asignado si hubo sustitución',
    fecha_hora_riego DATETIME       NOT NULL,
    duracion_minutos SMALLINT UNSIGNED NULL,
    cantidad_litros  DECIMAL(6,2)   NULL,
    completado       TINYINT(1)     NOT NULL DEFAULT 1,
    sincronizado     TINYINT(1)     NOT NULL DEFAULT 1
                     COMMENT '0=Pendiente sync (offline)  1=Sincronizado con servidor',
    notas            TEXT           NULL,
    creado_en        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_registro),
    UNIQUE KEY  uq_registro_turno (id_turno)
                COMMENT 'Un turno = una sola confirmación (evita duplicados offline)',
    INDEX idx_registro_usuario (id_usuario),
    INDEX idx_registro_fecha   (fecha_hora_riego),
    INDEX idx_registro_sync    (sincronizado)
          COMMENT 'Registros pendientes de sincronización',
    CONSTRAINT fk_registro_turnos
        FOREIGN KEY (id_turno) REFERENCES turnos_riego (id_turno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_registro_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Confirmaciones efectivas de riego — soporte Offline-First (Background Sync)';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: cosechas                                         │
-- │  Soluciona: "alguien se llevó toda la lechuga sin avisar"│
-- │  Dashboard pregunta 2: "¿Cuánto se cosechó este mes?"   │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE cosechas (
    id_cosecha               INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_siembra               INT UNSIGNED NOT NULL,
    id_usuario               INT UNSIGNED NOT NULL COMMENT 'Vecino que realizó la cosecha',
    fecha_cosecha            DATE         NOT NULL,
    cantidad_cosechada       DECIMAL(8,2) NOT NULL,
    unidad                   VARCHAR(20)  NOT NULL DEFAULT 'kg',
    distribucion_descripcion TEXT         NULL COMMENT 'Cómo se repartió entre los vecinos',
    es_distribuida           TINYINT(1)   NOT NULL DEFAULT 0
                             COMMENT '1=Ya repartida  0=Pendiente distribución',
    notas                    TEXT         NULL,
    creado_en                TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_cosecha),
    INDEX idx_cosechas_siembra (id_siembra),
    INDEX idx_cosechas_usuario (id_usuario),
    INDEX idx_cosechas_fecha   (fecha_cosecha)
          COMMENT 'Reporte mensual de producción del dashboard',
    CONSTRAINT fk_cosechas_siembras
        FOREIGN KEY (id_siembra) REFERENCES siembras (id_siembra)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_cosechas_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro de cosechas y distribución comunitaria';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: notificaciones                                   │
-- │  Reemplaza el grupo de WhatsApp con 300 mensajes diarios │
-- │  Índice usuario+leida optimiza el badge de notificaciones│
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE notificaciones (
    id_notificacion INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_usuario      INT UNSIGNED NOT NULL COMMENT 'Destinatario',
    tipo            ENUM('riego','cosecha','conflicto','sistema','recordatorio','logro')
                    NOT NULL,
    titulo          VARCHAR(200) NOT NULL,
    mensaje         TEXT         NOT NULL,
    leida           TINYINT(1)   NOT NULL DEFAULT 0,
    entidad_tipo    VARCHAR(50)  NULL COMMENT 'parcela | turno_riego | siembra | usuario',
    entidad_id      INT UNSIGNED NULL COMMENT 'ID para navegación directa desde la notificación',
    fecha_creacion  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_lectura   TIMESTAMP    NULL,
    PRIMARY KEY (id_notificacion),
    INDEX idx_notif_usuario       (id_usuario),
    INDEX idx_notif_leida         (leida),
    INDEX idx_notif_tipo          (tipo),
    INDEX idx_notif_usuario_leida (id_usuario, leida)
          COMMENT 'Badge de no leídas: COUNT(*) WHERE id_usuario=? AND leida=0',
    CONSTRAINT fk_notif_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Centro de notificaciones — reemplaza el caos del grupo de WhatsApp';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: historial_actividades                            │
-- │  Log completo de auditoría del sistema.                  │
-- │  Dashboard pregunta 3: "¿Quién está activo?"             │
-- │  BIGINT para id: alto volumen esperado a largo plazo.    │
-- │  metadata JSON: contexto extensible sin alterar esquema. │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE historial_actividades (
    id_actividad   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_usuario     INT UNSIGNED    NOT NULL,
    tipo_actividad VARCHAR(50)     NOT NULL
                   COMMENT 'siembra | riego_completado | riego_omitido | cosecha | login | conflicto',
    descripcion    TEXT            NOT NULL,
    entidad_tipo   VARCHAR(50)     NULL,
    entidad_id     INT UNSIGNED    NULL,
    metadata       JSON            NULL
                   COMMENT 'Contexto adicional: litros, duración, parcela, motivo, etc.',
    fecha_hora     TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_actividad),
    INDEX idx_hist_usuario       (id_usuario),
    INDEX idx_hist_tipo          (tipo_actividad),
    INDEX idx_hist_fecha         (fecha_hora),
    INDEX idx_hist_usuario_fecha (id_usuario, fecha_hora)
          COMMENT 'Ranking de actividad por vecino para el dashboard',
    CONSTRAINT fk_hist_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Log de auditoría — trazabilidad completa de todas las acciones del sistema';

-- ┌──────────────────────────────────────────────────────────┐
-- │  TABLA: observaciones                                    │
-- │  Cubre los 3 conflictos reales del caso:                 │
-- │  → Robo de lechuga (vandalismo)                          │
-- │  → Doble siembra de tomates (conflicto)                  │
-- │  → Falta de coordinación general (incidencias)           │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE observaciones (
    id_observacion      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_parcela          INT UNSIGNED NULL COMMENT 'NULL = observación general del huerto',
    id_usuario          INT UNSIGNED NOT NULL COMMENT 'Vecino que reporta',
    id_usuario_resuelve INT UNSIGNED NULL COMMENT 'Quien resolvió la incidencia',
    tipo                ENUM('incidencia','vandalismo','plaga','mejora','consulta','conflicto')
                        NOT NULL,
    titulo              VARCHAR(200) NOT NULL,
    descripcion         TEXT         NOT NULL,
    estado              ENUM('abierta','en_proceso','resuelta','cerrada')
                        NOT NULL DEFAULT 'abierta',
    prioridad           ENUM('baja','media','alta','urgente')
                        NOT NULL DEFAULT 'media',
    imagen_url          VARCHAR(500) NULL,
    fecha_reporte       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion    TIMESTAMP    NULL,
    notas_resolucion    TEXT         NULL,
    PRIMARY KEY (id_observacion),
    INDEX idx_obs_parcela          (id_parcela),
    INDEX idx_obs_usuario          (id_usuario),
    INDEX idx_obs_estado           (estado),
    INDEX idx_obs_tipo             (tipo),
    INDEX idx_obs_prioridad_estado (prioridad, estado)
          COMMENT 'Vista rápida de incidencias urgentes abiertas en el dashboard',
    CONSTRAINT fk_obs_parcelas
        FOREIGN KEY (id_parcela) REFERENCES parcelas (id_parcela)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_obs_usuarios
        FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_obs_resuelve
        FOREIGN KEY (id_usuario_resuelve) REFERENCES usuarios (id_usuario)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Incidencias, plagas, vandalismos y propuestas de mejora del huerto';


-- ============================================================
-- SECCIÓN 4: VISTAS PARA EL DASHBOARD
-- Responden directamente las 3 preguntas clave del caso.
-- ============================================================

-- Vista 1: ¿Qué parcelas necesitan riego hoy y quién es responsable?
CREATE OR REPLACE VIEW v_turnos_hoy AS
SELECT
    t.id_turno,
    p.codigo                          AS codigo_parcela,
    p.nombre                          AS nombre_parcela,
    CONCAT(u.nombre,' ',u.apellido)   AS responsable,
    u.telefono                        AS telefono_responsable,
    t.hora_inicio,
    t.hora_fin,
    t.estado,
    t.notas,
    c.nombre_comun                    AS cultivo_sembrado,
    s.fecha_estimada_cosecha
FROM turnos_riego t
    JOIN  parcelas p ON t.id_parcela          = p.id_parcela
    JOIN  usuarios u ON t.id_usuario_asignado = u.id_usuario
    LEFT JOIN siembras s ON s.id_parcela = p.id_parcela AND s.estado = 'activa'
    LEFT JOIN cultivos c ON s.id_cultivo = c.id_cultivo
WHERE t.fecha_turno = CURDATE()
ORDER BY t.hora_inicio, t.estado;

-- Vista 2: ¿Qué vecinos están activos y cuáles no cumplen?
CREATE OR REPLACE VIEW v_ranking_vecinos AS
SELECT
    u.id_usuario,
    CONCAT(u.nombre,' ',u.apellido)                                             AS vecino,
    u.puntos_reputacion,
    u.logro_titulo,
    COUNT(DISTINCT CASE WHEN t.estado='completado' THEN t.id_turno END)         AS riegos_completados,
    COUNT(DISTINCT CASE WHEN t.estado='omitido'    THEN t.id_turno END)         AS riegos_omitidos,
    COUNT(DISTINCT co.id_cosecha)                                                AS cosechas_realizadas,
    ROUND(
        COUNT(DISTINCT CASE WHEN t.estado='completado' THEN t.id_turno END)*100.0
        / NULLIF(COUNT(DISTINCT CASE WHEN t.estado IN ('completado','omitido')
                                     THEN t.id_turno END),0), 1)                AS pct_cumplimiento,
    u.ultimo_acceso
FROM usuarios u
    LEFT JOIN turnos_riego t ON u.id_usuario = t.id_usuario_asignado
    LEFT JOIN cosechas     co ON u.id_usuario = co.id_usuario
WHERE u.activo=1 AND u.id_rol IN (1,2)
GROUP BY u.id_usuario
ORDER BY u.puntos_reputacion DESC;

-- Vista 3: ¿Cuánto se cosechó este mes y cómo se repartió?
CREATE OR REPLACE VIEW v_cosechas_mes AS
SELECT
    YEAR(co.fecha_cosecha)                                                           AS anio,
    MONTH(co.fecha_cosecha)                                                          AS mes,
    c.nombre_comun                                                                   AS cultivo,
    SUM(co.cantidad_cosechada)                                                       AS total_cosechado,
    co.unidad,
    COUNT(co.id_cosecha)                                                             AS num_cosechas,
    SUM(CASE WHEN co.es_distribuida=1 THEN co.cantidad_cosechada ELSE 0 END)         AS cantidad_distribuida,
    GROUP_CONCAT(DISTINCT CONCAT(u.nombre,' ',u.apellido) SEPARATOR ', ')           AS cosechadores
FROM cosechas co
    JOIN siembras s ON co.id_siembra = s.id_siembra
    JOIN cultivos c ON s.id_cultivo  = c.id_cultivo
    JOIN usuarios u ON co.id_usuario = u.id_usuario
GROUP BY YEAR(co.fecha_cosecha), MONTH(co.fecha_cosecha), c.nombre_comun, co.unidad
ORDER BY anio DESC, mes DESC, total_cosechado DESC;

-- ============================================================
-- ════════════════════════════════════════════════════════════
-- SECCIÓN 5: DML — DATOS DE PRUEBA
-- Orden respeta dependencias de claves foráneas.
-- ════════════════════════════════════════════════════════════
-- ============================================================

-- ┌──────────────────────────────────────────────────────────┐
-- │  5.1  ROLES (3 registros)                                │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO roles (id_rol, nombre, descripcion, nivel_acceso) VALUES
(1,'Coordinadora',
 'Privilegios de gestión global, diseño cartográfico de parcelas y resolución de políticas de caducidad',1),
(2,'Vecino Colaborador',
 'Gestión de bancales propios, registro de tareas y participación en foros técnicos del huerto',2),
(3,'Voluntario Ocasional',
 'Interfaz simplificada para reportes rápidos de incidencias o riegos espontáneos',3);

-- ┌──────────────────────────────────────────────────────────┐
-- │  5.2  CULTIVOS (10 registros)                            │
-- │  Especies comunes en clima mediterráneo árido (La Serena)│
-- └──────────────────────────────────────────────────────────┘
INSERT INTO cultivos
  (id_cultivo,nombre_comun,nombre_cientifico,descripcion,
   frecuencia_riego_dias,dias_hasta_cosecha,unidad_medida,color_mapa)
VALUES
(1,'Tomate Cherry','Solanum lycopersicum var. cerasiforme',
  'Tomate pequeño de sabor intenso. Muy productivo en primavera-verano. Requiere soporte y poda.',
  2,75,'kg','#FF5252'),
(2,'Lechuga Romana','Lactuca sativa var. longifolia',
  'Hojas largas y crujientes. Cosecha escalonada. Ideal para principiantes.',
  2,45,'unidad','#66BB6A'),
(3,'Zanahoria','Daucus carota subsp. sativus',
  'Raíz que requiere suelo profundo. Lista cuando el cuello supera 1 cm de diámetro.',
  3,80,'kg','#FF9800'),
(4,'Cilantro','Coriandrum sativum',
  'Hierba aromática de rápido crecimiento. Cosechas escalonadas cada 3-4 semanas.',
  2,30,'manojo','#26C6DA'),
(5,'Albahaca','Ocimum basilicum',
  'Aromática mediterránea. Sensible al frío. Podar flores para prolongar producción.',
  2,35,'manojo','#AB47BC'),
(6,'Pepino','Cucumis sativus',
  'Alto rendimiento en climas cálidos. Requiere soporte vertical o espacio amplio.',
  2,60,'kg','#42A5F5'),
(7,'Pimiento Rojo','Capsicum annuum',
  'Verde a los 60 días, rojo a los 90. Maduración lenta pero alto valor nutricional.',
  3,90,'kg','#EF5350'),
(8,'Espinaca','Spinacia oleracea',
  'Hoja verde rica en hierro. Tolera bajas temperaturas. Ideal para invierno-primavera.',
  2,40,'kg','#2E7D32'),
(9,'Cebolla de Verdeo','Allium fistulosum',
  'Cosecha continua cortando hojas sin arrancar. Perenne y muy productiva.',
  3,50,'manojo','#F9A825'),
(10,'Rábano','Raphanus sativus',
  'Listo en 25-30 días. El cultivo más rápido del huerto. Ideal para principiantes.',
  2,25,'unidad','#EC407A');


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.3  USUARIOS (19 registros)                            │
-- │  Doña Carmen (Coordinadora) + 18 vecinos colaboradores   │
-- │  Los puntos_reputacion crean distintos niveles de        │
-- │  actividad para probar todas las vistas del dashboard.   │
-- │                                                          │
-- │  Hash compartido para pruebas: bcrypt("Huerto2026!",10)  │
-- │  GENERAR HASHES INDIVIDUALES en producción.              │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO usuarios
  (id_usuario,nombre,apellido,email,password_hash,telefono,
   id_rol,activo,puntos_reputacion,logro_titulo,fecha_registro,ultimo_acceso)
VALUES
-- Coordinadora
(1,'Carmen','Rojas Vega','carmen.rojas@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345001',1,1,1250,'Coordinadora Fundadora',
 '2026-01-15 10:00:00','2026-06-18 08:30:00'),
-- Vecinos muy activos (logros desbloqueados)
(2,'Juan','Pérez Molina','juan.perez@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345002',2,1,420,'Héroe de la Sequía',
 '2026-01-20 11:00:00','2026-06-18 07:15:00'),
(7,'Rosa','Hernández Vera','rosa.hernandez@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345007',2,1,500,'Historiadora',
 '2026-01-25 09:00:00','2026-06-18 09:00:00'),
(10,'Miguel','Torres Espinoza','miguel.torres@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345010',2,1,460,'Mentor',
 '2026-02-05 08:30:00','2026-06-18 06:45:00'),
-- Vecinos regularmente activos
(3,'María','González Ríos','maria.gonzalez@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345003',2,1,380,NULL,
 '2026-01-20 11:30:00','2026-06-17 19:00:00'),
(4,'Carlos','Muñoz Araya','carlos.munoz@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345004',2,1,310,NULL,
 '2026-01-22 09:00:00','2026-06-15 14:30:00'),
(5,'Ana','Flores Castillo','ana.flores@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345005',2,1,290,NULL,
 '2026-01-22 10:00:00','2026-06-16 16:45:00'),
(6,'Pedro','Martínez Lagos','pedro.martinez@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345006',2,1,260,NULL,
 '2026-01-25 08:00:00','2026-06-12 11:00:00'),
(9,'Elena','Castro Pizarro','elena.castro@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345009',2,1,350,NULL,
 '2026-02-01 11:00:00','2026-06-17 20:00:00'),
(11,'Sofía','Vega Moreno','sofia.vega@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345011',2,1,230,NULL,
 '2026-02-05 09:30:00','2026-06-14 17:30:00'),
(15,'Isabel','Vargas Leiva','isabel.vargas@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345015',2,1,270,NULL,
 '2026-02-15 10:00:00','2026-06-16 15:00:00'),
(17,'Valentina','Soto Becerra','valentina.soto@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345017',2,1,310,NULL,
 '2026-03-01 09:00:00','2026-06-17 21:00:00'),
(14,'Roberto','Morales Ibáñez','roberto.morales@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345014',2,1,200,NULL,
 '2026-02-15 09:00:00','2026-06-11 10:00:00'),
(18,'Andrés','Navarro Gutiérrez','andres.navarro@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345018',2,1,150,NULL,
 '2026-03-10 10:00:00','2026-06-13 09:30:00'),
-- Actividad media-baja (generan alertas en el dashboard)
(12,'Jorge','Reyes Contreras','jorge.reyes@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345012',2,1,120,NULL,
 '2026-02-10 10:00:00','2026-06-05 09:00:00'),
(8,'Luis','Ramírez Silva','luis.ramirez@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345008',2,1,180,NULL,
 '2026-02-01 10:00:00','2026-06-10 08:00:00'),
-- Baja actividad / posible abandono
(13,'Patricia','Díaz Peña','patricia.diaz@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345013',2,1,80,NULL,
 '2026-02-10 11:00:00','2026-05-28 14:00:00'),
-- Muy poca actividad
(16,'Diego','Fuentes Alarcón','diego.fuentes@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345016',2,1,40,NULL,
 '2026-03-01 08:00:00','2026-04-15 12:00:00'),
-- Recién registrada — nunca ha iniciado sesión (ultimo_acceso NULL)
(19,'Claudia','Riquelme Ojeda','claudia.riquelme@huertolink.cl',
 '$2b$10$K8Z2mP9nQ1xLvR7dE3wYheBN5cVjFtGsHuIo6kWm4pAl0y1rDxCq',
 '+56912345019',2,1,0,NULL,
 '2026-03-15 11:00:00',NULL);


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.4  PARCELAS (16 registros — cuadrícula 4×5)           │
-- │  P-01 a P-13: bancales asignados a vecinos               │
-- │  P-14       : en mantenimiento (infraestructura dañada)  │
-- │  P-15       : parcela comunitaria (es_publica=1)         │
-- │  P-16       : parcela regalo / Theft Plot anti-robo      │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO parcelas
  (id_parcela,codigo,nombre,ubicacion_fila,ubicacion_columna,
   area_m2,estado,id_usuario_asignado,fecha_asignacion,es_publica,descripcion)
VALUES
-- Fila 1
(1,'P-01','Bancal Los Tomates',      1,1,2.00,'ocupada',     2, '2026-01-20',0,
  'Bancal de Juan Pérez. Tomates cherry en plena producción — segundo cultivo del año.'),
(2,'P-02','Bancal Las Lechugas',     1,2,1.50,'ocupada',     3, '2026-01-20',0,
  'Bancal de María González. Lechugas romanas casi listas para primera cosecha.'),
(3,'P-03','Bancal Zanahorias',       1,3,2.00,'ocupada',     4, '2026-01-22',0,
  'Bancal de Carlos Muñoz. Zanahorias en desarrollo. Primera vez cultivando raíces.'),
(4,'P-04','Bancal Aromáticas',       1,4,1.00,'ocupada',     5, '2026-01-22',0,
  'Bancal de Ana Flores. Cilantro y albahaca compartiendo espacio. Muy aromático.'),
(5,'P-05','Bancal Los Pepinos',      1,5,2.50,'ocupada',     6, '2026-01-25',0,
  'Bancal de Pedro Martínez. Pepinos y pimientos. Actualmente con alerta de pulgones.'),
-- Fila 2
(6,'P-06','Bancal Rosa',             2,1,1.50,'ocupada',     7, '2026-01-25',0,
  'Bancal de Rosa Hernández (Historiadora). Espinacas y vegetales de hoja. Muy bien documentado.'),
(7,'P-07','Bancal Luis',             2,2,2.00,'ocupada',     8, '2026-02-01',0,
  'Bancal de Luis Ramírez. Cebolla de verdeo. Bajo cumplimiento de turnos este mes.'),
(8,'P-08','Bancal Elena',            2,3,1.50,'ocupada',     9, '2026-02-01',0,
  'Bancal de Elena Castro. Rábanos listos para cosechar y lechugas en crecimiento.'),
(9,'P-09','Bancal Miguel',           2,4,2.00,'ocupada',     10,'2026-02-05',0,
  'Bancal del Mentor Miguel Torres. Tomates cherry y pimientos rojos. Modelo de buenas prácticas.'),
(10,'P-10','Bancal Sofía',           2,5,1.50,'ocupada',     11,'2026-02-05',0,
  'Bancal de Sofía Vega. Zanahorias y cilantro en buen estado.'),
-- Fila 3
(11,'P-11','Bancal Jorge',           3,1,2.00,'ocupada',     12,'2026-02-10',0,
  'Bancal de Jorge Reyes. Tomates con producción irregular. Requiere seguimiento.'),
(12,'P-12','Bancal Patricia',        3,2,1.50,'ocupada',     13,'2026-02-10',0,
  'Bancal de Patricia Díaz. Sin actividad en los últimos 20 días. Riesgo de abandono.'),
(13,'P-13','Bancal Compartido Sur',  3,3,3.00,'ocupada',     14,'2026-02-15',0,
  'Bancal de Roberto Morales, compartido con Isabel, Valentina y Andrés. Lechugas activas.'),
(14,'P-14','Bancal Mantenimiento',   3,4,2.00,'mantenimiento',NULL,NULL,0,
  'Malla de soporte dañada. En reparación. Estimado de habilitación: 3-4 semanas. Ver obs. #10.'),
-- Fila 4
(15,'P-15','Parcela Comunitaria',    4,1,4.00,'ocupada',     NULL,'2026-01-15',1,
  'Bancal comunitario gestionado por Doña Carmen. Acceso para todos los miembros del huerto.'),
(16,'P-16','Parcela Regalo',         4,2,2.00,'regalo',      NULL,'2026-03-01',1,
  'THEFT PLOT: Parcela de acceso libre para reducir robos en bancales privados. Señalizada digitalmente. Lechugas y rábanos disponibles para todos.');

-- ┌──────────────────────────────────────────────────────────┐
-- │  5.5  SIEMBRAS (25 registros)                            │
-- │  Activas, cosechadas y una PERDIDA (conflicto del caso): │
-- │  Pedro sembró tomates en el bancal de Patricia sin       │
-- │  coordinación → siembra id=25, estado='perdida'          │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO siembras
  (id_siembra,id_parcela,id_cultivo,id_usuario,
   fecha_siembra,fecha_estimada_cosecha,estado,
   cantidad_sembrada,unidad_cantidad,notas)
VALUES
-- Siembras ACTIVAS
(1,1,1,2,   '2026-04-01','2026-06-15','activa',  12,'plantas',
  'Segunda temporada de tomates de Juan. Excelente crecimiento, superó fecha estimada.'),
(2,2,2,3,   '2026-05-01','2026-06-15','activa',   8,'plantas',
  'Lechugas de María casi listas — cosecha programada esta semana.'),
(3,3,3,4,   '2026-04-15','2026-07-05','activa',  50,'semillas',
  'Primeras zanahorias de Carlos. Listas en aprox. 2-3 semanas.'),
(4,4,4,5,   '2026-05-10','2026-06-10','activa',   1,'m2',
  'Cilantro de Ana. Ya pasó fecha estimada, cosechar por hojas regularmente.'),
(5,4,5,5,   '2026-05-10','2026-06-14','activa',   4,'plantas',
  'Albahaca junto al cilantro en P-04. Buena compañía de cultivos.'),
(6,5,6,6,   '2026-04-20','2026-06-20','activa',   6,'plantas',
  'Pepinos de Pedro casi listos. Alerta de pulgones activa (ver obs. #3).'),
(7,5,7,6,   '2026-04-20','2026-07-20','activa',   4,'plantas',
  'Pimientos compartiendo espacio con pepinos. En desarrollo temprano.'),
(8,6,8,7,   '2026-05-05','2026-06-14','activa',   1,'m2',
  'Espinacas de Rosa. Cosecha parcial el 14/06. Planta continúa produciendo.'),
(9,7,9,8,   '2026-04-25','2026-06-14','activa',  10,'plantas',
  'Cebolla de verdeo de Luis. Lista para corte. Cosecha sin registro detectada (obs. #7).'),
(10,8,2,9,  '2026-05-15','2026-06-29','activa',   6,'plantas',
  'Lechugas de Elena en crecimiento.'),
(11,8,10,9, '2026-05-15','2026-06-09','activa',  15,'semillas',
  'Rábanos de Elena. Superaron fecha estimada. Cosechados parcialmente el 16/06.'),
(12,9,1,10, '2026-04-10','2026-06-24','activa',  10,'plantas',
  'Tomates del Mentor Miguel. Variedades selectas. Próximos a madurar.'),
(13,9,7,10, '2026-04-10','2026-07-09','activa',   6,'plantas',
  'Pimientos rojos de Miguel. Crecimiento en etapa media.'),
(14,10,3,11,'2026-04-18','2026-07-07','activa',  40,'semillas',
  'Zanahorias de Sofía en buen estado.'),
(15,11,1,12,'2026-04-05','2026-06-19','activa',   8,'plantas',
  'Tomates de Jorge. Fecha de cosecha mañana. Requiere más atención.'),
(16,13,2,14,'2026-05-01','2026-06-15','activa',  10,'plantas',
  'Lechugas del bancal compartido P-13 a cargo de Roberto.'),
(17,15,4,1, '2026-05-01','2026-05-31','activa',   2,'m2',
  'Cilantro comunitario de Doña Carmen. Cosecha escalonada en curso.'),
(18,15,2,1, '2026-05-01','2026-06-15','activa',  12,'plantas',
  'Lechugas comunitarias para todos los miembros del huerto.'),
(19,16,2,1, '2026-05-15','2026-06-29','activa',  20,'plantas',
  'Lechugas de la Parcela Regalo (Theft Plot). Acceso libre para el barrio.'),
(20,16,10,1,'2026-05-15','2026-06-09','activa',  30,'semillas',
  'Rábanos de la Parcela Regalo. Para que transeúntes puedan cosechar libremente.'),
-- Siembras COSECHADAS (historial mar-abr 2026)
(21,1,2,2,  '2026-02-10','2026-03-27','cosechada', 6,'plantas',
  'Primera siembra del año de Juan: lechugas. Cosechada con éxito en marzo.'),
(22,2,10,3, '2026-02-10','2026-03-07','cosechada',20,'semillas',
  'Rábanos de María en P-02. Primera cosecha del año.'),
(23,6,4,7,  '2026-02-20','2026-03-22','cosechada', 1,'m2',
  'Primera cosecha de cilantro de Rosa. Documentada fotográficamente.'),
(24,15,8,1, '2026-02-01','2026-03-13','cosechada', 2,'m2',
  'Espinacas comunitarias de invierno. Distribuidas entre los 18 vecinos.'),
-- Siembra PERDIDA — Conflicto real del caso Huerto Herido
(25,12,1,6, '2026-03-15','2026-05-29','perdida',   4,'plantas',
  'CONFLICTO DOCUMENTADO: Pedro Martínez sembró tomates en el bancal P-12 de Patricia Díaz el mismo día y en el mismo espacio, sin coordinación previa. Las siembras de ambos se dañaron mutuamente. Caso mediado por Doña Carmen. Este conflicto motivó la creación del módulo de mapa 2D para prevenir duplicaciones.');


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.6  TURNOS DE RIEGO (63 registros)                     │
-- │  • HOY (2026-06-18): 6 turnos — vista principal          │
-- │  • Próximos 2 días: turnos pendientes                    │
-- │  • Historial abr-jun: completados, omitidos              │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO turnos_riego
  (id_turno,id_parcela,id_usuario_asignado,fecha_turno,
   hora_inicio,hora_fin,estado,notas)
VALUES
-- HOY 2026-06-18 — aparecen en la vista v_turnos_hoy
(1, 1, 2, '2026-06-18','07:00:00','07:30:00','pendiente',
  'Turno de Juan: tomates cherry en P-01 necesitan riego urgente.'),
(2, 2, 3, '2026-06-18','07:30:00','08:00:00','pendiente',
  'Lechugas de María — riego ligero antes de la cosecha.'),
(3, 9,10, '2026-06-18','08:00:00','08:30:00','pendiente',
  'Miguel riega tomates y pimientos en P-09.'),
(4,15, 1, '2026-06-18','09:00:00','09:30:00','pendiente',
  'Doña Carmen riega y revisa la parcela comunitaria P-15.'),
(5, 6, 7, '2026-06-18','07:30:00','08:00:00','completado',
  'Rosa completó su turno temprano — confirmado a las 07:35.'),
(6, 7, 8, '2026-06-18','08:30:00','09:00:00','omitido',
  'Luis Ramírez no se presentó. Tercera omisión en junio. Notificación enviada a Coordinadora.'),
-- Mañana 2026-06-19
(7, 3, 4, '2026-06-19','07:00:00','07:30:00','pendiente','Zanahorias de Carlos.'),
(8, 4, 5, '2026-06-19','07:30:00','08:00:00','pendiente','Aromáticas de Ana — cilantro y albahaca.'),
(9, 5, 6, '2026-06-19','08:00:00','08:30:00','pendiente','Pepinos y pimientos de Pedro. Revisar pulgones.'),
(10,8, 9, '2026-06-19','08:30:00','09:00:00','pendiente','Elena riega rábanos y lechugas en P-08.'),
(11,10,11,'2026-06-19','09:00:00','09:30:00','pendiente','Sofía riega su bancal P-10.'),
(12,16,17,'2026-06-19','09:30:00','10:00:00','pendiente','Valentina riega la Parcela Regalo P-16.'),
-- 2026-06-20
(13,11,12,'2026-06-20','07:00:00','07:30:00','pendiente','Jorge riega sus tomates en P-11.'),
(14,12,13,'2026-06-20','07:30:00','08:00:00','pendiente','Patricia riega bancal P-12.'),
(15,13,14,'2026-06-20','08:00:00','08:30:00','pendiente','Roberto riega bancal compartido P-13.'),
(16, 1, 2,'2026-06-20','08:30:00','09:00:00','pendiente','Segundo riego semanal de Juan para los tomates.'),
-- Lunes-Martes 2026-06-16/17
(17, 1, 2,'2026-06-16','07:00:00','07:30:00','completado',NULL),
(18, 2, 3,'2026-06-16','07:30:00','08:00:00','completado',NULL),
(19, 9,10,'2026-06-16','08:00:00','08:30:00','completado',NULL),
(20, 3, 4,'2026-06-16','08:30:00','09:00:00','completado',NULL),
(21, 6, 7,'2026-06-17','07:00:00','07:30:00','completado',NULL),
(22, 7, 8,'2026-06-17','07:30:00','08:00:00','omitido',   'Luis omitió nuevamente el martes.'),
(23,15, 1,'2026-06-17','09:00:00','09:30:00','completado','Carmen regó P-15 e inspeccionó el huerto.'),
-- Primera quincena junio
(24, 1, 2,'2026-06-02','07:00:00','07:30:00','completado',NULL),
(25, 2, 3,'2026-06-02','07:30:00','08:00:00','completado',NULL),
(26, 9,10,'2026-06-04','08:00:00','08:30:00','completado',NULL),
(27, 5, 6,'2026-06-04','08:30:00','09:00:00','completado',NULL),
(28, 7, 8,'2026-06-04','07:30:00','08:00:00','omitido',   'Luis — primera omisión de junio.'),
(29, 6, 7,'2026-06-06','07:30:00','08:00:00','completado',NULL),
(30,11,12,'2026-06-06','07:00:00','07:30:00','omitido',   'Jorge no regó sus tomates. Notificación enviada.'),
(31, 4, 5,'2026-06-08','07:30:00','08:00:00','completado',NULL),
(32,10,11,'2026-06-08','09:00:00','09:30:00','completado',NULL),
(33,13,14,'2026-06-10','08:00:00','08:30:00','completado',NULL),
(34, 3, 4,'2026-06-10','07:00:00','07:30:00','completado',NULL),
(35,15,17,'2026-06-10','09:00:00','09:30:00','completado','Valentina sustituyó en la parcela comunitaria.'),
(36, 8, 9,'2026-06-12','08:30:00','09:00:00','completado',NULL),
(37,12,13,'2026-06-12','07:30:00','08:00:00','completado',NULL),
(38, 1, 2,'2026-06-14','07:00:00','07:30:00','completado',NULL),
(39, 9,10,'2026-06-14','08:00:00','08:30:00','completado',NULL),
(40, 6, 7,'2026-06-14','07:30:00','08:00:00','completado',NULL),
-- Mayo 2026
(41, 1, 2,'2026-05-05','07:00:00','07:30:00','completado',NULL),
(42, 2, 3,'2026-05-05','07:30:00','08:00:00','completado',NULL),
(43, 9,10,'2026-05-07','08:00:00','08:30:00','completado',NULL),
(44, 6, 7,'2026-05-07','07:30:00','08:00:00','completado',NULL),
(45, 7, 8,'2026-05-09','07:30:00','08:00:00','omitido',   'Luis incumplió en mayo también. Patrón repetitivo.'),
(46, 5, 6,'2026-05-09','08:00:00','08:30:00','completado',NULL),
(47,15, 1,'2026-05-12','09:00:00','09:30:00','completado',NULL),
(48, 3, 4,'2026-05-14','07:00:00','07:30:00','completado',NULL),
(49, 4, 5,'2026-05-14','07:30:00','08:00:00','completado',NULL),
(50,11,12,'2026-05-16','07:00:00','07:30:00','completado',NULL),
(51,13,15,'2026-05-20','08:00:00','08:30:00','completado','Isabel sustituyó a Roberto en P-13.'),
(52, 8, 9,'2026-05-22','08:30:00','09:00:00','completado',NULL),
(53,10,11,'2026-05-24','09:00:00','09:30:00','completado',NULL),
(54, 2, 3,'2026-05-26','07:30:00','08:00:00','completado',NULL),
-- Abril 2026
(55, 1, 2,'2026-04-03','07:00:00','07:30:00','completado',NULL),
(56, 9,10,'2026-04-05','08:00:00','08:30:00','completado',NULL),
(57, 6, 7,'2026-04-07','07:30:00','08:00:00','completado',NULL),
(58, 5, 6,'2026-04-09','08:00:00','08:30:00','completado',NULL),
(59,15, 1,'2026-04-15','09:00:00','09:30:00','completado',NULL),
(60, 3, 4,'2026-04-17','07:00:00','07:30:00','completado',NULL),
(61, 7, 8,'2026-04-19','07:30:00','08:00:00','omitido',   'Luis — omisión en abril. Incumplimiento sostenido.'),
(62, 2, 3,'2026-04-25','07:30:00','08:00:00','completado',NULL),
(63, 4, 5,'2026-04-27','07:30:00','08:00:00','completado',NULL);

-- ┌──────────────────────────────────────────────────────────┐
-- │  5.7  REGISTRO DE RIEGO (30 registros)                   │
-- │  Confirmaciones para los turnos completados.             │
-- │  id=25: sincronizado=0 para probar modo Offline-First.   │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO registro_riego
  (id_registro,id_turno,id_usuario,fecha_hora_riego,
   duracion_minutos,cantidad_litros,completado,sincronizado,notas)
VALUES
(1, 5, 7,'2026-06-18 07:35:00',20,15.0,1,1,'Riego matutino completado sin inconvenientes.'),
(2,17, 2,'2026-06-16 07:10:00',25,20.0,1,1,NULL),
(3,18, 3,'2026-06-16 07:45:00',18,12.0,1,1,NULL),
(4,19,10,'2026-06-16 08:15:00',25,18.0,1,1,NULL),
(5,20, 4,'2026-06-16 08:45:00',20,15.0,1,1,NULL),
(6,21, 7,'2026-06-17 07:20:00',18,14.0,1,1,NULL),
(7,23, 1,'2026-06-17 09:10:00',30,25.0,1,1,'Riego comunitario + inspección general del huerto.'),
(8,24, 2,'2026-06-02 07:05:00',25,20.0,1,1,NULL),
(9,25, 3,'2026-06-02 07:35:00',18,13.0,1,1,NULL),
(10,26,10,'2026-06-04 08:05:00',25,18.0,1,1,NULL),
(11,27, 6,'2026-06-04 08:35:00',22,17.0,1,1,NULL),
(12,29, 7,'2026-06-06 07:35:00',18,14.0,1,1,NULL),
(13,31, 5,'2026-06-08 07:35:00',15,10.0,1,1,NULL),
(14,32,11,'2026-06-08 09:05:00',20,15.0,1,1,NULL),
(15,33,14,'2026-06-10 08:05:00',28,22.0,1,1,NULL),
(16,34, 4,'2026-06-10 07:05:00',22,16.0,1,1,NULL),
(17,35,17,'2026-06-10 09:10:00',25,20.0,1,1,'Valentina sustituyó a Carmen en P-15.'),
(18,36, 9,'2026-06-12 08:35:00',20,15.0,1,1,NULL),
(19,37,13,'2026-06-12 07:35:00',18,13.0,1,1,NULL),
(20,38, 2,'2026-06-14 07:05:00',25,20.0,1,1,NULL),
(21,39,10,'2026-06-14 08:05:00',25,18.0,1,1,NULL),
(22,40, 7,'2026-06-14 07:35:00',18,14.0,1,1,NULL),
(23,41, 2,'2026-05-05 07:08:00',25,20.0,1,1,NULL),
(24,42, 3,'2026-05-05 07:38:00',18,13.0,1,1,NULL),
-- Registro OFFLINE — sincronizado=0 (prueba de Background Sync API)
(25,43,10,'2026-05-07 08:08:00',25,18.0,1,0,
  'Registrado sin conexión en campo. Sincronización pendiente con el servidor.'),
(26,44, 7,'2026-05-07 07:38:00',18,14.0,1,1,NULL),
(27,46, 6,'2026-05-09 08:08:00',22,17.0,1,1,NULL),
(28,47, 1,'2026-05-12 09:08:00',30,25.0,1,1,NULL),
(29,48, 4,'2026-05-14 07:08:00',22,16.0,1,1,NULL),
(30,49, 5,'2026-05-14 07:38:00',15,10.0,1,1,NULL);


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.8  COSECHAS (10 registros — mar a jun 2026)           │
-- │  id=10: es_distribuida=0 para probar módulo pendiente.   │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO cosechas
  (id_cosecha,id_siembra,id_usuario,fecha_cosecha,
   cantidad_cosechada,unidad,distribucion_descripcion,es_distribuida,notas)
VALUES
-- Junio 2026
(1, 2, 3,'2026-06-05', 6,'unidad',
  'Una lechuga para cada uno: Juan, María, Elena, Sofía, Valentina y Doña Carmen.',
  1,'Lechugas de María listas antes de lo estimado. Excelente estado.'),
(2, 4, 5,'2026-06-08', 4,'manojo',
  'Un manojo por hogar: Ana, Pedro, Rosa y Luis.',
  1,'Primer corte de cilantro de Ana. Aromatizó toda la manzana según vecinos.'),
(3, 9, 8,'2026-06-10', 8,'manojo',
  'Cebollas de verdeo distribuidas entre los 8 vecinos más activos del mes.',
  1,'Cosecha de Luis sin registro previo. Detectada por Elena Castro (obs. #7).'),
(4,17, 1,'2026-06-12', 3,'manojo',
  'Cilantro comunitario en partes iguales para las 3 familias que asistieron a la jornada.',
  1,'Doña Carmen organizó jornada presencial. Documentada por Rosa (Historiadora).'),
(5, 8, 7,'2026-06-14',1.5,'kg',
  '0.5 kg para Rosa, 0.5 kg para Elena, 0.5 kg para la olla comunitaria del sábado.',
  1,'Excelente cosecha de espinacas de Rosa.'),
-- Mayo 2026
(6,21, 2,'2026-05-10', 5,'unidad',
  'Una lechuga para cada vecino del sector norte del huerto.',
  1,'Primera cosecha del año de Juan. Temporada exitosa.'),
(7,23, 7,'2026-05-12', 5,'manojo',
  '5 manojos de cilantro distribuidos en la jornada del sábado.',
  1,'Rosa documentó fotografías de esta cosecha para el historial del huerto.'),
-- Abril 2026
(8,22, 3,'2026-04-15',0.8,'kg',
  'Rábanos de María usados en ensalada comunitaria.',
  1,'Rábanos listos antes de lo esperado. Primera cosecha de P-02.'),
-- Marzo 2026
(9,24, 1,'2026-03-20', 2,'kg',
  'Espinacas comunitarias distribuidas equitativamente. Cada familia recibió aprox. 111 g.',
  1,'Gran cosecha comunitaria de invierno. Asistencia récord de 18 vecinos en la jornada.'),
-- PENDIENTE DE DISTRIBUCIÓN — para probar módulo de gestión
(10,11, 9,'2026-06-16',0.6,'kg',
  NULL,
  0,'Rábanos de Elena cosechados y pesados. Pendiente distribución entre los vecinos del sector.');

-- ┌──────────────────────────────────────────────────────────┐
-- │  5.9  NOTIFICACIONES (25 registros)                      │
-- │  Todos los tipos: riego, cosecha, conflicto, sistema,    │
-- │  recordatorio, logro. Leídas y no leídas.               │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO notificaciones
  (id_notificacion,id_usuario,tipo,titulo,mensaje,
   leida,entidad_tipo,entidad_id,fecha_creacion,fecha_lectura)
VALUES
-- NO LEÍDAS — urgentes del dashboard de hoy
(1, 2,'riego','Tu turno de riego es HOY — P-01',
  'Tienes asignado el riego del Bancal Los Tomates (P-01) hoy a las 07:00. Los tomates cherry necesitan agua urgentemente. Confirma en la app cuando termines.',
  0,'turno_riego',1,'2026-06-18 06:00:00',NULL),
(2, 3,'riego','Turno de riego pendiente — P-02',
  'Hoy a las 07:30 debes regar las lechugas romanas en P-02. Ya están maduras para cosechar. Confirma el riego en HuertoLink.',
  0,'turno_riego',2,'2026-06-18 06:00:00',NULL),
(3,10,'riego','Riego pendiente — P-09 Bancal Miguel',
  'Tu turno de riego para P-09 comienza a las 08:00. Tomates cherry y pimientos te esperan.',
  0,'turno_riego',3,'2026-06-18 06:00:00',NULL),
(4, 1,'sistema','⚠️ Luis Ramírez — 3 omisiones en junio',
  'Luis Ramírez (Bancal P-07) ha omitido 3 turnos de riego este mes. La cebolla de verdeo está en riesgo. Se recomienda contactarlo o reasignar el bancal temporalmente.',
  0,'usuario',8,'2026-06-18 07:00:00',NULL),
(5, 1,'conflicto','🚨 Riesgo de abandono — P-12 Patricia Díaz',
  'Patricia Díaz no ha registrado actividad en los últimos 20 días. Su bancal P-12 podría estar en riesgo según los estándares del huerto.',
  0,'parcela',12,'2026-06-17 18:00:00',NULL),
(6, 9,'cosecha','🥬 Tus rábanos superaron fecha de cosecha',
  'Los rábanos de P-08 superaron su fecha estimada (09 jun). Tienes una cosecha de 0.6 kg del 16/06 pendiente de distribución entre los vecinos.',
  0,'siembra',11,'2026-06-16 09:00:00',NULL),
-- Recordatorios jornada presencial sábado
(7, 2,'recordatorio','Jornada Presencial — Sáb 21 jun, 10:00',
  'Este sábado 21 hay jornada de trabajo en el huerto. Tu asistencia suma 50 puntos de reputación. Habrá cosecha comunitaria y limpieza general.',
  0,NULL,NULL,'2026-06-18 08:00:00',NULL),
(8, 3,'recordatorio','Jornada Presencial — Sáb 21 jun, 10:00',
  'Este sábado 21 hay jornada de trabajo en el huerto. Asistencia: +50 puntos. Trae guantes y herramientas si tienes.',
  0,NULL,NULL,'2026-06-18 08:00:00',NULL),
(9, 4,'recordatorio','Jornada Presencial — Sáb 21 jun, 10:00',
  'Recuerda: este sábado hay jornada en el huerto. Participación = 50 puntos de reputación. El huerto te necesita.',
  0,NULL,NULL,'2026-06-18 08:00:00',NULL),
(10,10,'recordatorio','Jornada Presencial — Sáb 21 jun, 10:00',
  'Miguel, te esperamos en la jornada del sábado. Como Mentor, tu presencia es clave para guiar a los nuevos vecinos.',
  0,NULL,NULL,'2026-06-18 08:00:00',NULL),
-- LEÍDAS — logros desbloqueados
(11, 7,'logro','🏆 Nuevo título: Historiadora del Huerto',
  '¡Felicidades Rosa! Has documentado 10 cosechas y jornadas del huerto con fotografías. Has obtenido el título de Historiadora del Huerto Comunitario.',
  1,'usuario',7,'2026-06-10 12:00:00','2026-06-10 14:30:00'),
(12,10,'logro','🌟 Nuevo título: Mentor del Huerto',
  '¡Felicidades Miguel! Has resuelto dudas de 5 vecinos distintos. Eres el Mentor del Huerto.',
  1,'usuario',10,'2026-06-08 10:00:00','2026-06-08 11:00:00'),
(13, 2,'logro','☀️ Título: Héroe de la Sequía',
  '¡Juan, has completado 30 turnos de riego consecutivos! Eres el Héroe de la Sequía del huerto.',
  1,'usuario',2,'2026-06-05 09:00:00','2026-06-05 10:00:00'),
-- LEÍDAS — cosechas y riegos
(14, 3,'cosecha','Lechugas de P-02 listas para cosechar',
  'Tus lechugas romanas han alcanzado madurez. Fecha estimada: 15 jun. Programa tu cosecha.',
  1,'siembra',2,'2026-06-13 08:00:00','2026-06-13 09:00:00'),
(15, 6,'cosecha','🥒 Pepinos casi listos — P-05',
  'Los pepinos de P-05 están próximos a madurar (estimado 20 jun). Prepárate para la cosecha.',
  1,'siembra',6,'2026-06-15 08:00:00','2026-06-15 18:00:00'),
(16, 5,'riego','Turno cumplido — +10 puntos',
  'Confirmamos el riego de Aromáticas (P-04) del 08 de junio. +10 puntos de reputación añadidos.',
  1,'turno_riego',31,'2026-06-08 07:50:00','2026-06-08 19:00:00'),
(17, 4,'riego','Turno cumplido — +10 puntos',
  'Zanahorias de P-03 regadas correctamente. +10 puntos. Sigue así Carlos.',
  1,'turno_riego',34,'2026-06-10 07:20:00','2026-06-10 08:00:00'),
(18, 1,'sistema','Resumen semanal del huerto',
  'Esta semana: 18 riegos completados, 3 omitidos, 2 cosechas realizadas. Actividad general: BUENA. Ver dashboard para detalle.',
  1,NULL,NULL,'2026-06-15 20:00:00','2026-06-16 07:00:00'),
(19,12,'riego','⚠️ Turno omitido — P-11',
  'Jorge, omitiste el turno del 06 de junio en P-11. Los tomates necesitan riego. Por favor coordina con el equipo.',
  1,'turno_riego',30,'2026-06-06 09:00:00','2026-06-07 10:00:00'),
-- LEÍDAS — históricas (conflictos del caso)
(20,14,'sistema','Bienvenido al Bancal Compartido P-13',
  'Roberto, has sido asignado como responsable principal del Bancal Compartido P-13. Coordina el riego con Isabel, Valentina y Andrés.',
  1,'parcela',13,'2026-02-15 12:00:00','2026-02-15 14:00:00'),
(21, 1,'conflicto','✅ RESUELTO: Doble siembra en P-12',
  'El conflicto de doble siembra en P-12 ha sido resuelto. Se documentó en el historial como lección aprendida que motivó el módulo de mapa 2D.',
  1,'parcela',12,'2026-03-20 16:00:00','2026-03-20 18:00:00'),
(22, 6,'conflicto','Aviso: siembra no autorizada en P-12',
  'Pedro, se detectó que sembraste tomates en la Parcela P-12 sin autorización. Doña Carmen requiere tu presencia para resolver el conflicto.',
  1,'parcela',12,'2026-03-16 09:00:00','2026-03-16 11:00:00'),
(23,13,'conflicto','Siembra no autorizada en tu bancal P-12',
  'Patricia, alguien sembró tomates en tu Parcela P-12 sin consultar. Doña Carmen ya fue notificada y está gestionando la situación.',
  1,'parcela',12,'2026-03-16 09:00:00','2026-03-16 10:00:00'),
-- NO LEÍDA — Claudia nunca ha entrado al sistema
(24,19,'sistema','Bienvenida al Huerto HuertoLink',
  'Claudia, tu registro fue confirmado. Podrás participar como vecina colaboradora. Doña Carmen te asignará un bancal pronto. Explora el dashboard para conocer el huerto.',
  0,'usuario',19,'2026-03-15 11:30:00',NULL),
-- LEÍDA — aviso robo
(25, 3,'conflicto','⚠️ Robo de lechugas en P-02 — Episodio pasado',
  'María, se reportó el robo de tus lechugas en marzo. Se tomaron medidas: habilitación de Parcela Regalo P-16 y sistema de registro de cosechas. Este incidente motivó HuertoLink.',
  1,'parcela',2,'2026-03-10 10:00:00','2026-03-11 08:00:00');


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.10  HISTORIAL DE ACTIVIDADES (30 registros)           │
-- │  Log de auditoría — trazabilidad completa del sistema.   │
-- │  El campo metadata JSON permite filtros avanzados.       │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO historial_actividades
  (id_actividad,id_usuario,tipo_actividad,descripcion,
   entidad_tipo,entidad_id,metadata,fecha_hora)
VALUES
(1, 1,'login','Doña Carmen inició sesión en HuertoLink',
  'usuario',1,'{"dispositivo":"smartphone","ip":"192.168.1.100"}',
  '2026-06-18 08:30:00'),
(2, 2,'login','Juan Pérez inició sesión',
  'usuario',2,'{"dispositivo":"smartphone"}',
  '2026-06-18 07:15:00'),
(3, 7,'riego_completado','Rosa Hernández completó riego de P-06 Bancal Rosa',
  'turno_riego',5,'{"parcela":"P-06","litros":15,"minutos":20}',
  '2026-06-18 07:35:00'),
(4, 8,'riego_omitido','Luis Ramírez omitió turno de riego en P-07',
  'turno_riego',6,'{"parcela":"P-07","motivo":"no_presentado","omisiones_mes":3}',
  '2026-06-18 09:30:00'),
(5, 1,'riego_completado','Carmen completó riego de Parcela Comunitaria P-15',
  'turno_riego',23,'{"parcela":"P-15","litros":25,"minutos":30,"inspeccion":true}',
  '2026-06-17 09:10:00'),
(6, 9,'cosecha','Elena Castro cosechó rábanos en P-08',
  'cosecha',10,'{"cultivo":"Rábano","cantidad":0.6,"unidad":"kg","distribuida":false}',
  '2026-06-16 11:00:00'),
(7, 7,'cosecha','Rosa Hernández cosechó espinacas en P-06',
  'cosecha',5,'{"cultivo":"Espinaca","cantidad":1.5,"unidad":"kg","distribuida":true}',
  '2026-06-14 11:00:00'),
(8, 1,'cosecha','Doña Carmen cosechó cilantro comunitario P-15',
  'cosecha',4,'{"cultivo":"Cilantro","cantidad":3,"unidad":"manojo","jornada":true}',
  '2026-06-12 10:30:00'),
(9, 7,'historial_foto','Rosa documentó el estado del huerto con fotografías para la jornada mensual',
  NULL,NULL,'{"fotos":12,"evento":"jornada_mensual","mes":"junio_2026"}',
  '2026-06-12 10:00:00'),
(10,12,'riego_omitido','Jorge Reyes omitió turno de riego en P-11',
  'turno_riego',30,'{"parcela":"P-11","motivo":"no_presentado"}',
  '2026-06-06 09:00:00'),
(11, 2,'riego_completado','Juan Pérez completó riego P-01 (inicio de semana)',
  'turno_riego',17,'{"parcela":"P-01","litros":20,"minutos":25}',
  '2026-06-16 07:10:00'),
(12, 4,'riego_completado','Carlos Muñoz completó riego P-03',
  'turno_riego',20,'{"parcela":"P-03","litros":15,"minutos":20}',
  '2026-06-16 08:45:00'),
(13, 3,'cosecha','María González cosechó lechugas en P-02',
  'cosecha',1,'{"cultivo":"Lechuga Romana","cantidad":6,"unidad":"unidad","distribuida":true}',
  '2026-06-05 09:00:00'),
(14, 5,'cosecha','Ana Flores cosechó cilantro en P-04',
  'cosecha',2,'{"cultivo":"Cilantro","cantidad":4,"unidad":"manojo"}',
  '2026-06-08 10:00:00'),
(15, 8,'cosecha','Luis Ramírez cosechó cebolla de verdeo P-07 sin registrar previamente',
  'cosecha',3,'{"cultivo":"Cebolla de Verdeo","cantidad":8,"unidad":"manojo","sin_registro_previo":true}',
  '2026-06-10 09:00:00'),
(16, 6,'observacion','Pedro Martínez reportó plaga de pulgones en P-05',
  'observacion',3,'{"tipo":"plaga","cultivo":"Pepino","urgencia":"alta"}',
  '2026-06-08 16:00:00'),
(17,10,'consulta','Miguel Torres respondió consulta técnica sobre zanahorias de Carlos',
  'observacion',4,'{"tipo":"consulta_mentor","resolucion":"explicó indicadores de madurez"}',
  '2026-06-01 17:00:00'),
(18,17,'riego_completado','Valentina Soto completó riego de Parcela Comunitaria P-15',
  'turno_riego',35,'{"parcela":"P-15","litros":20,"minutos":25,"sustituto":true}',
  '2026-06-10 09:10:00'),
(19,15,'riego_completado','Isabel Vargas cubrió riego del Bancal Compartido P-13',
  'turno_riego',51,'{"parcela":"P-13","sustituyo_a":"Roberto Morales"}',
  '2026-05-20 08:20:00'),
(20, 2,'cosecha','Juan Pérez cosechó lechugas en P-01',
  'cosecha',6,'{"cultivo":"Lechuga Romana","cantidad":5,"unidad":"unidad","distribuida":true}',
  '2026-05-10 09:00:00'),
(21, 7,'cosecha','Rosa Hernández cosechó cilantro en P-06',
  'cosecha',7,'{"cultivo":"Cilantro","cantidad":5,"unidad":"manojo","jornada_sabado":true}',
  '2026-05-12 11:00:00'),
(22,10,'siembra','Miguel Torres registró siembra de tomates en P-09',
  'siembra',12,'{"cultivo":"Tomate Cherry","parcela":"P-09","cantidad":10,"unidad":"plantas"}',
  '2026-04-10 09:00:00'),
(23, 7,'siembra','Rosa Hernández registró siembra de espinacas en P-06',
  'siembra',8,'{"cultivo":"Espinaca","parcela":"P-06","cantidad":1,"unidad":"m2"}',
  '2026-05-05 10:00:00'),
(24, 1,'gestion_parcela','Doña Carmen actualizó estado de P-14 a mantenimiento',
  'parcela',14,'{"estado_anterior":"disponible","estado_nuevo":"mantenimiento","motivo":"malla_soporte_danada"}',
  '2026-05-20 10:00:00'),
(25, 3,'login','María González inició sesión',
  'usuario',3,'{"dispositivo":"smartphone"}',
  '2026-06-17 19:00:00'),
(26, 9,'login','Elena Castro inició sesión',
  'usuario',9,'{"dispositivo":"smartphone"}',
  '2026-06-17 20:00:00'),
(27,16,'login','Diego Fuentes — último acceso registrado',
  'usuario',16,'{"dispositivo":"smartphone"}',
  '2026-04-15 12:00:00'),
-- Eventos históricos: los dos conflictos del caso Huerto Herido
(28, 1,'conflicto','Doña Carmen reportó robo de lechugas en bancal P-02',
  'observacion',1,'{"tipo":"vandalismo","cultivo":"Lechuga","cantidad_perdida":"cosecha_total","medida":"parcela_regalo"}',
  '2026-03-10 09:00:00'),
(29, 1,'conflicto','Conflicto doble siembra P-12 gestionado por Coordinadora',
  'observacion',2,'{"usuarios_involucrados":[6,13],"resolucion":"mediacion_directa","siembra_perdida":25}',
  '2026-03-20 16:00:00'),
(30, 1,'siembra','Carmen habilitó Parcela Regalo P-16 como medida anti-robo',
  'parcela',16,'{"motivo":"prevencion_robos","tipo":"theft_plot","cultivos":["Lechuga","Rábano"]}',
  '2026-03-01 10:00:00');


-- ┌──────────────────────────────────────────────────────────┐
-- │  5.11  OBSERVACIONES E INCIDENCIAS (10 registros)        │
-- │  Refleja los conflictos reales del caso Huerto Herido:   │
-- │  obs #1: Robo de lechuga (conflicto documentado en caso) │
-- │  obs #2: Doble siembra tomates (conflicto documentado)   │
-- │  obs #3-10: Incidencias actuales del huerto              │
-- └──────────────────────────────────────────────────────────┘
INSERT INTO observaciones
  (id_observacion,id_parcela,id_usuario,id_usuario_resuelve,
   tipo,titulo,descripcion,estado,prioridad,
   fecha_reporte,fecha_resolucion,notas_resolucion)
VALUES
-- #1 — VANDALISMO: robo de lechuga (conflicto real del caso original)
(1,2,1,1,
  'vandalismo','Robo completo de lechugas — Parcela P-02',
  'Se encontró el bancal P-02 completamente vaciado. Alguien se llevó todas las lechugas de María González sin autorización ni aviso previo. Tercer incidente de robo en el huerto en 2 meses. Doña Carmen está a punto de renunciar según su propio testimonio.',
  'resuelta','urgente',
  '2026-03-10 09:00:00','2026-03-15 16:00:00',
  'Se habilitó la Parcela Regalo P-16 como medida disuasoria (Theft Plot). Se instaló señalización digital. Se acordó el sistema de registro de cosechas para identificar retiros no autorizados. Este incidente fue el detonante principal para crear HuertoLink.'),

-- #2 — CONFLICTO: doble siembra de tomates (conflicto real del caso original)
(2,12,6,1,
  'conflicto','Doble siembra de tomates en P-12 — Sin coordinación previa',
  'Pedro Martínez sembró 4 plantas de tomate en la Parcela P-12 asignada a Patricia Díaz, el mismo día y en el mismo espacio, sin coordinar. Los tomates de ambos se dañaron mutuamente por competencia de recursos. Patricia descubrió el problema 3 días después. La única comunicación era el grupo de WhatsApp con 300 mensajes diarios donde nadie se enteró de nada.',
  'resuelta','alta',
  '2026-03-16 08:00:00','2026-03-20 18:00:00',
  'Mediación directa con ambos vecinos conducida por Doña Carmen. Siembra de Pedro marcada como perdida. Se diseñó el módulo de mapa 2D para visualizar qué hay sembrado en cada parcela ANTES de iniciar una nueva siembra. Este conflicto es el caso de uso principal que justifica el desarrollo de HuertoLink.'),

-- #3 — PLAGA activa en pepinos de Pedro
(3,5,6,NULL,
  'plaga','Presencia de pulgones en P-05 — Pepinos en riesgo',
  'Se detectaron colonias de pulgones (áfidos) en las hojas de los pepinos del Bancal P-05. El problema comenzó hace 3 días y se está expandiendo hacia los pimientos. Riesgo de contagio al bancal vecino P-06 de Rosa.',
  'en_proceso','alta',
  '2026-06-08 16:00:00',NULL,NULL),

-- #4 — CONSULTA resuelta por el Mentor
(4,3,4,10,
  'consulta','¿Cómo saber si las zanahorias están listas para cosechar?',
  'Carlos Muñoz consulta cómo identificar la madurez de las zanahorias. Primera vez que cultiva raíces. Tiene miedo de cosechar demasiado pronto o demasiado tarde.',
  'resuelta','baja',
  '2026-06-01 14:00:00','2026-06-01 17:00:00',
  'Miguel Torres (Mentor) explicó: revisar que el cuello visible supere 1 cm de diámetro y que el color de la piel superior sea anaranjado uniforme. Las de Carlos estarán listas aproximadamente el 5 de julio.'),

-- #5 — INCIDENCIA: posible abandono del bancal de Patricia
(5,12,1,NULL,
  'incidencia','Riesgo de abandono — Bancal P-12 Patricia Díaz',
  'Patricia Díaz lleva 20 días sin registrar actividad en el sistema. No ha completado ningún turno de riego y tampoco responde en el grupo de WhatsApp. El cultivo podría perderse por falta de riego. Doña Carmen intentó contactarla sin respuesta.',
  'en_proceso','alta',
  '2026-06-15 10:00:00',NULL,NULL),

-- #6 — MEJORA propuesta por el Mentor
(6,NULL,10,NULL,
  'mejora','Propuesta: Sistema de turnos de riego rotativo quincenal',
  'Miguel Torres propone implementar un sistema de turnos de riego rotativos quincenales para distribuir equitativamente la carga entre todos los vecinos, reemplazando el sistema fijo actual. Esto obligaría a los vecinos menos activos como Luis y Jorge a asumir más responsabilidad de forma algorítmica y justa.',
  'abierta','media',
  '2026-06-10 19:00:00',NULL,NULL),

-- #7 — INCIDENCIA: cosecha sin registro
(7,7,9,8,
  'incidencia','Cosecha de cebolla de verdeo sin registro previo — P-07',
  'Elena Castro reporta que alguien cosechó cebollas de verdeo del bancal P-07 de Luis Ramírez sin registrarlo en el sistema. Se perdieron 3 manojos sin trazabilidad. Esto recuerda el incidente original de las lechugas de María.',
  'resuelta','media',
  '2026-06-11 11:00:00','2026-06-11 15:00:00',
  'Luis Ramírez reconoció haber cosechado para uso personal sin registrar. Se le recordó el protocolo de registro obligatorio. Se añadió 10 puntos negativos a su historial y se envió notificación de advertencia.'),

-- #8 — VANDALISMO menor: señalización de Parcela Regalo dañada
(8,16,7,1,
  'vandalismo','Señalización de Parcela Regalo P-16 dañada',
  'La señalización física e informativa de la Parcela Regalo P-16 fue arrancada y encontrada en el suelo. La zona sigue funcionando pero sin indicación visible para transeúntes del barrio.',
  'resuelta','baja',
  '2026-05-25 08:00:00','2026-05-27 10:00:00',
  'Señalización repuesta. Se evaluará señalización más resistente. Se documentó para proponer señalización digital con código QR que enlace al mapa de HuertoLink.'),

-- #9 — CONSULTA abierta: albahaca con hojas amarillas
(9,4,5,NULL,
  'consulta','Albahaca con hojas amarillas en la base — P-04',
  'Ana Flores observa que las hojas inferiores de la albahaca en P-04 están amarillando. No sabe si es exceso de riego, déficit de nutrientes, o alguna enfermedad fúngica. La planta sigue produciendo en la parte superior.',
  'abierta','media',
  '2026-06-17 16:00:00',NULL,NULL),

-- #10 — INCIDENCIA: infraestructura dañada P-14
(10,14,1,NULL,
  'incidencia','Malla de soporte deteriorada — Parcela P-14 fuera de servicio',
  'La malla de soporte del Bancal P-14 está completamente deteriorada y no puede sostener cultivos trepadores ni verticales. Se requiere inversión de mantenimiento antes de reactivar esta parcela. Está marcada como "mantenimiento" en el sistema.',
  'en_proceso','media',
  '2026-05-18 09:00:00',NULL,NULL);

-- ============================================================
-- RESTAURAR CONFIGURACIÓN
-- ============================================================
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- SECCIÓN 6: VERIFICACIÓN — CONSULTAS DE COMPROBACIÓN
-- Ejecutar estas consultas para validar que los datos
-- fueron insertados correctamente y que las vistas funcionan.
-- ============================================================

/*
-- ── CONTEO DE REGISTROS POR TABLA ──────────────────────────
SELECT 'roles'                  AS tabla, COUNT(*) AS registros FROM roles
UNION ALL SELECT 'cultivos',              COUNT(*) FROM cultivos
UNION ALL SELECT 'usuarios',              COUNT(*) FROM usuarios
UNION ALL SELECT 'parcelas',              COUNT(*) FROM parcelas
UNION ALL SELECT 'siembras',              COUNT(*) FROM siembras
UNION ALL SELECT 'turnos_riego',          COUNT(*) FROM turnos_riego
UNION ALL SELECT 'registro_riego',        COUNT(*) FROM registro_riego
UNION ALL SELECT 'cosechas',              COUNT(*) FROM cosechas
UNION ALL SELECT 'notificaciones',        COUNT(*) FROM notificaciones
UNION ALL SELECT 'historial_actividades', COUNT(*) FROM historial_actividades
UNION ALL SELECT 'observaciones',         COUNT(*) FROM observaciones;

-- ── DASHBOARD PREGUNTA 1: Turnos pendientes hoy ────────────
SELECT * FROM v_turnos_hoy WHERE estado = 'pendiente';

-- ── DASHBOARD PREGUNTA 2: Cosechas de junio 2026 ───────────
SELECT * FROM v_cosechas_mes WHERE anio = 2026 AND mes = 6;

-- ── DASHBOARD PREGUNTA 3: Ranking completo de vecinos ──────
SELECT * FROM v_ranking_vecinos;

-- ── Vecinos con menor cumplimiento (para alertas) ──────────
SELECT * FROM v_ranking_vecinos
WHERE riegos_omitidos > 0
ORDER BY pct_cumplimiento ASC;

-- ── Parcelas con siembra activa y próximas a cosechar ──────
SELECT p.codigo, p.nombre, c.nombre_comun, s.fecha_estimada_cosecha,
       DATEDIFF(s.fecha_estimada_cosecha, CURDATE()) AS dias_restantes
FROM siembras s
  JOIN parcelas p ON s.id_parcela = p.id_parcela
  JOIN cultivos c ON s.id_cultivo = c.id_cultivo
WHERE s.estado = 'activa'
ORDER BY s.fecha_estimada_cosecha;

-- ── Notificaciones no leídas por usuario (para badge) ──────
SELECT u.nombre, u.apellido, COUNT(*) AS no_leidas
FROM notificaciones n JOIN usuarios u ON n.id_usuario = u.id_usuario
WHERE n.leida = 0
GROUP BY n.id_usuario ORDER BY no_leidas DESC;

-- ── Incidencias urgentes abiertas ──────────────────────────
SELECT id_observacion, tipo, titulo, prioridad, fecha_reporte
FROM observaciones
WHERE estado IN ('abierta','en_proceso')
ORDER BY FIELD(prioridad,'urgente','alta','media','baja');

-- ── Registros offline pendientes de sincronización ─────────
SELECT rr.id_registro, p.codigo, CONCAT(u.nombre,' ',u.apellido) AS vecino,
       rr.fecha_hora_riego
FROM registro_riego rr
  JOIN turnos_riego t ON rr.id_turno = t.id_turno
  JOIN parcelas p ON t.id_parcela = p.id_parcela
  JOIN usuarios u ON rr.id_usuario = u.id_usuario
WHERE rr.sincronizado = 0;
*/

-- ============================================================
-- FIN DEL SCRIPT — HuertoLink v1.0.0
-- Total: 11 tablas | 3 vistas | ~220 registros de prueba
-- ============================================================
