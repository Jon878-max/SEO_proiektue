-- invitados datu-basea sortu
CREATE DATABASE IF NOT EXISTS invitados;

-- invitados datu-basea erabili
USE invitados;

-- clientes taula sortu, telefono-zenbakiaren bakarkotasuna bermatuz
DROP TABLE IF EXISTS clientes;
CREATE TABLE IF NOT EXISTS clientes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255) NOT NULL,
    telefono VARCHAR(15) NOT NULL UNIQUE
);
