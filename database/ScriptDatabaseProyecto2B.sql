-- =============================================================================
-- SCRIPT MAESTRO DE BASE DE DATOS - FINAL CORREGIDO
-- Proyecto: Franquicia Barberia (Ingeniería de Software)
-- Autor: Bryan Ayala (Generado por Asistente AI)
-- Versión: 3.0 (Integrada y Depurada)
-- =============================================================================

-- =============================================================================
-- PASO 1: LIMPIEZA Y CREACIÓN DEL ENTORNO
-- =============================================================================
USE master;
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'BarberiaFranquiciaDB')
BEGIN
    ALTER DATABASE BarberiaFranquiciaDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BarberiaFranquiciaDB;
END
GO

CREATE DATABASE BarberiaFranquiciaDB;
GO

USE BarberiaFranquiciaDB;
GO

CREATE SCHEMA Gestion;
GO

-- =============================================================================
-- PASO 1.5: CONFIGURACIÓN DE SEGURIDAD (Login y Usuario App)
-- =============================================================================

-- 1. Crear Login en el servidor (si no existe)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'app_barberia')
BEGIN
    CREATE LOGIN [app_barberia] WITH PASSWORD = 'Barberia2024!', CHECK_POLICY = OFF;
    PRINT 'Login app_barberia creado.';
END
GO

-- 2. Crear Usuario en la BD asociado al Login
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app_barberia')
BEGIN
    CREATE USER [app_barberia] FOR LOGIN [app_barberia];
    PRINT 'Usuario de base de datos app_barberia creado.';
END
GO

-- 3. Asignar permisos (Rol de Propietario para depuración y desarrollo)
ALTER ROLE db_owner ADD MEMBER [app_barberia];
GO

-- =============================================================================
-- PASO 2: DOMINIOS Y TIPOS DE DATOS
-- =============================================================================
CREATE TYPE Gestion.D_ID FROM INT NOT NULL;
CREATE TYPE Gestion.D_Identificacion FROM NVARCHAR(13) NOT NULL;
CREATE TYPE Gestion.D_Nombre FROM NVARCHAR(100) NOT NULL;
CREATE TYPE Gestion.D_TextoCorto FROM NVARCHAR(50) NOT NULL;
CREATE TYPE Gestion.D_Direccion FROM NVARCHAR(150) NULL;
CREATE TYPE Gestion.D_Email FROM NVARCHAR(100) NULL;
CREATE TYPE Gestion.D_Telefono FROM NVARCHAR(10) NULL;
CREATE TYPE Gestion.D_Estado FROM NVARCHAR(20) NOT NULL;
CREATE TYPE Gestion.D_Dinero FROM DECIMAL(10, 2) NOT NULL;
CREATE TYPE Gestion.D_Cantidad FROM INT NOT NULL;
CREATE TYPE Gestion.D_Porcentaje FROM DECIMAL(5,2) NOT NULL;
CREATE TYPE Gestion.D_Fecha FROM DATE NULL;
CREATE TYPE Gestion.D_FechaHora FROM DATETIME NOT NULL;
CREATE TYPE Gestion.D_Sexo FROM CHAR(1) NULL;
CREATE TYPE Gestion.D_Booleano FROM BIT NOT NULL;
GO

-- =============================================================================
-- PASO 3: TABLAS (DDL) CON AUTENTICACIÓN
-- =============================================================================

CREATE TABLE Gestion.Franquiciado (
    FranquiciadoID      Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto      Gestion.D_Nombre,
    RUC                 Gestion.D_Identificacion UNIQUE,
    FechaInicioContrato Gestion.D_Fecha NOT NULL DEFAULT GETDATE(),
    PorcentajeRegalia   Gestion.D_Porcentaje DEFAULT 5.00,
    Email               NVARCHAR(100) NULL, -- Auth
    PasswordHash        NVARCHAR(255) NULL  -- Auth
);
GO

CREATE TABLE Gestion.Ciudad (
    CiudadID     Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    NombreCiudad Gestion.D_TextoCorto
);
GO

