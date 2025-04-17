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

