
-- tables
-- Table: ALGORITMO
CREATE TABLE ALGORITMO (
    id_algoritmo int  NOT NULL,
    nombre_metadata varchar(40)  NOT NULL,
    descripcion varchar(256)  NOT NULL,
    costo_computacional varchar(15)  NOT NULL,
    CONSTRAINT PK_ALGORITMO PRIMARY KEY (id_algoritmo)
);

-- Table: IMAGEN_MEDICA
CREATE TABLE IMAGEN_MEDICA (
    id_paciente int  NOT NULL,
    id_imagen int  NOT NULL,
    modalidad varchar(80)  NOT NULL,
    descripcion varchar(180)  NOT NULL,
    descripcion_breve varchar(80)  NULL,
    CONSTRAINT PK_IMAGEN_MEDICA PRIMARY KEY (id_paciente,id_imagen)
);

-- Table: PACIENTE
CREATE TABLE PACIENTE (
    id_paciente int  NOT NULL,
    apellido varchar(80)  NOT NULL,
    nombre varchar(80)  NOT NULL,
    domicilio varchar(120)  NOT NULL,
    fecha_nacimiento date  NOT NULL,
    CONSTRAINT PK_PACIENTE PRIMARY KEY (id_paciente)
);

-- Table: PROCESAMIENTO
CREATE TABLE PROCESAMIENTO (
    id_algoritmo int  NOT NULL,
    id_paciente int  NOT NULL,
    id_imagen int  NOT NULL,
    nro_secuencia int  NOT NULL,
    parametro decimal(15,3)  NOT NULL,
    CONSTRAINT PK_PROCESAMIENTO PRIMARY KEY (id_algoritmo,id_paciente,id_imagen,nro_secuencia)
);

-- foreign keys
-- Reference: FK_IMAGEN_MEDICA_PACIENTE (table: IMAGEN_MEDICA)
ALTER TABLE IMAGEN_MEDICA ADD CONSTRAINT FK_IMAGEN_MEDICA_PACIENTE
    FOREIGN KEY (id_paciente)
    REFERENCES PACIENTE (id_paciente)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_PROCESAMIENTO_ALGORITMO (table: PROCESAMIENTO)
ALTER TABLE PROCESAMIENTO ADD CONSTRAINT FK_PROCESAMIENTO_ALGORITMO
    FOREIGN KEY (id_algoritmo)
    REFERENCES ALGORITMO (id_algoritmo)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;

-- Reference: FK_PROCESAMIENTO_IMAGEN_MEDICA (table: PROCESAMIENTO)
ALTER TABLE PROCESAMIENTO ADD CONSTRAINT FK_PROCESAMIENTO_IMAGEN_MEDICA
    FOREIGN KEY (id_paciente, id_imagen)
    REFERENCES IMAGEN_MEDICA (id_paciente, id_imagen)  
    NOT DEFERRABLE 
    INITIALLY IMMEDIATE
;
