-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS todo_list
    CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE todo_list;

-- Tabla de categorías: clasifica las tareas.
CREATE TABLE IF NOT EXISTS categorias (
                            id_categoria INT NOT NULL AUTO_INCREMENT,
                            nombre VARCHAR(100) NOT NULL,
                            creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                            actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                            PRIMARY KEY (id_categoria)
);

-- Tabla de usuario: para la autenticación y gestión de usuarios.
CREATE TABLE IF NOT EXISTS usuario (
                         id_usuario INT NOT NULL AUTO_INCREMENT,
                         nombre VARCHAR(100) NOT NULL,
                         email VARCHAR(100) NOT NULL UNIQUE,
                         contrasena VARCHAR(255) NOT NULL,
                         creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                         actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                         PRIMARY KEY (id_usuario)
);

-- Tabla de tarea: con la información principal de la tarea.
-- Se mantiene la columna 'estado' con ENUM para un estado inmediato.
CREATE TABLE IF NOT EXISTS tarea (
                       id_tarea INT NOT NULL AUTO_INCREMENT,
                       titulo VARCHAR(255) NOT NULL,
                       descripcion TEXT DEFAULT NULL,
                       estado ENUM('Nueva', 'En Progreso', 'Completado', 'Pendiente') DEFAULT 'Nueva',
                       completada BOOLEAN DEFAULT FALSE,
                       fecha_limite DATE DEFAULT NULL,
                       categoria_id INT NOT NULL,
                       usuario_id INT NOT NULL,
                       creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                       actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                       PRIMARY KEY (id_tarea),
                       CONSTRAINT fk_tarea_categoria FOREIGN KEY (categoria_id) REFERENCES categorias(id_categoria),
                       CONSTRAINT fk_tarea_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id_usuario)
);

-- Tabla de etiqueta: almacena las etiquetas para las tareas.
CREATE TABLE IF NOT EXISTS etiqueta (
                          id_etiqueta INT NOT NULL AUTO_INCREMENT,
                          nombre VARCHAR(100) NOT NULL,
                          creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                          actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                          PRIMARY KEY (id_etiqueta)
);

-- Tabla intermedia tarea_etiqueta: representa la relación muchos a muchos entre tareas y etiquetas.
CREATE TABLE IF NOT EXISTS tarea_etiqueta (
                                tarea_id INT NOT NULL,
                                etiqueta_id INT NOT NULL,
                                PRIMARY KEY (tarea_id, etiqueta_id),
                                CONSTRAINT fk_tarea_etiqueta_tarea FOREIGN KEY (tarea_id) REFERENCES tarea(id_tarea),
                                CONSTRAINT fk_tarea_etiqueta_etiqueta FOREIGN KEY (etiqueta_id) REFERENCES etiqueta(id_etiqueta)
);


-- inserts
use todo_list;
-- Índice en la tabla 'tarea' para optimizar las búsquedas por estado de la tarea.
ALTER TABLE tarea
    ADD INDEX idx_tarea_estado (estado);

-- Documentación:
-- Este índice permite filtrar rápidamente las tareas según su estado (por ejemplo, "Nueva", "En Progreso", etc.).

-- Índice en la tabla 'tarea' para optimizar consultas basadas en la fecha límite.
ALTER TABLE tarea
    ADD INDEX idx_tarea_fecha_limite (fecha_limite);

-- Documentación:
-- Este índice es útil cuando se desea obtener tareas ordenadas o filtradas por la fecha límite,
-- especialmente en escenarios donde se muestran próximas o vencidas.

-- Índice en la tabla 'etiqueta' para acelerar búsquedas por nombre de etiqueta.
ALTER TABLE etiqueta
    ADD INDEX idx_etiqueta_nombre (nombre);

-- Documentación:
-- Este índice ayuda a agilizar las búsquedas y comparaciones cuando se filtra o une con tareas por el nombre de la etiqueta.

-- Índice en la tabla 'tarea' para optimizar la unión (JOIN) con la tabla 'categorias'.
ALTER TABLE tarea
    ADD INDEX idx_tarea_categoria (categoria_id);

-- Documentación:
-- Si bien la llave foránea ya suele crear un índice automáticamente, este comando refuerza la optimización
-- al relacionar tareas con sus respectivas categorías.

-- Índice en la tabla 'tarea' para optimizar la unión (JOIN) con la tabla 'usuario'.
ALTER TABLE tarea
    ADD INDEX idx_tarea_usuario (usuario_id);

