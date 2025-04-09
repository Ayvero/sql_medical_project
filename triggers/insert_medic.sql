
-- Inserts para la tabla ALGORITMO
INSERT INTO ALGORITMO (id_algoritmo, nombre_metadata, descripcion, costo_computacional) VALUES
(1, 'MetaX', 'Algoritmo de segmentación de tejidos', 'Alto'),
(2, 'BioScan', 'Análisis automático de tumores', 'Medio'),
(3, 'FastRec', 'Reconstrucción rápida de imágenes', 'Bajo');

-- Inserts para la tabla PACIENTE
INSERT INTO PACIENTE (id_paciente, apellido, nombre, domicilio, fecha_nacimiento) VALUES
(101, 'Gómez', 'Laura', 'Av. Siempreviva 742', '1985-07-12'),
(102, 'Pérez', 'Carlos', 'Calle Falsa 123', '1990-03-20'),
(103, 'López', 'Mariana', 'Mitre 456', '1978-11-02');

-- Inserts para la tabla IMAGEN_MEDICA
INSERT INTO IMAGEN_MEDICA (id_paciente, id_imagen, modalidad, descripcion, descripcion_breve) VALUES
(101, 1, 'MRI', 'Resonancia magnética de cráneo', 'Craneo MRI'),
(101, 2, 'CT', 'Tomografía de tórax', 'Tórax CT'),
(102, 1, 'X-ray', 'Radiografía de brazo', 'Brazo X-ray'),
(103, 1, 'Ultrasound', 'Ecografía abdominal', 'Eco abdomen');

-- Inserts para la tabla PROCESAMIENTO
INSERT INTO PROCESAMIENTO (id_algoritmo, id_paciente, id_imagen, nro_secuencia, parametro) VALUES
(1, 101, 1, 1, 0.345),
(2, 101, 1, 2, 0.567),
(3, 101, 2, 1, 0.123),
(1, 102, 1, 1, 0.789),
(2, 103, 1, 1, 0.456);