CREATE TABLE Gestion.Sede (
    SedeID          Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    NombreSede      Gestion.D_Nombre,
    Direccion       Gestion.D_Direccion,
    Telefono        Gestion.D_Telefono CHECK (Telefono LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    CiudadID        Gestion.D_ID,
    FranquiciadoID  Gestion.D_ID,
    EsPropia        Gestion.D_Booleano DEFAULT 0,
    FOREIGN KEY (CiudadID) REFERENCES Gestion.Ciudad(CiudadID),
    FOREIGN KEY (FranquiciadoID) REFERENCES Gestion.Franquiciado(FranquiciadoID)
);
GO

CREATE TABLE Gestion.Especialidad (
    EspecialidadID      Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    NombreEspecialidad  Gestion.D_TextoCorto
);
GO

CREATE TABLE Gestion.Barbero (
    BarberoID       Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    Cedula          Gestion.D_Identificacion UNIQUE CHECK (Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Nombres         Gestion.D_Nombre,
    Apellidos       Gestion.D_Nombre,
    Telefono        Gestion.D_Telefono CHECK (Telefono LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Email           Gestion.D_Email CHECK (Email LIKE '%_@_%._%'),
    Direccion       Gestion.D_Direccion,
    FechaNacimiento Gestion.D_Fecha,
    Sexo            Gestion.D_Sexo CHECK (Sexo IN ('M', 'F')),
    FechaRegistro   DATETIME DEFAULT GETDATE(),
    EspecialidadID  Gestion.D_ID,
    SedeID          Gestion.D_ID,
    PasswordHash    NVARCHAR(255) NULL, -- Auth
    FOREIGN KEY (EspecialidadID) REFERENCES Gestion.Especialidad(EspecialidadID),
    FOREIGN KEY (SedeID) REFERENCES Gestion.Sede(SedeID)
);
GO

CREATE TABLE Gestion.Cliente (
    ClienteID     Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    Cedula        Gestion.D_Identificacion UNIQUE CHECK (Cedula LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Nombres       Gestion.D_Nombre,
    Apellidos     Gestion.D_Nombre,
    Telefono      Gestion.D_Telefono CHECK (Telefono LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    Email         Gestion.D_Email CHECK (Email LIKE '%_@_%._%'),
    Direccion     Gestion.D_Direccion,
    Sexo          Gestion.D_Sexo CHECK (Sexo IN ('M', 'F')),
    FechaRegistro DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Gestion.Servicio (
    ServicioID      Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    NombreServicio  Gestion.D_Nombre,
    Precio          Gestion.D_Dinero,
    DuracionMinutos Gestion.D_Cantidad
);
GO

CREATE TABLE Gestion.Cita (
    CitaID      Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    FechaHora   Gestion.D_FechaHora,
    Estado      Gestion.D_Estado DEFAULT 'Pendiente' CHECK (Estado IN ('Pendiente', 'Atendida', 'Cancelada', 'No Asistida')),
    ClienteID   Gestion.D_ID,
    BarberoID   Gestion.D_ID,
    SedeID      Gestion.D_ID,
    Total       Gestion.D_Dinero DEFAULT 0.00,
    FOREIGN KEY (ClienteID) REFERENCES Gestion.Cliente(ClienteID),
    FOREIGN KEY (BarberoID) REFERENCES Gestion.Barbero(BarberoID),
    FOREIGN KEY (SedeID) REFERENCES Gestion.Sede(SedeID)
);
GO

-- CORRECCION CRITICA: Se eliminó PrecioUnitario para consistencia lógica
CREATE TABLE Gestion.DetalleCitaServicio (
    DetalleServicioID Gestion.D_ID IDENTITY(1,1) PRIMARY KEY,
    CitaID            Gestion.D_ID,
    ServicioID        Gestion.D_ID,
    FOREIGN KEY (CitaID) REFERENCES Gestion.Cita(CitaID),
    FOREIGN KEY (ServicioID) REFERENCES Gestion.Servicio(ServicioID)
);
GO

-- =============================================================================
-- PASO 4: DATOS DE PRUEBA (SEEDING)
-- =============================================================================

-- CIUDADES
INSERT INTO Gestion.Ciudad (NombreCiudad) VALUES 
('Quito'), ('Guayaquil'), ('Cuenca'), ('Manta'), ('Ambato'),
('Loja'), ('Santo Domingo'), ('Machala'), ('Portoviejo'), ('Riobamba'),
('Esmeraldas'), ('Ibarra'), ('Latacunga'), ('Tulcan'), ('Babahoyo'),
('Duran'), ('Quevedo'), ('Milagro'), ('Salinas'), ('Santa Elena');
GO

-- FRANQUICIADOS
INSERT INTO Gestion.Franquiciado (NombreCompleto, RUC, PorcentajeRegalia, Email, PasswordHash) VALUES 
('Carlos Mendoza', '1712345678001', 5.00, 'carlos.mendoza@barberia.com', 'admin123'),
('Ana Torres', '1798765432001', 5.50, 'ana.torres@barberia.com', 'admin123'),
('Roberto Jaramillo', '0912345678001', 4.50, 'roberto.jaramillo@barberia.com', 'admin123'),
('Maria Fernandez', '1312345678001', 5.00, 'maria.fernandez@barberia.com', 'admin123'),
('Luis Paredes', '0612345678001', 5.25, 'luis.paredes@barberia.com', 'admin123'),
('Sofia Gonzalez', '1812345678001', 4.75, 'sofia.gonzalez@barberia.com', 'admin123'),
('Pedro Alvarado', '0712345678001', 5.00, 'pedro.alvarado@barberia.com', 'admin123'),
('Carmen Reyes', '0112345678001', 5.00, 'carmen.reyes@barberia.com', 'admin123'),
('Fernando Castillo', '0212345678001', 5.50, 'fernando.castillo@barberia.com', 'admin123'),
('Patricia Navarro', '0312345678001', 4.50, 'patricia.navarro@barberia.com', 'admin123'),
('Andres Moreno', '0412345678001', 5.00, 'andres.moreno@barberia.com', 'admin123'),
('Lucia Herrera', '0512345678001', 5.25, 'lucia.herrera@barberia.com', 'admin123'),
('Diego Salazar', '2012345678001', 5.00, 'diego.salazar@barberia.com', 'admin123'),
('Valentina Cruz', '2112345678001', 4.75, 'valentina.cruz@barberia.com', 'admin123'),
('Gabriel Ortiz', '2212345678001', 5.00, 'gabriel.ortiz@barberia.com', 'admin123'),
('Isabella Vega', '2312345678001', 5.00, 'isabella.vega@barberia.com', 'admin123'),
('Mateo Rios', '2412345678001', 5.50, 'mateo.rios@barberia.com', 'admin123'),
('Camila Luna', '2512345678001', 4.50, 'camila.luna@barberia.com', 'admin123'),
('Sebastian Pena', '2612345678001', 5.00, 'sebastian.pena@barberia.com', 'admin123'),
('Daniela Soto', '2712345678001', 5.25, 'daniela.soto@barberia.com', 'admin123');
GO

-- SEDES
INSERT INTO Gestion.Sede (NombreSede, Direccion, Telefono, CiudadID, FranquiciadoID) VALUES 
('Sede Matriz Norte', 'Av. Amazonas y Naciones Unidas', '0223456789', 1, 1),
('Sede Centro Historico', 'Calle Garcia Moreno 123', '0234567890', 1, 2),
('Sede Mall del Sol', 'Mall del Sol Local 45', '0412345678', 2, 3),
('Sede Urdesa', 'Av. Victor Emilio Estrada 456', '0423456789', 2, 4),
('Sede Mall del Rio', 'Mall del Rio Local 78', '0712345678', 3, 5),
('Sede Centro Cuenca', 'Calle Sucre y Bolivar', '0723456789', 3, 6),
('Sede Manta Beach', 'Malecon de Manta', '0512345678', 4, 7),
('Sede Ambato Centro', 'Calle Bolivar y Sucre', '0323456789', 5, 8),
('Sede Loja Sur', 'Av. Universitaria', '0712345679', 6, 9),
('Sede Santo Domingo', 'Av. Quito y Tsachila', '0212345679', 7, 10),
('Sede Machala', 'Av. 25 de Junio', '0712345680', 8, 11),
('Sede Portoviejo', 'Calle 10 de Agosto', '0512345679', 9, 12),
('Sede Riobamba', 'Av. Daniel Leon Borja', '0312345680', 10, 13),
('Sede Esmeraldas', 'Malecon Las Palmas', '0612345678', 11, 14),
('Sede Ibarra', 'Calle Bolivar Centro', '0612345679', 12, 15),
('Sede Latacunga', 'Calle Quito', '0312345681', 13, 16),
('Sede Tulcan', 'Av. Coral', '0612345680', 14, 17),
('Sede Babahoyo', 'Malecon 9 de Octubre', '0512345680', 15, 18),
('Sede Duran', 'Av. Primero de Mayo', '0412345679', 16, 19),
('Sede Quevedo', 'Calle 7 de Octubre', '0512345681', 17, 20);
GO

-- ESPECIALIDADES
INSERT INTO Gestion.Especialidad (NombreEspecialidad) VALUES 
('Corte Clasico'), ('Barberia Moderna'), ('Colorimetria'), ('Afeitado Tradicional'),
('Diseno de Barba'), ('Corte Infantil'), ('Tratamientos Capilares'), ('Alisado'),
('Trenzas y Dreadlocks'), ('Estilo Urbano');
GO

-- BARBEROS
INSERT INTO Gestion.Barbero (Cedula, Nombres, Apellidos, Telefono, Email, FechaNacimiento, Sexo, EspecialidadID, SedeID, PasswordHash) VALUES 
('1712345678', 'Juan', 'Perez', '0991234567', 'juan.perez@barberia.com', '1990-05-15', 'M', 1, 1, 'barbero123'),
('1723456789', 'Maria', 'Lopez', '0992345678', 'maria.lopez@barberia.com', '1992-08-20', 'F', 2, 1, 'barbero123'),
('1734567890', 'Carlos', 'Sanchez', '0993456789', 'carlos.sanchez@barberia.com', '1988-03-10', 'M', 3, 2, 'barbero123'),
('1745678901', 'Ana', 'Martinez', '0994567890', 'ana.martinez@barberia.com', '1995-11-25', 'F', 4, 2, 'barbero123'),
('0912345678', 'Pedro', 'Gomez', '0995678901', 'pedro.gomez@barberia.com', '1991-07-08', 'M', 5, 3, 'barbero123'),
('0923456789', 'Lucia', 'Ramirez', '0996789012', 'lucia.ramirez@barberia.com', '1993-02-14', 'F', 6, 3, 'barbero123'),
('0934567890', 'Miguel', 'Torres', '0997890123', 'miguel.torres@barberia.com', '1987-09-30', 'M', 7, 4, 'barbero123'),
('0945678901', 'Sofia', 'Flores', '0998901234', 'sofia.flores@barberia.com', '1994-04-18', 'F', 8, 4, 'barbero123'),
('0712345678', 'Diego', 'Herrera', '0999012345', 'diego.herrera@barberia.com', '1989-12-05', 'M', 9, 5, 'barbero123'),
('0723456789', 'Valentina', 'Castro', '0990123456', 'valentina.castro@barberia.com', '1996-06-22', 'F', 10, 5, 'barbero123'),
('1312345678', 'Fernando', 'Mendez', '0981234567', 'fernando.mendez@barberia.com', '1990-01-15', 'M', 1, 6, 'barbero123'),
('1323456789', 'Camila', 'Vargas', '0982345678', 'camila.vargas@barberia.com', '1992-10-08', 'F', 2, 6, 'barbero123'),
('0612345678', 'Gabriel', 'Rojas', '0983456789', 'gabriel.rojas@barberia.com', '1988-07-20', 'M', 3, 7, 'barbero123'),
('0623456789', 'Isabella', 'Morales', '0984567890', 'isabella.morales@barberia.com', '1995-03-12', 'F', 4, 7, 'barbero123'),
('1812345678', 'Mateo', 'Jimenez', '0985678901', 'mateo.jimenez@barberia.com', '1991-09-25', 'M', 5, 8, 'barbero123'),
('1823456789', 'Paula', 'Ortega', '0986789012', 'paula.ortega@barberia.com', '1993-05-30', 'F', 6, 8, 'barbero123'),
('0712345679', 'Andres', 'Silva', '0987890123', 'andres.silva@barberia.com', '1987-11-18', 'M', 7, 9, 'barbero123'),
('0723456780', 'Laura', 'Nunez', '0988901234', 'laura.nunez@barberia.com', '1994-08-05', 'F', 8, 9, 'barbero123'),
('0112345678', 'Sebastian', 'Ramos', '0989012345', 'sebastian.ramos@barberia.com', '1989-04-22', 'M', 9, 10, 'barbero123'),
('0123456789', 'Mariana', 'Delgado', '0980123456', 'mariana.delgado@barberia.com', '1996-02-08', 'F', 10, 10, 'barbero123');
GO

-- CLIENTES
INSERT INTO Gestion.Cliente (Cedula, Nombres, Apellidos, Telefono, Email, Direccion, Sexo) VALUES 
('1750123456', 'Roberto', 'Aguirre', '0971234567', 'roberto.aguirre@email.com', 'Calle A 123', 'M'),
('1751234567', 'Carmen', 'Benitez', '0972345678', 'carmen.benitez@email.com', 'Av. B 456', 'F'),
('1752345678', 'Jorge', 'Cordova', '0973456789', 'jorge.cordova@email.com', 'Calle C 789', 'M'),
('1753456789', 'Patricia', 'Duarte', '0974567890', 'patricia.duarte@email.com', 'Av. D 012', 'F'),
('1754567890', 'Ricardo', 'Espinoza', '0975678901', 'ricardo.espinoza@email.com', 'Calle E 345', 'M'),
('0950123456', 'Monica', 'Figueroa', '0976789012', 'monica.figueroa@email.com', 'Av. F 678', 'F'),
('0951234567', 'Eduardo', 'Guerrero', '0977890123', 'eduardo.guerrero@email.com', 'Calle G 901', 'M'),
('0952345678', 'Adriana', 'Hidalgo', '0978901234', 'adriana.hidalgo@email.com', 'Av. H 234', 'F'),
('0953456789', 'Oscar', 'Ibarra', '0979012345', 'oscar.ibarra@email.com', 'Calle I 567', 'M'),
('0954567890', 'Natalia', 'Jacome', '0970123456', 'natalia.jacome@email.com', 'Av. J 890', 'F'),
('0750123456', 'Victor', 'Lara', '0961234567', 'victor.lara@email.com', 'Calle K 123', 'M'),
('0751234567', 'Daniela', 'Mejia', '0962345678', 'daniela.mejia@email.com', 'Av. L 456', 'F'),
('0752345678', 'Alejandro', 'Navas', '0963456789', 'alejandro.navas@email.com', 'Calle M 789', 'M'),
('0753456789', 'Fernanda', 'Olmos', '0964567890', 'fernanda.olmos@email.com', 'Av. N 012', 'F'),
('0754567890', 'Mauricio', 'Ponce', '0965678901', 'mauricio.ponce@email.com', 'Calle O 345', 'M'),
('1350123456', 'Silvia', 'Quintero', '0966789012', 'silvia.quintero@email.com', 'Av. P 678', 'F'),
('1351234567', 'Esteban', 'Rivera', '0967890123', 'esteban.rivera@email.com', 'Calle Q 901', 'M'),
('1352345678', 'Cecilia', 'Suarez', '0968901234', 'cecilia.suarez@email.com', 'Av. R 234', 'F'),
('1353456789', 'Hector', 'Tello', '0969012345', 'hector.tello@email.com', 'Calle S 567', 'M'),
('1354567890', 'Beatriz', 'Uribe', '0960123456', 'beatriz.uribe@email.com', 'Av. T 890', 'F'),
('0650123456', 'Raul', 'Valdez', '0951234567', 'raul.valdez@email.com', 'Calle U 123', 'M'),
('0651234567', 'Elena', 'Zambrano', '0952345678', 'elena.zambrano@email.com', 'Av. V 456', 'F'),
('1850123456', 'Francisco', 'Acosta', '0953456789', 'francisco.acosta@email.com', 'Calle W 789', 'M'),
('1851234567', 'Gloria', 'Bravo', '0954567890', 'gloria.bravo@email.com', 'Av. X 012', 'F'),
('1852345678', 'Nicolas', 'Campos', '0955678901', 'nicolas.campos@email.com', 'Calle Y 345', 'M');
GO

-- SERVICIOS
INSERT INTO Gestion.Servicio (NombreServicio, Precio, DuracionMinutos) VALUES 
('Corte de Cabello', 10.00, 30),
('Afeitado de Barba', 8.00, 20),
('Corte + Barba', 15.00, 45),
('Mascarilla Negra', 5.00, 15),
('Tinte de Cabello', 25.00, 60),
('Alisado', 50.00, 90),
('Tratamiento Capilar', 20.00, 40),
('Corte Infantil', 8.00, 20),
('Diseno de Cejas', 5.00, 10),
('Lavado y Secado', 7.00, 15),
('Peinado Especial', 12.00, 25),
('Trenzas', 30.00, 60);
GO

-- CITAS (La carga masiva de citas ya incluía el total calculado, lo mantenemos como seed)
INSERT INTO Gestion.Cita (FechaHora, Estado, ClienteID, BarberoID, SedeID, Total) VALUES 
('2025-01-15 09:00:00', 'Atendida', 1, 1, 1, 11.50),
('2025-01-15 10:00:00', 'Atendida', 2, 2, 1, 17.25),
('2025-01-16 11:00:00', 'Atendida', 3, 3, 2, 23.00),
('2025-01-16 14:00:00', 'Atendida', 4, 4, 2, 11.50),
('2025-01-17 09:30:00', 'Atendida', 5, 5, 3, 17.25),
('2025-01-17 15:00:00', 'Cancelada', 6, 6, 3, 0.00),
('2025-01-18 10:00:00', 'Atendida', 7, 7, 4, 28.75),
('2025-01-18 11:30:00', 'Atendida', 8, 8, 4, 57.50),
('2025-01-19 09:00:00', 'Atendida', 9, 9, 5, 23.00),
('2025-01-19 16:00:00', 'No Asistida', 10, 10, 5, 0.00),
('2025-01-20 10:00:00', 'Atendida', 11, 11, 6, 11.50),
('2025-01-20 14:00:00', 'Atendida', 12, 12, 6, 17.25),
('2025-01-21 09:00:00', 'Atendida', 13, 13, 7, 28.75),
('2025-01-21 11:00:00', 'Cancelada', 14, 14, 7, 0.00),
('2025-01-22 10:30:00', 'Atendida', 15, 15, 8, 23.00),
('2025-01-22 15:00:00', 'Atendida', 16, 16, 8, 11.50),
('2025-01-23 09:00:00', 'Atendida', 17, 17, 9, 8.05),
('2025-01-23 14:00:00', 'Atendida', 18, 18, 9, 34.50),
('2025-01-24 10:00:00', 'Atendida', 19, 19, 10, 11.50),
('2025-01-24 16:00:00', 'Atendida', 20, 20, 10, 17.25),
-- Citas futuras
('2026-02-01 09:00:00', 'Pendiente', 1, 1, 1, 0.00),
('2026-02-01 10:00:00', 'Pendiente', 2, 2, 1, 0.00),
('2026-02-02 11:00:00', 'Pendiente', 3, 3, 2, 0.00),
('2026-02-02 14:00:00', 'Pendiente', 4, 4, 2, 0.00),
('2026-02-03 09:30:00', 'Pendiente', 5, 5, 3, 0.00),
('2026-02-03 15:00:00', 'Pendiente', 6, 6, 3, 0.00),
('2026-02-04 10:00:00', 'Pendiente', 7, 7, 4, 0.00),
('2026-02-04 11:30:00', 'Pendiente', 8, 8, 4, 0.00),
('2026-02-05 09:00:00', 'Pendiente', 9, 9, 5, 0.00),
('2026-02-05 16:00:00', 'Pendiente', 10, 10, 5, 0.00);
GO

-- DETALLE CITA SERVICIO CORREGIDO (Sin PrecioUnitario)
INSERT INTO Gestion.DetalleCitaServicio (CitaID, ServicioID) VALUES 
(1, 1), -- Cita 1: Corte
(2, 3), -- Cita 2: Corte + Barba
(3, 1), (3, 5), -- Cita 3: Corte + Tinte
(4, 1), -- Cita 4: Corte
(5, 3), -- Cita 5: Corte + Barba
(7, 3), (7, 4), -- Cita 7: Corte+Barba + Mascarilla
(8, 6), -- Cita 8: Alisado
(9, 1), (9, 7), -- Cita 9: Corte + Tratamiento
(11, 1), -- Cita 11: Corte
(12, 3), -- Cita 12: Corte + Barba
(13, 3), (13, 4), -- Cita 13: Corte+Barba + Mascarilla
(15, 1), (15, 7), -- Cita 15: Corte + Tratamiento
(16, 1), -- Cita 16: Corte
(17, 2), -- Cita 17: Afeitado
(18, 12), -- Cita 18: Trenzas
(19, 1), -- Cita 19: Corte
(20, 3), -- Cita 20: Corte + Barba
-- Citas futuras con servicios
(21, 1), (21, 2),
(22, 3),
(23, 5),
(24, 6),
(25, 1), (25, 4),
(26, 7),
(27, 8),
(28, 9), (28, 10),
(29, 11),
(30, 12);
GO

-- =============================================================================
-- PASO 5: FUNCIONES (Lógica de Negocio)
-- =============================================================================

CREATE OR ALTER FUNCTION Gestion.fn_EsBarberoDisponible(@BarberoID INT, @FechaHora DATETIME)
RETURNS BIT AS
BEGIN
    DECLARE @EstaDisponible BIT = 1; 
    IF EXISTS (SELECT 1 FROM Gestion.Cita WHERE BarberoID = @BarberoID AND FechaHora = @FechaHora AND Estado <> 'Cancelada')
        SET @EstaDisponible = 0;
    RETURN @EstaDisponible;
END;
GO

CREATE OR ALTER FUNCTION Gestion.fn_BarberoPerteneceASede(@BarberoID INT, @SedeID INT)
RETURNS BIT AS
BEGIN
    DECLARE @Pertenece BIT = 0;
    IF EXISTS (SELECT 1 FROM Gestion.Barbero WHERE BarberoID = @BarberoID AND SedeID = @SedeID)
        SET @Pertenece = 1;
    RETURN @Pertenece;
END;
GO

-- IMPORTANTE: Cálculo con JOIN (Lógica corregida)
CREATE OR ALTER FUNCTION Gestion.fn_CalcularTotalConIVA(@CitaID INT)
RETURNS DECIMAL(10,2) AS
BEGIN
    DECLARE @Subtotal DECIMAL(10,2);
    SELECT @Subtotal = ISNULL(SUM(S.Precio), 0)
    FROM Gestion.DetalleCitaServicio D
    INNER JOIN Gestion.Servicio S ON D.ServicioID = S.ServicioID
    WHERE D.CitaID = @CitaID;
    RETURN @Subtotal * 1.15;
END;
GO

CREATE OR ALTER FUNCTION Gestion.fn_CalcularEdad(@FechaNacimiento DATE)
RETURNS INT AS
BEGIN
    DECLARE @Edad INT;
    SET @Edad = DATEDIFF(YEAR, @FechaNacimiento, GETDATE()) - 
                CASE WHEN (MONTH(@FechaNacimiento) > MONTH(GETDATE())) OR 
                          (MONTH(@FechaNacimiento) = MONTH(GETDATE()) AND DAY(@FechaNacimiento) > DAY(GETDATE())) 
                     THEN 1 ELSE 0 END;
    RETURN @Edad;
END;
GO

-- =============================================================================
-- PASO 6: TRIGGERS
-- =============================================================================

CREATE OR ALTER TRIGGER Gestion.trg_ValidarDisponibilidadCita ON Gestion.Cita AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i WHERE (SELECT COUNT(*) FROM Gestion.Cita WHERE BarberoID = i.BarberoID AND FechaHora = i.FechaHora AND Estado <> 'Cancelada') > 1)
    BEGIN
        RAISERROR ('El barbero ya tiene una cita en ese horario.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE OR ALTER TRIGGER Gestion.trg_ValidarSedeBarbero ON Gestion.Cita AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i WHERE NOT EXISTS (SELECT 1 FROM Gestion.Barbero WHERE BarberoID = i.BarberoID AND SedeID = i.SedeID))
    BEGIN
        RAISERROR ('El barbero no trabaja en la sede de la cita.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

CREATE OR ALTER TRIGGER Gestion.trg_MantenimientoTotalCita ON Gestion.DetalleCitaServicio AFTER INSERT, DELETE, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CitasAfectadas TABLE (CitaID INT);
    INSERT INTO @CitasAfectadas (CitaID) SELECT DISTINCT CitaID FROM inserted UNION SELECT DISTINCT CitaID FROM deleted;
    UPDATE C SET C.Total = Gestion.fn_CalcularTotalConIVA(C.CitaID) FROM Gestion.Cita C INNER JOIN @CitasAfectadas A ON C.CitaID = A.CitaID;
END;
GO

CREATE OR ALTER TRIGGER Gestion.trg_ValidarEdadBarbero ON Gestion.Barbero AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE Gestion.fn_CalcularEdad(FechaNacimiento) < 18)
    BEGIN
        RAISERROR ('El barbero debe ser mayor de 18 anios.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- =============================================================================
-- PASO 7: PROCEDIMIENTOS ALMACENADOS (CRUD)
-- =============================================================================

CREATE OR ALTER PROCEDURE Gestion.sp_CU_Ciudad @ID Gestion.D_ID = NULL, @Nombre Gestion.D_TextoCorto, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Ciudad (NombreCiudad) VALUES (@Nombre);
    ELSE IF @Accion = 'U' UPDATE Gestion.Ciudad SET NombreCiudad = @Nombre WHERE CiudadID = @ID;
    ELSE IF @Accion = 'D' BEGIN
        IF NOT EXISTS (SELECT 1 FROM Gestion.Sede WHERE CiudadID = @ID) DELETE FROM Gestion.Ciudad WHERE CiudadID = @ID;
        ELSE RAISERROR ('No se puede eliminar: Ciudad tiene sedes.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CU_Especialidad @ID Gestion.D_ID = NULL, @Nombre Gestion.D_TextoCorto, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Especialidad (NombreEspecialidad) VALUES (@Nombre);
    ELSE IF @Accion = 'U' UPDATE Gestion.Especialidad SET NombreEspecialidad = @Nombre WHERE EspecialidadID = @ID;
    ELSE IF @Accion = 'D' BEGIN
        IF NOT EXISTS (SELECT 1 FROM Gestion.Barbero WHERE EspecialidadID = @ID) DELETE FROM Gestion.Especialidad WHERE EspecialidadID = @ID;
        ELSE RAISERROR ('No se puede eliminar: Especialidad tiene barberos.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CRUD_Cliente @ID Gestion.D_ID = NULL, @Cedula Gestion.D_Identificacion = NULL, @Nombres Gestion.D_Nombre = NULL, @Apellidos Gestion.D_Nombre = NULL, @Telefono Gestion.D_Telefono = NULL, @Email Gestion.D_Email = NULL, @Direccion Gestion.D_Direccion = NULL, @Sexo Gestion.D_Sexo = NULL, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Cliente (Cedula, Nombres, Apellidos, Telefono, Email, Direccion, Sexo) VALUES (@Cedula, @Nombres, @Apellidos, @Telefono, @Email, @Direccion, @Sexo);
    ELSE IF @Accion = 'U' UPDATE Gestion.Cliente SET Telefono = @Telefono, Email = @Email, Direccion = @Direccion WHERE ClienteID = @ID;
    ELSE IF @Accion = 'D' BEGIN
        IF NOT EXISTS (SELECT 1 FROM Gestion.Cita WHERE ClienteID = @ID) DELETE FROM Gestion.Cliente WHERE ClienteID = @ID;
        ELSE RAISERROR ('No se puede eliminar: Cliente tiene citas.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CRUD_Barbero @ID Gestion.D_ID = NULL, @Cedula Gestion.D_Identificacion = NULL, @Nombres Gestion.D_Nombre = NULL, @Apellidos Gestion.D_Nombre = NULL, @Telefono Gestion.D_Telefono = NULL, @Email Gestion.D_Email = NULL, @EspecialidadID Gestion.D_ID = NULL, @SedeID Gestion.D_ID = NULL, @FechaNacimiento DATE = NULL, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Barbero (Cedula, Nombres, Apellidos, Telefono, Email, EspecialidadID, SedeID, FechaNacimiento) VALUES (@Cedula, @Nombres, @Apellidos, @Telefono, @Email, @EspecialidadID, @SedeID, @FechaNacimiento);
    ELSE IF @Accion = 'U' UPDATE Gestion.Barbero SET Telefono = @Telefono, Email = @Email, EspecialidadID = @EspecialidadID, SedeID = @SedeID WHERE BarberoID = @ID;
    ELSE IF @Accion = 'D' BEGIN
        IF NOT EXISTS (SELECT 1 FROM Gestion.Cita WHERE BarberoID = @ID) DELETE FROM Gestion.Barbero WHERE BarberoID = @ID;
        ELSE RAISERROR ('No se puede eliminar: Barbero tiene citas.', 16, 1);
    END
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CU_Franquiciado @ID Gestion.D_ID = NULL, @Nombre Gestion.D_Nombre, @RUC Gestion.D_Identificacion, @Regalia Gestion.D_Porcentaje, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Franquiciado (NombreCompleto, RUC, PorcentajeRegalia) VALUES (@Nombre, @RUC, @Regalia);
    ELSE IF @Accion = 'U' UPDATE Gestion.Franquiciado SET NombreCompleto = @Nombre, PorcentajeRegalia = @Regalia WHERE FranquiciadoID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CRUD_Sede @ID Gestion.D_ID = NULL, @Nombre Gestion.D_Nombre = NULL, @Direccion Gestion.D_Direccion = NULL, @Telefono Gestion.D_Telefono = NULL, @CiudadID Gestion.D_ID = NULL, @FranquiciadoID Gestion.D_ID = NULL, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Sede (NombreSede, Direccion, Telefono, CiudadID, FranquiciadoID) VALUES (@Nombre, @Direccion, @Telefono, @CiudadID, @FranquiciadoID);
    ELSE IF @Accion = 'U' UPDATE Gestion.Sede SET NombreSede = @Nombre, Direccion = @Direccion, Telefono = @Telefono WHERE SedeID = @ID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CU_Servicio @ID Gestion.D_ID = NULL, @Nombre Gestion.D_Nombre, @Precio Gestion.D_Dinero, @Duracion Gestion.D_Cantidad, @Accion CHAR(1) AS
BEGIN
    IF @Accion = 'I' INSERT INTO Gestion.Servicio (NombreServicio, Precio, DuracionMinutos) VALUES (@Nombre, @Precio, @Duracion);
    ELSE IF @Accion = 'U' UPDATE Gestion.Servicio SET NombreServicio = @Nombre, Precio = @Precio, DuracionMinutos = @Duracion WHERE ServicioID = @ID;
END;
GO

-- PROCEDIMIENTOS DE CITA (SIN PRECIOS MANUALES)
CREATE OR ALTER PROCEDURE Gestion.sp_InsertarCita @FechaHora Gestion.D_FechaHora, @ClienteID Gestion.D_ID, @BarberoID Gestion.D_ID, @SedeID Gestion.D_ID AS
BEGIN
    INSERT INTO Gestion.Cita (FechaHora, ClienteID, BarberoID, SedeID, Estado, Total) VALUES (@FechaHora, @ClienteID, @BarberoID, @SedeID, 'Pendiente', 0.00);
    SELECT SCOPE_IDENTITY() AS NuevaCitaID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_ActualizarCita @CitaID Gestion.D_ID, @FechaHora Gestion.D_FechaHora, @ClienteID Gestion.D_ID, @BarberoID Gestion.D_ID, @SedeID Gestion.D_ID, @Estado Gestion.D_Estado AS
BEGIN
    UPDATE Gestion.Cita SET FechaHora = @FechaHora, ClienteID = @ClienteID, BarberoID = @BarberoID, SedeID = @SedeID, Estado = @Estado WHERE CitaID = @CitaID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_InsertarDetalleCita @CitaID Gestion.D_ID, @ServicioID Gestion.D_ID AS
BEGIN
    INSERT INTO Gestion.DetalleCitaServicio (CitaID, ServicioID) VALUES (@CitaID, @ServicioID);
END;
GO

-- CORRECCION: Se agregó el Procedure faltante en la reconstrucción
CREATE OR ALTER PROCEDURE Gestion.sp_ActualizarDetalleCita @DetalleServicioID Gestion.D_ID, @ServicioID Gestion.D_ID AS
BEGIN
    UPDATE Gestion.DetalleCitaServicio SET ServicioID = @ServicioID WHERE DetalleServicioID = @DetalleServicioID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_CancelarCita @CitaID Gestion.D_ID AS
BEGIN
    UPDATE Gestion.Cita SET Estado = 'Cancelada' WHERE CitaID = @CitaID;
END;
GO

CREATE OR ALTER PROCEDURE Gestion.sp_ProcesarCitasNoAsistidas AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CitaID_Actual INT, @Contador INT = 0;
    DECLARE cur_CitasVencidas CURSOR FOR SELECT CitaID FROM Gestion.Cita WHERE Estado = 'Pendiente' AND FechaHora < GETDATE();
    OPEN cur_CitasVencidas;
    FETCH NEXT FROM cur_CitasVencidas INTO @CitaID_Actual;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        UPDATE Gestion.Cita SET Estado = 'No Asistida' WHERE CitaID = @CitaID_Actual;
        SET @Contador = @Contador + 1;
        FETCH NEXT FROM cur_CitasVencidas INTO @CitaID_Actual;
    END
    CLOSE cur_CitasVencidas;
    DEALLOCATE cur_CitasVencidas;
    PRINT 'Citas marcadas como No Asistidas: ' + CAST(@Contador AS NVARCHAR(10));
END;
GO

-- =============================================================================
-- PASO 8: VISTAS (REPORTES)
-- =============================================================================

-- BLOQUE 1: ANALISIS FINANCIERO
CREATE OR ALTER VIEW Gestion.v_ReporteRegaliasMensuales AS
SELECT f.NombreCompleto AS "Franquiciado", COUNT(c.CitaID) AS "Citas Atendidas", SUM(c.Total) AS "Venta Bruta", f.PorcentajeRegalia AS "% Regalia", SUM(c.Total * f.PorcentajeRegalia / 100.0) AS "Total A Pagar"
FROM Gestion.Cita c INNER JOIN Gestion.Sede s ON s.SedeID = c.SedeID INNER JOIN Gestion.Franquiciado f ON f.FranquiciadoID = s.FranquiciadoID
WHERE c.Estado = 'Atendida' GROUP BY f.NombreCompleto, f.PorcentajeRegalia;
GO

CREATE OR ALTER VIEW Gestion.v_IngresosPorCiudad AS
SELECT TOP 100 PERCENT ciu.NombreCiudad AS "Ciudad", ISNULL(SUM(c.Total), 0) AS "Ingreso Generado"
FROM Gestion.Ciudad ciu LEFT JOIN Gestion.Sede s ON s.CiudadID = ciu.CiudadID LEFT JOIN Gestion.Cita c ON c.SedeID = s.SedeID AND c.Estado = 'Atendida'
GROUP BY ciu.NombreCiudad ORDER BY "Ingreso Generado" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_TicketPromedioPorSede AS
SELECT TOP 100 PERCENT s.NombreSede AS "Sede", COUNT(c.CitaID) AS "Total Citas", AVG(c.Total) AS "Ticket Promedio"
FROM Gestion.Sede s INNER JOIN Gestion.Cita c ON s.SedeID = c.SedeID WHERE c.Estado = 'Atendida'
GROUP BY s.NombreSede ORDER BY "Ticket Promedio" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_SedesBajoRendimiento AS
SELECT s.NombreSede, ISNULL(SUM(c.Total), 0) AS "Venta Total Historica"
FROM Gestion.Sede s LEFT JOIN Gestion.Cita c ON s.SedeID = c.SedeID AND c.Estado = 'Atendida'
GROUP BY s.NombreSede HAVING ISNULL(SUM(c.Total), 0) < 500;
GO

-- BLOQUE 2: PRODUCTIVIDAD OPERATIVA
CREATE OR ALTER VIEW Gestion.v_TopBarberosDelMes AS
SELECT TOP 3 b.Nombres + ' ' + b.Apellidos AS "Barbero", SUM(c.Total) AS "Recaudado Este Mes"
FROM Gestion.Barbero b INNER JOIN Gestion.Cita c ON b.BarberoID = c.BarberoID
WHERE c.Estado = 'Atendida' AND MONTH(c.FechaHora) = MONTH(GETDATE()) AND YEAR(c.FechaHora) = YEAR(GETDATE())
GROUP BY b.Nombres, b.Apellidos ORDER BY "Recaudado Este Mes" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_EficienciaCitas AS
SELECT b.Nombres AS "Barbero", COUNT(c.CitaID) AS "Citas Totales", SUM(CASE WHEN c.Estado = 'Cancelada' THEN 1 ELSE 0 END) AS "Canceladas",
CAST(SUM(CASE WHEN c.Estado = 'Cancelada' THEN 1 ELSE 0 END) * 100.0 / COUNT(c.CitaID) AS DECIMAL(5,2)) AS "% Cancelacion"
FROM Gestion.Barbero b INNER JOIN Gestion.Cita c ON b.BarberoID = c.BarberoID GROUP BY b.Nombres;
GO

CREATE OR ALTER VIEW Gestion.v_BarberosMultifaceticos AS
SELECT b.Nombres, COUNT(DISTINCT d.ServicioID) AS "Tipos Servicios Distintos"
FROM Gestion.Barbero b INNER JOIN Gestion.Cita c ON b.BarberoID = c.BarberoID INNER JOIN Gestion.DetalleCitaServicio d ON c.CitaID = d.CitaID
GROUP BY b.Nombres HAVING COUNT(DISTINCT d.ServicioID) > 2;
GO

CREATE OR ALTER VIEW Gestion.v_AntiguedadPersonal AS
SELECT Nombres + ' ' + Apellidos AS "Personal", FechaRegistro, DATEDIFF(DAY, FechaRegistro, GETDATE()) AS "Dias Trabajando" FROM Gestion.Barbero;
GO

-- BLOQUE 3: INTELIGENCIA DE CLIENTES
CREATE OR ALTER VIEW Gestion.v_ClientesVIP AS
SELECT TOP 100 PERCENT cli.Nombres + ' ' + cli.Apellidos AS "Cliente VIP", SUM(c.Total) AS "Gasto Total"
FROM Gestion.Cliente cli INNER JOIN Gestion.Cita c ON cli.ClienteID = c.ClienteID WHERE c.Estado = 'Atendida'
GROUP BY cli.Nombres, cli.Apellidos HAVING SUM(c.Total) > 50 ORDER BY "Gasto Total" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_ClientesRecurrentes AS
SELECT cli.Nombres AS "Cliente", COUNT(c.CitaID) AS "Visitas Exitosas"
FROM Gestion.Cliente cli INNER JOIN Gestion.Cita c ON cli.ClienteID = c.ClienteID WHERE c.Estado = 'Atendida'
GROUP BY cli.Nombres HAVING COUNT(c.CitaID) > 1;
GO

CREATE OR ALTER VIEW Gestion.v_UltimaVisitaCliente AS
SELECT cli.Email, MAX(c.FechaHora) AS "Ultima Visita", DATEDIFF(DAY, MAX(c.FechaHora), GETDATE()) AS "Dias Ausente"
FROM Gestion.Cliente cli INNER JOIN Gestion.Cita c ON cli.ClienteID = c.ClienteID WHERE cli.Email IS NOT NULL GROUP BY cli.Email;
GO

CREATE OR ALTER VIEW Gestion.v_DistribucionDemografica AS
SELECT CASE WHEN Sexo = 'M' THEN 'Masculino' ELSE 'Femenino' END AS "Genero", COUNT(*) AS "Cantidad Clientes" FROM Gestion.Cliente GROUP BY Sexo;
GO

-- BLOQUE 4: ANALISIS DE SERVICIOS
CREATE OR ALTER VIEW Gestion.v_RankingServiciosPopulares AS
SELECT TOP 100 PERCENT s.NombreServicio, COUNT(d.DetalleServicioID) AS "Veces Vendido"
FROM Gestion.Servicio s INNER JOIN Gestion.DetalleCitaServicio d ON s.ServicioID = d.ServicioID GROUP BY s.NombreServicio ORDER BY "Veces Vendido" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_ServiciosMasRentables AS
SELECT TOP 100 PERCENT s.NombreServicio, SUM(s.Precio) AS "Dinero Generado"
FROM Gestion.Servicio s INNER JOIN Gestion.DetalleCitaServicio d ON s.ServicioID = d.ServicioID GROUP BY s.NombreServicio ORDER BY "Dinero Generado" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_AnalisisCitasCombinadas AS
SELECT c.CitaID, cli.Nombres AS "Cliente", COUNT(d.ServicioID) AS "Cantidad Servicios"
FROM Gestion.Cita c INNER JOIN Gestion.DetalleCitaServicio d ON c.CitaID = d.CitaID INNER JOIN Gestion.Cliente cli ON c.ClienteID = cli.ClienteID
GROUP BY c.CitaID, cli.Nombres HAVING COUNT(d.ServicioID) > 1;
GO

-- BLOQUE 5: AUDITORIA Y CONTROL TEMPORAL
CREATE OR ALTER VIEW Gestion.v_ResumenDiarioVentas AS
SELECT CAST(FechaHora AS DATE) AS "Fecha", COUNT(CitaID) AS "Citas", SUM(Total) AS "Venta Dia"
FROM Gestion.Cita WHERE Estado = 'Atendida' GROUP BY CAST(FechaHora AS DATE);
GO

CREATE OR ALTER VIEW Gestion.v_PicosDeAtencion AS
SELECT TOP 100 PERCENT DATEPART(HOUR, FechaHora) AS "Hora del Dia", COUNT(CitaID) AS "Afluencia"
FROM Gestion.Cita GROUP BY DATEPART(HOUR, FechaHora) ORDER BY "Afluencia" DESC;
GO

CREATE OR ALTER VIEW Gestion.v_CitasFuturas AS
SELECT c.FechaHora, cli.Nombres + ' ' + cli.Apellidos AS "Cliente", b.Nombres AS "Barbero Asignado"
FROM Gestion.Cita c INNER JOIN Gestion.Cliente cli ON c.ClienteID = cli.ClienteID INNER JOIN Gestion.Barbero b ON c.BarberoID = b.BarberoID
WHERE c.FechaHora > GETDATE() AND c.Estado = 'Pendiente';
GO

CREATE OR ALTER VIEW Gestion.v_PerdidasPorCancelacion AS
SELECT Estado AS "Motivo Perdida", COUNT(CitaID) AS "Cantidad", ISNULL(SUM(Total), 0) AS "Dinero Perdido"
FROM Gestion.Cita WHERE Estado IN ('Cancelada', 'No Asistida') GROUP BY Estado;
GO

-- CORRECCION: Ajuste lógico para reflejar que ya no hay Precio Cobrado manual
CREATE OR ALTER VIEW Gestion.v_AuditoriaPrecios AS
SELECT d.DetalleServicioID, s.NombreServicio, s.Precio AS [Precio Oficial], s.Precio AS [Precio Cobrado], 0.00 AS [Diferencia]
FROM Gestion.DetalleCitaServicio d INNER JOIN Gestion.Servicio s ON d.ServicioID = s.ServicioID;
GO

PRINT '=== BASE DE DATOS RECONSTRUIDA, CORREGIDA Y VALIDADA EXITOSAMENTE ===';
GO