-- Documentación:
-- Similar al caso anterior, este índice mejora el rendimiento de las consultas que requieren unir o filtrar
-- las tareas según el usuario.


DELIMITER $$
CREATE TRIGGER before_categoria_delete
    BEFORE DELETE ON categorias
    FOR EACH ROW
BEGIN
    DECLARE tareas_incompletas INT;

  -- Se cuenta la cantidad de tareas asociadas a la categoría que no están completadas.
    SELECT COUNT(*) INTO tareas_incompletas
    FROM tarea
    WHERE categoria_id = OLD.id_categoria
      AND estado <> 'Completado';

    -- Si hay tareas incompletas, se impide la eliminación de la categoría.
    IF tareas_incompletas > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar la categoría porque tiene tareas incompletas o en progreso';
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_tarea_insert
    BEFORE INSERT ON tarea
    FOR EACH ROW
BEGIN
    -- Se actualiza el campo 'completada' según el valor de 'estado'.
    IF NEW.estado = 'Completado' THEN
    SET NEW.completada = TRUE;
    ELSE
    SET NEW.completada = FALSE;
END IF;
END$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER before_tarea_update
    BEFORE UPDATE ON tarea
    FOR EACH ROW
BEGIN
    -- Se actualiza el campo 'completada' en función del valor de 'estado' al editar la tarea.
    IF NEW.estado = 'Completado' THEN
    SET NEW.completada = TRUE;
    ELSE
    SET NEW.completada = FALSE;
END IF;
END$$
DELIMITER ;


CREATE VIEW vw_tareas_detalle AS
SELECT
    t.id_tarea,
    t.titulo,
    t.descripcion,
    t.estado,
    t.completada,
    t.fecha_limite,
    c.nombre AS categoria,
    u.nombre AS usuario,
    t.creada_en,
    t.actualizada_en
FROM tarea t
         JOIN categorias c ON t.categoria_id = c.id_categoria
         JOIN usuario u ON t.usuario_id = u.id_usuario;


CREATE VIEW vw_tareas_pendientes AS
SELECT
    t.id_tarea,
    t.titulo,
    t.descripcion,
    t.estado,
    t.completada,
    t.fecha_limite,
    t.categoria_id,
    t.usuario_id,
    t.creada_en,
    t.actualizada_en
FROM tarea t
WHERE t.estado <> 'Completado';


CREATE VIEW vw_resumen_categorias AS
SELECT
    c.id_categoria,
    c.nombre AS categoria,
    COUNT(t.id_tarea) AS total_tareas,
    SUM(CASE WHEN t.estado = 'Completado' THEN 1 ELSE 0 END) AS tareas_completadas,
    SUM(CASE WHEN t.estado <> 'Completado' THEN 1 ELSE 0 END) AS tareas_pendientes
FROM categorias c
         LEFT JOIN tarea t ON c.id_categoria = t.categoria_id
GROUP BY c.id_categoria, c.nombre;


CREATE VIEW vw_tareas_vencidas AS
SELECT
    t.id_tarea,
    t.titulo,
    t.descripcion,
    t.estado,
    t.fecha_limite,
    u.nombre AS usuario,
    c.nombre AS categoria,
    t.creada_en,
    t.actualizada_en
FROM tarea t
         JOIN usuario u ON t.usuario_id = u.id_usuario
         JOIN categorias c ON t.categoria_id = c.id_categoria
WHERE t.fecha_limite IS NOT NULL
  AND t.fecha_limite < CURDATE()
  AND t.estado <> 'Completado';


CREATE VIEW vw_tareas_etiquetas AS
SELECT
    t.id_tarea,
    t.titulo,
    t.descripcion,
    t.estado,
    t.fecha_limite,
    GROUP_CONCAT(e.nombre ORDER BY e.nombre SEPARATOR ', ') AS etiquetas,
    u.nombre AS usuario,
    c.nombre AS categoria,
    t.creada_en,
    t.actualizada_en
FROM tarea t
         LEFT JOIN tarea_etiqueta te ON t.id_tarea = te.tarea_id
         LEFT JOIN etiqueta e ON te.etiqueta_id = e.id_etiqueta
         JOIN usuario u ON t.usuario_id = u.id_usuario
         JOIN categorias c ON t.categoria_id = c.id_categoria
GROUP BY t.id_tarea, t.titulo, t.descripcion, t.estado, t.fecha_limite,
         u.nombre, c.nombre, t.creada_en, t.actualizada_en;

