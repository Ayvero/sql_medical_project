# 📚 Proyecto SQL - Sistema de Imágenes Médicas

Este proyecto académico simula un sistema de gestión de imágenes médicas, incluyendo pacientes, imágenes, algoritmos de procesamiento y reglas de validación implementadas mediante restricciones SQL y triggers en PostgreSQL.

---

## 🛠️ Tecnologías utilizadas

- PostgreSQL
- PL/pgSQL
- DataGrip (para conexión y pruebas locales)
- SQL estándar

---

## 🗃️ Estructura del proyecto

- `create_tables.sql` → Crea las tablas principales del sistema.
- `insert_data.sql` → Inserta datos representativos para probar las restricciones y triggers.
- `triggers.sql` → Incluye funciones y triggers para validar la lógica del negocio.

---

## 📄 Archivos incluidos

- `create_tables.sql`
- `insert_data.sql`
- `triggers.sql`
- `README.md`

---

## 📌 Restricciones implementadas

1. Modalidades permitidas para las imágenes médicas.
2. Máximo de 5 procesamientos por imagen.
3. La fecha de procesamiento no puede ser anterior a la fecha de la imagen.
4. Máximo de 2 estudios de tipo FLUOROSCOPIA por paciente y por año.
5. No se pueden aplicar algoritmos con complejidad O(n) a imágenes de tipo FLUOROSCOPIA.

---

## 🚀 Cómo probar el proyecto

1. Instalar PostgreSQL.
2. Crear una base de datos y conectarse con una herramienta como DataGrip o pgAdmin.
3. Ejecutar `create_tables.sql` y luego `insert_data.sql`.
4. Ejecutar `triggers.sql`.
5. Probar inserciones o actualizaciones para validar que las restricciones funcionen correctamente.

---

## 🧪 Consultas y triggers destacados

El proyecto incluye validaciones tanto a nivel de base de datos como programáticas (PL/pgSQL), para asegurar la integridad de los datos médicos y prevenir situaciones no deseadas en el procesamiento de imágenes.

-------------------------------------------

# 📚 SQL Project - Medical Imaging System

This academic project simulates a management system for medical images, including patients, images, processing algorithms, and validation rules using SQL constraints and PostgreSQL triggers.

---

## 🛠️ Technologies used

- PostgreSQL
- PL/pgSQL
- DataGrip (for local connection and testing)
- Standard SQL

---

## 🗃️ Project structure

- `create_tables.sql` → Creates the main tables of the system.
- `insert_data.sql` → Inserts representative data to test constraints and triggers.
- `triggers.sql` → Includes trigger functions and business logic validations.

---

## 📄 Included files

- `create_tables.sql`
- `insert_data.sql`
- `triggers.sql`
- `README.md`

---

## 📌 Implemented constraints

1. Allowed modalities for medical images.
2. Maximum of 5 processings per image.
3. Processing date cannot be earlier than the image date.
4. Maximum of 2 FLUOROSCOPIA studies per patient per year.
5. Algorithms with complexity O(n) cannot be applied to FLUOROSCOPIA images.

---


## 🧪 Highlights

The project includes validations at both database and procedural levels (PL/pgSQL), ensuring medical data integrity and preventing undesired scenarios during image processing.
