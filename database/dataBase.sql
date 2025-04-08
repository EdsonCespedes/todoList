-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS todo_list;
-- DROP DATABASE todo_list;
USE todo_list;

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS todo_list
    CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE todo_list;

-- Tabla de categorías: clasifica las tareas.
CREATE TABLE categorias (
  id_categoria INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_categoria)
);

-- Tabla de usuario: para la autenticación y gestión de usuarios.
CREATE TABLE usuario (
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
CREATE TABLE tarea (
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
CREATE TABLE etiqueta (
  id_etiqueta INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  creada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  actualizada_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_etiqueta)
);

-- Tabla intermedia tarea_etiqueta: representa la relación muchos a muchos entre tareas y etiquetas.
CREATE TABLE tarea_etiqueta (
  tarea_id INT NOT NULL,
  etiqueta_id INT NOT NULL,
  PRIMARY KEY (tarea_id, etiqueta_id),
  CONSTRAINT fk_tarea_etiqueta_tarea FOREIGN KEY (tarea_id) REFERENCES tarea(id_tarea),
  CONSTRAINT fk_tarea_etiqueta_etiqueta FOREIGN KEY (etiqueta_id) REFERENCES etiqueta(id_etiqueta)
);