--
DELIMITER $$

/*===============================
  CATEGORÍAS
================================*/

/* Crear una nueva categoría */
CREATE PROCEDURE sp_create_category(
    IN p_nombre VARCHAR(100)
)
BEGIN
INSERT INTO categorias (nombre)
VALUES (p_nombre);
END$$

/* Actualizar el nombre de una categoría */
CREATE PROCEDURE sp_update_category(
    IN p_id_categoria INT,
    IN p_nombre VARCHAR(100)
)
BEGIN
UPDATE categorias
SET nombre = p_nombre
WHERE id_categoria = p_id_categoria;
END$$

/* Eliminar una categoría solo si no tiene tareas incompletas */
CREATE PROCEDURE sp_delete_category(
    IN p_id_categoria INT
)
BEGIN
  DECLARE v_incompletas INT;
  -- Contar tareas asociadas que no estén completadas
SELECT COUNT(*) INTO v_incompletas
FROM tarea
WHERE categoria_id = p_id_categoria
  AND estado <> 'Completado';
IF v_incompletas > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar: existen tareas incompletas';
ELSE
DELETE FROM categorias
WHERE id_categoria = p_id_categoria;
END IF;
END$$

/* Listar todas las categorías */
CREATE PROCEDURE sp_list_categories()
BEGIN
SELECT * FROM categorias;
END$$


/*===============================
  USUARIOS
================================*/

/* Crear un nuevo usuario (la contraseña debe ser un hash) */
CREATE PROCEDURE sp_create_user(
    IN p_nombre VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_hash_contrasena VARCHAR(255)
)
BEGIN
INSERT INTO usuario (nombre, email, contrasena)
VALUES (p_nombre, p_email, p_hash_contrasena);
END$$

/* Obtener usuario por email (para autenticación) */
CREATE PROCEDURE sp_get_user_by_email(
    IN p_email VARCHAR(100)
)
BEGIN
SELECT id_usuario, nombre, email, contrasena
FROM usuario
WHERE email = p_email;
END$$

/* Actualizar contraseña de usuario */
CREATE PROCEDURE sp_update_user_password(
    IN p_id_usuario INT,
    IN p_new_hash VARCHAR(255)
)
BEGIN
UPDATE usuario
SET contrasena = p_new_hash,
    actualizado_en = CURRENT_TIMESTAMP
WHERE id_usuario = p_id_usuario;
END$$

/* Eliminar usuario (y opcionalmente, sus tareas) */
CREATE PROCEDURE sp_delete_user(
    IN p_id_usuario INT
)
BEGIN
  -- Si prefieres borrar sus tareas: uncomment siguiente línea
  -- DELETE FROM tarea WHERE usuario_id = p_id_usuario;
DELETE FROM usuario WHERE id_usuario = p_id_usuario;
END$$


/*===============================
  TAREAS
================================*/

/* Crear una tarea nueva */
CREATE PROCEDURE sp_create_task(
    IN p_titulo VARCHAR(255),
    IN p_descripcion TEXT,
    IN p_estado ENUM('Nueva','En Progreso','Completado','Pendiente'),
    IN p_fecha_limite DATE,
    IN p_categoria_id INT,
    IN p_usuario_id INT
        )
BEGIN
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id)
VALUES (p_titulo, p_descripcion, p_estado, p_fecha_limite, p_categoria_id, p_usuario_id);
END$$

/* Consultar una tarea por su ID */
CREATE PROCEDURE sp_get_task_by_id(
    IN p_id_tarea INT
)
BEGIN
SELECT * FROM tarea
WHERE id_tarea = p_id_tarea;
END$$

/* Listar tareas de un usuario */
CREATE PROCEDURE sp_list_tasks_by_user(
    IN p_usuario_id INT
)
BEGIN
SELECT *
FROM tarea
WHERE usuario_id = p_usuario_id;
END$$

/* Actualizar datos de una tarea */
CREATE PROCEDURE sp_update_task(
    IN p_id_tarea INT,
    IN p_titulo VARCHAR(255),
    IN p_descripcion TEXT,
    IN p_estado ENUM('Nueva','En Progreso','Completado','Pendiente'),
    IN p_fecha_limite DATE,
    IN p_categoria_id INT
        )
BEGIN
UPDATE tarea
SET titulo       = p_titulo,
    descripcion  = p_descripcion,
    estado       = p_estado,
    fecha_limite = p_fecha_limite,
    categoria_id = p_categoria_id
