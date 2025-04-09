
/*
===========================================
  Proyecto SQL – Restricciones y Triggers
  ----------------------------------------
  Descripción:
  Este archivo contiene la implementación de restricciones de integridad y triggers
  aplicados sobre un conjunto de tablas relacionadas con imágenes médicas, pacientes
  y algoritmos de procesamiento. El objetivo es garantizar la consistencia de los datos 
  a través de validaciones específicas que no siempre pueden ser cubiertas 
  por restricciones tradicionales.

  Tecnologías utilizadas:
  - PostgreSQL
  - Lenguaje PL/pgSQL para funciones de triggers

  Contenido:
  */
  
-- 1) Esta restricción asegura que el campo `modalidad` de la tabla IMAGEN_MEDICA 
-- solo puede tomar uno de los valores listados. Es una restricción CHECK clásica 
-- que valida que se cumpla una condición específica antes de permitir la inserción o actualización.
-- Si se intenta insertar un valor distinto, la base de datos lo rechazará.

ALTER TABLE IMAGEN_MEDICA
ADD CONSTRAINT ck_modalidades
CHECK (modalidad IN ('RADIOLOGIA CONVENCIONAL', 'FLUOROSCOPIA', 'ESTUDIOS
RADIOGRAFICOS CON FLUOROSCOPIA', 'MAMOGRAFIA', 'SONOGRAFIA'));

--==========================================================================

-- 2) Este caso busca restringir que una misma imagen (identificada por paciente + imagen) 
-- no tenga más de 5 registros en la tabla PROCESAMIENTO. 
-- Como las restricciones CHECK no pueden incluir subconsultas en PostgreSQL, este enfoque 
-- no es funcional directamente. Por eso, se acompaña con un trigger que sí puede hacer esa verificación.

ALTER TABLE PROCESAMIENTO
ADD CONSTRAINT ck_max_procesamientos
CHECK (NOT EXISTS (
SELECT 1
FROM PROCESAMIENTO
GROUP BY id_paciente, id_imagen
HAVING COUNT(*) > 5));

-- TRIGGER asociado:
-- Esta función se dispara antes de insertar o actualizar una fila en PROCESAMIENTO.
-- Cuenta cuántos procesamientos tiene ya una imagen dada (por paciente e id de imagen).
-- Si el conteo ya es mayor a 4, se lanza una excepción impidiendo la operación.
-- De esta manera se implementa una restricción procedural que no es posible con un simple CHECK.

CREATE OR REPLACE FUNCTION FN_MAXIMO_PROCESAMIENTOS() RETURNS
Trigger AS $$
DECLARE
cant integer;
BEGIN
SELECT COUNT(*) INTO cant
FROM PROCESAMIENTO
WHERE id_imagen = NEW.id_imagen
AND id_paciente = NEW.id_paciente;
IF (cant > 4) THEN
RAISE EXCEPTION 'Superó la cantidad de procesamientos por imagen';
END IF;
RETURN NEW;
END $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_MAXIMO_PROCESAMIENTOS
BEFORE INSERT OR UPDATE OF id_imagen, id_paciente
ON PROCESAMIENTO
FOR EACH ROW
EXECUTE PROCEDURE FN_MAXIMO_PROCESAMIENTOS();




-- ========================================
-- 3) Validación de fechas entre imágenes y procesamientos
-- ========================================
-- Se agregan columnas de tipo fecha a las tablas IMAGEN_MEDICA y PROCESAMIENTO.
-- La columna "fecha_img" representa la fecha en que fue tomada la imagen médica.
-- La columna "fecha_proc" representa la fecha en que se realizó un procesamiento
-- sobre esa imagen.
--
-- Objetivo: Garantizar que la fecha del procesamiento (fecha_proc) nunca sea
-- anterior a la fecha en que fue tomada la imagen (fecha_img).

-- Agregado de columnas de fecha
ALTER TABLE IMAGEN_MEDICA
ADD COLUMN fecha_img date;

ALTER TABLE PROCESAMIENTO
ADD COLUMN fecha_proc date;

-- Restricción a nivel de base de datos (no siempre soportada por todos los motores)
-- A través de un ASSERTION se controla que ningún procesamiento tenga una fecha
-- anterior a la de la imagen asociada.
CREATE ASSERTION fecha_menor
CHECK (
  NOT EXISTS (
    SELECT 1
    FROM PROCESAMIENTO p
    JOIN IMAGEN_MEDICA im
      ON (p.id_paciente = im.id_paciente AND p.id_imagen = im.id_imagen)
    WHERE p.fecha_proc < im.fecha_img
  )
);

-- ========================================
-- Implementación mediante triggers
-- ========================================

-- Función FN_FECHAS_PROCESAMIENTO:
-- Antes de insertar o actualizar una fila en PROCESAMIENTO, se busca la fecha de la imagen
-- y se verifica que la nueva fecha de procesamiento no sea menor.
CREATE OR REPLACE FUNCTION FN_FECHAS_PROCESAMIENTO() RETURNS Trigger AS $$
DECLARE
  fechaImg IMAGEN_MEDICA.fecha_img%type;