WHERE id_tarea = p_id_tarea;
END$$

/* Marcar una tarea como completada */
CREATE PROCEDURE sp_mark_task_complete(
    IN p_id_tarea INT
)
BEGIN
UPDATE tarea
SET estado     = 'Completado',
    completada = TRUE
WHERE id_tarea = p_id_tarea;
END$$

/* Eliminar una tarea */
CREATE PROCEDURE sp_delete_task(
    IN p_id_tarea INT
)
BEGIN
DELETE FROM tarea
WHERE id_tarea = p_id_tarea;
END$$


/*===============================
  ETIQUETAS
================================*/

/* Crear una nueva etiqueta */
CREATE PROCEDURE sp_create_label(
    IN p_nombre VARCHAR(100)
)
BEGIN
INSERT INTO etiqueta (nombre)
VALUES (p_nombre);
END$$

/* Asignar una etiqueta a una tarea */
CREATE PROCEDURE sp_assign_label_to_task(
    IN p_id_tarea INT,
    IN p_id_etiqueta INT
)
BEGIN
  INSERT IGNORE INTO tarea_etiqueta (tarea_id, etiqueta_id)
  VALUES (p_id_tarea, p_id_etiqueta);
END$$

/* Desasignar una etiqueta de una tarea */
CREATE PROCEDURE sp_remove_label_from_task(
    IN p_id_tarea INT,
    IN p_id_etiqueta INT
)
BEGIN
DELETE FROM tarea_etiqueta
WHERE tarea_id    = p_id_tarea
  AND etiqueta_id = p_id_etiqueta;
END$$

/* Eliminar etiqueta solo si no está asociada a ninguna tarea */
CREATE PROCEDURE sp_delete_label(
    IN p_id_etiqueta INT
)
BEGIN
  DECLARE v_count INT;
SELECT COUNT(*) INTO v_count
FROM tarea_etiqueta
WHERE etiqueta_id = p_id_etiqueta;
IF v_count > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'No se puede eliminar: etiqueta en uso';
ELSE
DELETE FROM etiqueta
WHERE id_etiqueta = p_id_etiqueta;
END IF;
END$$

/* Listar todas las etiquetas */
CREATE PROCEDURE sp_list_labels()
BEGIN
SELECT * FROM etiqueta;
END$$

DELIMITER ;


-- ==============================================
-- INSERTS DE CATEGORÍAS
-- ==============================================
-- Se crean categorías iniciales para asignar a las tareas.
INSERT INTO categorias (nombre) VALUES
                                    ('General'),               -- id_categoria = 1
                                    ('Casa'),                  -- id_categoria = 2
                                    ('Compras'),               -- id_categoria = 3
                                    ('Base de datos 2'),       -- id_categoria = 4
                                    ('Comunicación 1'),        -- id_categoria = 5
                                    ('Desarrollo de Software 2'), -- id_categoria = 6
                                    ('Redes 1'),               -- id_categoria = 7
                                    ('Sistemas Operativos 2'), -- id_categoria = 8
                                    ('Historia');              -- id_categoria = 9

-- ==============================================
-- INSERTS DE USUARIOS
-- ==============================================
--
INSERT INTO usuario (nombre, email, contrasena) VALUES
                                                    ('Juan Pérez',     'juan.perez@example.com',    'hash_pw_juan'),
                                                    ('María López',    'maria.lopez@example.com',   'hash_pw_maria'),
                                                    ('Carlos García',  'carlos.garcia@example.com', 'hash_pw_carlos'),
                                                    ('Ana Fernández',  'ana.fernandez@example.com', 'hash_pw_ana'),
                                                    ('Luis Martínez',  'luis.martinez@example.com', 'hash_pw_luis');

-- ==============================================
-- INSERTS DE TAREAS POR USUARIO
-- ==============================================
-- Usuario 1: Juan Pérez (id_usuario = 1)
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id) VALUES
                                                                                            ('Lavar los platos',               'Lavar todos los platos del día',                     'Nueva', '2025-04-17', 2, 1),
                                                                                            ('Barrer la sala',                 'Barrer y sacar el polvo de la sala de estar',        'Nueva', '2025-04-18', 2, 1),
                                                                                            ('Hacer compra: leche, pan, huevos','Comprar víveres básicos para la semana',            'Nueva', '2025-04-17', 3, 1),
                                                                                            ('Comprar frutas: manzanas y plátanos','Comprar frutas frescas para el desayuno',         'Nueva', '2025-04-17', 3, 1),
                                                                                            ('Leer capítulo 3 de Base de datos 2','Estudiar el modelo relacional y normalización',  'Nueva', '2025-04-25', 4, 1),
                                                                                            ('Entregar práctica de SO2',       'Resolver ejercicios prácticos de Sistemas Operativos 2', 'Nueva', '2025-04-28', 8, 1);

-- Usuario 2: María López (id_usuario = 2)
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id) VALUES
                                                                                            ('Planchar la ropa',               'Planchar camisas y pantalones',                     'Nueva', '2025-04-18', 2, 2),
                                                                                            ('Limpiar el baño',                'Limpieza profunda de lavabo y ducha',               'Nueva', '2025-04-18', 2, 2),
                                                                                            ('Comprar café y azúcar',          'Reponer café molido y paquete de azúcar',           'Nueva', '2025-04-17', 3, 2),
                                                                                            ('Investigar tema para Comunicación 1','Buscar fuentes para el trabajo de comunicación', 'Nueva', '2025-04-24', 5, 2),
                                                                                            ('Preparar presentación DS2',      'Diapositivas sobre patrones de diseño en Java',     'Nueva', '2025-04-27', 6, 2),
                                                                                            ('Resolver ejercicios de Redes 1', 'Practicar subredes y tabla de enrutamiento',        'Nueva', '2025-04-26', 7, 2);

-- Usuario 3: Carlos García (id_usuario = 3)
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id) VALUES
                                                                                            ('Sacar la basura',                'Llevar los desechos al contenedor',                 'Nueva', '2025-04-17', 2, 3),
                                                                                            ('Organizar el garaje',            'Clasificar cajas y barrer el suelo',                'Nueva', '2025-04-19', 2, 3),
                                                                                            ('Comprar material de oficina',    'Bloc de notas, bolígrafos y post-its',              'Nueva', '2025-04-18', 3, 3),
                                                                                            ('Estudiar para parcial de Historia','Revisar apuntes de historia contemporánea',        'Nueva', '2025-04-30', 9, 3),
                                                                                            ('Desarrollar proyecto BD2',       'Implementar esquema ER en MySQL',                   'Nueva', '2025-05-02', 4, 3),
                                                                                            ('Exposición de Comunicación 1',   'Preparar discurso y diapositivas',                  'Nueva', '2025-05-05', 5, 3);

-- Usuario 4: Ana Fernández (id_usuario = 4)
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id) VALUES
                                                                                            ('Regar las plantas',              'Regar plantas de interior y exterior',              'Nueva', '2025-04-17', 2, 4),
                                                                                            ('Limpiar ventanas',               'Limpieza con limpiavidrios y paño suave',           'Nueva', '2025-04-19', 2, 4),
                                                                                            ('Lista de compras: arroz, pasta, aceite','Anotar y comprar víveres básicos',             'Nueva', '2025-04-17', 3, 4),
                                                                                            ('Completar laboratorio SO2',      'Ejercicios de concurrencia en Sistemas Operativos 2','Nueva', '2025-04-29', 8, 4),
                                                                                            ('Revisar código DS2',             'Code review del proyecto de grupo',                  'Nueva', '2025-05-03', 6, 4),
                                                                                            ('Leer artículos de Redes 1',      'Estudiar protocolos TCP/IP y OSI',                  'Nueva', '2025-04-26', 7, 4);

-- Usuario 5: Luis Martínez (id_usuario = 5)
INSERT INTO tarea (titulo, descripcion, estado, fecha_limite, categoria_id, usuario_id) VALUES
                                                                                            ('Barrer el patio',                'Barrer hojas y polvo del patio delantero',          'Nueva', '2025-04-18', 2, 5),
                                                                                            ('Lavar la ropa',                  'Separar colores y lavar en la lavadora',            'Nueva', '2025-04-19', 2, 5),
                                                                                            ('Comprar productos de limpieza',   'Detergente, limpiador multiusos y esponjas',        'Nueva', '2025-04-17', 3, 5),
                                                                                            ('Preparar entrega Historia',      'Redactar ensayo sobre la Revolución Industrial',     'Nueva', '2025-04-30', 9, 5),
                                                                                            ('Diseñar esquema BD2',            'Crear diagrama UML para la base de datos',          'Nueva', '2025-05-01', 4, 5),
                                                                                            ('Redactar informe Comunicación 1','Escribir conclusiones del proyecto de comunicación', 'Nueva', '2025-05-04', 5, 5);