BEGIN
  SELECT fecha_img INTO fechaImg
  FROM IMAGEN_MEDICA
  WHERE id_paciente = NEW.id_paciente
    AND id_imagen = NEW.id_imagen;

  IF (NEW.fecha_proc < fechaImg) THEN
    RAISE EXCEPTION 'La fecha de procesamiento no puede ser menor que la fecha de la imagen';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

-- Trigger asociado a la función anterior
CREATE TRIGGER TR_FECHAS_PROCESAMIENTO
BEFORE INSERT OR UPDATE OF fecha_proc, id_imagen, id_paciente
ON PROCESAMIENTO
FOR EACH ROW
EXECUTE PROCEDURE FN_FECHAS_PROCESAMIENTO();


-- Función FN_FECHAS_IMG_MEDICA:
-- Antes de modificar la fecha de una imagen, se controla que no haya registros de procesamiento
-- posteriores a la nueva fecha propuesta.
CREATE OR REPLACE FUNCTION FN_FECHAS_IMG_MEDICA() RETURNS Trigger AS $$
DECLARE
  fechaProc PROCESAMIENTO.fecha_proc%type;
BEGIN
  SELECT fecha_proc INTO fechaProc
  FROM PROCESAMIENTO
  WHERE id_paciente = NEW.id_paciente
    AND id_imagen = NEW.id_imagen;

  IF (fechaProc < NEW.fecha_img) THEN
    RAISE EXCEPTION 'La fecha de la imagen no puede ser posterior a la de procesamiento';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

-- Trigger asociado a la función anterior
CREATE TRIGGER TR_FECHAS_IMG_MEDICA
BEFORE UPDATE OF fecha_img
ON IMAGEN_MEDICA
FOR EACH ROW
EXECUTE PROCEDURE FN_FECHAS_IMG_MEDICA();




-- ========================================
-- 4) Restricción: Máximo de dos estudios de FLUOROSCOPIA por paciente por año
-- ========================================
-- Esta validación se encarga de garantizar que un mismo paciente no se realice más
-- de dos estudios de tipo "FLUOROSCOPIA" en un mismo año calendario.

-- En la tabla IMAGEN_MEDICA:
-- Se intenta implementar un CHECK con una subconsulta, pero esta sintaxis no
-- está permitida en la mayoría de los motores SQL (como PostgreSQL), ya que
-- las subconsultas no están permitidas dentro de CHECK constraints.

ALTER TABLE IMAGEN_MEDICA
ADD CONSTRAINT ck_max_fluoroscopia_anual
CHECK (
  NOT EXISTS (
    SELECT 1
    FROM IMAGEN_MEDICA
    WHERE modalidad LIKE 'FLUOROSCOPIA'
    GROUP BY id_paciente, EXTRACT(YEAR FROM fecha_img)
    HAVING COUNT(id_imagen) > 2
  )
);

-- ========================================
-- Implementación mediante trigger
-- ========================================

-- Función FN_MAXIMO_FLUOROSCOPIA_ANUAL:
-- Antes de insertar o actualizar un registro de tipo "FLUOROSCOPIA", se verifica
-- cuántas fluoroscopias ya tiene ese paciente en el mismo año.
-- Si ya tiene 2 o más, se lanza una excepción.

CREATE OR REPLACE FUNCTION FN_MAXIMO_FLUOROSCOPIA_ANUAL()
RETURNS Trigger AS $$
DECLARE
  cant integer;
BEGIN
  SELECT COUNT(*) INTO cant
  FROM IMAGEN_MEDICA
  WHERE id_paciente = NEW.id_paciente
    AND modalidad = 'FLUOROSCOPIA'
    AND EXTRACT(YEAR FROM fecha_img) = EXTRACT(YEAR FROM NEW.fecha_img);

  IF (cant > 1) THEN
    RAISE EXCEPTION 'El paciente ya tiene 2 fluoroscopias este año';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

-- Trigger TR_MAXIMO_FLUOROSCOPIA_ANUAL:
-- Se activa antes de insertar o actualizar una imagen médica de tipo FLUOROSCOPIA.
-- Evalúa si el paciente ya tiene 2 estudios registrados en ese año.
CREATE TRIGGER TR_MAXIMO_FLUOROSCOPIA_ANUAL
BEFORE INSERT OR UPDATE OF fecha_img, modalidad
ON IMAGEN_MEDICA
FOR EACH ROW
WHEN (NEW.modalidad LIKE 'FLUOROSCOPIA')
EXECUTE PROCEDURE FN_MAXIMO_FLUOROSCOPIA_ANUAL();




-- ========================================
-- 5) Restricción: No se pueden aplicar algoritmos de costo "O(n)" a imágenes de tipo FLUOROSCOPIA
-- ========================================
-- El objetivo de esta regla es evitar que algoritmos con complejidad computacional O(n)
-- sean aplicados sobre imágenes médicas de tipo "FLUOROSCOPIA", probablemente porque
-- su uso en ese contexto no es adecuado o permitido por cuestiones de rendimiento.

-- ========================================
-- Restricción declarativa mediante ASSERTION (no compatible en PostgreSQL)
-- ========================================
-- Esta cláusula intenta expresar la regla de negocio directamente como una restricción
-- a nivel de base de datos usando `CREATE ASSERTION`, que no es soportado en PostgreSQL.
-- Por eso, la implementación práctica de esta validación se realiza mediante triggers.

CREATE ASSERTION costo_computacional_fluoroscopia
CHECK (
  NOT EXISTS (
    SELECT 1
    FROM IMAGEN_MEDICA im
    JOIN PROCESAMIENTO p ON (im.id_imagen = p.id_imagen AND im.id_paciente = p.id_paciente)
    JOIN ALGORITMO a ON (p.id_algoritmo = a.id_algoritmo)
    WHERE im.modalidad LIKE 'FLUOROSCOPIA'
    AND a.costo_computacional LIKE 'O(n)'
  )
);

-- ========================================
-- Implementaciones con triggers
-- ========================================

-- 1) Trigger en la tabla PROCESAMIENTO
-- Verifica que no se esté registrando un algoritmo con costo O(n) sobre una imagen
-- que sea de tipo FLUOROSCOPIA.

CREATE OR REPLACE FUNCTION FN_ALGORITMO_FLUOROSCOPIA_PROC()
RETURNS Trigger AS $$
DECLARE
  modalidad IMAGEN_MEDICA.modalidad%type;
  costo ALGORITMO.costo_computacional%type;
BEGIN
  SELECT im.modalidad INTO modalidad
  FROM IMAGEN_MEDICA im
  WHERE im.id_imagen = NEW.id_imagen AND im.id_paciente = NEW.id_paciente;

  SELECT a.costo_computacional INTO costo
  FROM ALGORITMO a
  WHERE a.id_algoritmo = NEW.id_algoritmo;

  IF (modalidad LIKE 'FLUOROSCOPIA' AND costo LIKE 'O(n)') THEN
    RAISE EXCEPTION 'No puede tener costo O(n) en FLUOROSCOPIA';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_ALGORITMO_FLUOROSCOPIA_PROC
BEFORE INSERT OR UPDATE OF id_imagen, id_paciente, id_algoritmo
ON PROCESAMIENTO
FOR EACH ROW
EXECUTE PROCEDURE FN_ALGORITMO_FLUOROSCOPIA_PROC();

-- 2) Trigger en la tabla ALGORITMO
-- Se activa cuando se intenta actualizar el costo computacional de un algoritmo
-- que ya está asociado a una imagen de tipo FLUOROSCOPIA.

CREATE OR REPLACE FUNCTION FN_ALGORITMO_FLUOROSCOPIA_ALG()
RETURNS Trigger AS $$
DECLARE
  modalidad IMAGEN_MEDICA.modalidad%type;
BEGIN
  SELECT im.modalidad INTO modalidad
  FROM PROCESAMIENTO p
  JOIN IMAGEN_MEDICA im ON (p.id_imagen = im.id_imagen)
  WHERE p.id_algoritmo = NEW.id_algoritmo;

  IF (modalidad LIKE 'FLUOROSCOPIA') THEN
    RAISE EXCEPTION 'No puede tener costo O(n) en FLUOROSCOPIA';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_ALGORITMO_FLUOROSCOPIA_ALG
BEFORE UPDATE OF costo_computacional
ON ALGORITMO
FOR EACH ROW
WHEN (NEW.costo_computacional LIKE 'O(n)')
EXECUTE PROCEDURE FN_ALGORITMO_FLUOROSCOPIA_ALG();

-- 3) Trigger en la tabla IMAGEN_MEDICA
-- Se activa si se intenta cambiar la modalidad de una imagen ya procesada a FLUOROSCOPIA
-- y esa imagen tiene un algoritmo con costo O(n) asociado.

CREATE OR REPLACE FUNCTION FN_ALGORITMO_FLUOROSCOPIA_IMG()
RETURNS Trigger AS $$
DECLARE
  costo ALGORITMO.costo_computacional%type;
BEGIN
  SELECT a.costo_computacional INTO costo
  FROM PROCESAMIENTO p
  JOIN ALGORITMO a ON (p.id_algoritmo = a.id_algoritmo)
  WHERE p.id_imagen = NEW.id_imagen;

  IF (costo LIKE 'O(n)') THEN
    RAISE EXCEPTION 'No puede tener costo O(n) en FLUOROSCOPIA';
  END IF;

  RETURN NEW;
END $$ LANGUAGE 'plpgsql';

CREATE TRIGGER TR_ALGORITMO_FLUOROSCOPIA_IMG
BEFORE UPDATE OF modalidad
ON IMAGEN_MEDICA
FOR EACH ROW
WHEN (NEW.modalidad LIKE 'FLUOROSCOPIA')
EXECUTE PROCEDURE FN_ALGORITMO_FLUOROSCOPIA_IMG();

--=========================================================