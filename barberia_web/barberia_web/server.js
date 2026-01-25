/**
 * Barbería Profesional T13 - Backend API
 * Tecnologías: Node.js + Express + mssql
 * Conecta con la base de datos SQL Server local
 */

const express = require('express');
const sql = require('mssql');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Configuración de SQL Server (SQL Authentication)
// Usuario: app_barberia / Contraseña: Barberia2024!
const dbConfig = {
    user: 'app_barberia',
    password: 'Barberia2024!',
    server: 'localhost',
    database: 'BarberiaFranquiciaDB',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

// Pool de conexiones
let pool;

async function connectDB() {
    try {
        pool = await sql.connect(dbConfig);
        console.log('✅ Conectado a SQL Server: BarberiaFranquiciaDB');
    } catch (err) {
        // Si falla SQL Auth, intentar con msnodesqlv8 (Windows Auth)
        console.log('⚠️ SQL Auth falló, intentando Windows Auth...');
        try {
            const sqlv8 = require('mssql/msnodesqlv8');
            pool = await sqlv8.connect({
                server: 'localhost',
                database: 'BarberiaFranquiciaDB',
                driver: 'msnodesqlv8',
                options: {
                    trustedConnection: true
                }
            });
            console.log('✅ Conectado via Windows Auth: BarberiaFranquiciaDB');
        } catch (err2) {
            console.error('❌ Error de conexión:', JSON.stringify(err2, null, 2));
            console.error('Por favor verifica que SQL Server esté corriendo y la base de datos exista.');
            process.exit(1);
        }
    }
}

// =============================================
// API: AUTENTICACION
// =============================================

// Login - Busca en Franquiciado primero, luego en Barbero
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Buscar en Franquiciado
        let result = await pool.request()
            .input('Email', sql.NVarChar, email)
            .query('SELECT FranquiciadoID, NombreCompleto, Email, PasswordHash FROM Gestion.Franquiciado WHERE Email = @Email');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            if (user.PasswordHash === password) {
                return res.json({
                    success: true,
                    user: {
                        id: user.FranquiciadoID,
                        nombre: user.NombreCompleto,
                        email: user.Email,
                        rol: 'franquiciado'
                    }
                });
            }
        }

        // Buscar en Barbero
        result = await pool.request()
            .input('Email', sql.NVarChar, email)
            .query('SELECT BarberoID, Nombres, Apellidos, Email, PasswordHash, SedeID FROM Gestion.Barbero WHERE Email = @Email');

        if (result.recordset.length > 0) {
            const user = result.recordset[0];
            if (user.PasswordHash === password) {
                return res.json({
                    success: true,
                    user: {
                        id: user.BarberoID,
                        nombre: user.Nombres + ' ' + user.Apellidos,
                        email: user.Email,
                        rol: 'barbero',
                        sedeID: user.SedeID
                    }
                });
            }
        }

        // No encontrado o password incorrecto
        res.status(401).json({ success: false, error: 'Credenciales incorrectas' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// =============================================
// API: ENTIDADES (CRUD)
// =============================================

// --- CIUDADES ---
app.get('/api/ciudades', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.Ciudad');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- SEDES ---
app.get('/api/sedes', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT s.*, c.NombreCiudad, f.NombreCompleto AS Franquiciado
            FROM Gestion.Sede s
            LEFT JOIN Gestion.Ciudad c ON s.CiudadID = c.CiudadID
            LEFT JOIN Gestion.Franquiciado f ON s.FranquiciadoID = f.FranquiciadoID
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- ESPECIALIDADES ---
app.get('/api/especialidades', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.Especialidad');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- BARBEROS ---
app.get('/api/barberos', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT b.*, e.NombreEspecialidad, s.NombreSede
            FROM Gestion.Barbero b
            LEFT JOIN Gestion.Especialidad e ON b.EspecialidadID = e.EspecialidadID
            LEFT JOIN Gestion.Sede s ON b.SedeID = s.SedeID
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/barberos', async (req, res) => {
    try {
        const { Cedula, Nombres, Apellidos, Telefono, Email, EspecialidadID, SedeID, FechaNacimiento, PasswordHash } = req.body;
        await pool.request()
            .input('Cedula', sql.NVarChar(10), Cedula)
            .input('Nombres', sql.NVarChar(50), Nombres)
            .input('Apellidos', sql.NVarChar(50), Apellidos)
            .input('Telefono', sql.NVarChar(15), Telefono)
            .input('Email', sql.NVarChar(100), Email)
            .input('EspecialidadID', sql.Int, EspecialidadID)
            .input('SedeID', sql.Int, SedeID)
            .input('FechaNacimiento', sql.Date, FechaNacimiento)
            .input('Accion', sql.Char(1), 'I')
            .execute('Gestion.sp_CRUD_Barbero');

        // Si se proporcionó password, actualizar
        if (PasswordHash) {
            await pool.request()
                .input('Email', sql.NVarChar(100), Email)
                .input('PasswordHash', sql.NVarChar(255), PasswordHash)
                .query('UPDATE Gestion.Barbero SET PasswordHash = @PasswordHash WHERE Email = @Email');
        }
        res.json({ success: true, message: 'Barbero registrado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/barberos/:id', async (req, res) => {
    try {
        const { Cedula, Nombres, Apellidos, Telefono, Email, EspecialidadID, SedeID, FechaNacimiento, PasswordHash } = req.body;
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Cedula', sql.NVarChar(10), Cedula)
            .input('Nombres', sql.NVarChar(50), Nombres)
            .input('Apellidos', sql.NVarChar(50), Apellidos)
            .input('Telefono', sql.NVarChar(15), Telefono)
            .input('Email', sql.NVarChar(100), Email)
            .input('EspecialidadID', sql.Int, EspecialidadID)
            .input('SedeID', sql.Int, SedeID)
            .input('FechaNacimiento', sql.Date, FechaNacimiento)
            .input('Accion', sql.Char(1), 'U')
            .execute('Gestion.sp_CRUD_Barbero');

        if (PasswordHash) {
            await pool.request()
                .input('BarberoID', sql.Int, req.params.id)
                .input('PasswordHash', sql.NVarChar(255), PasswordHash)
                .query('UPDATE Gestion.Barbero SET PasswordHash = @PasswordHash WHERE BarberoID = @BarberoID');
        }
        res.json({ success: true, message: 'Barbero actualizado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/barberos/:id', async (req, res) => {
    try {
        await pool.request()
            .input('ID', sql.Int, req.params.id)
            .input('Accion', sql.Char(1), 'D')
            .execute('Gestion.sp_CRUD_Barbero');
        res.json({ success: true, message: 'Barbero eliminado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- CLIENTES ---
app.get('/api/clientes', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.Cliente ORDER BY ClienteID DESC');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/clientes', async (req, res) => {
    try {
        const { Cedula, Nombres, Apellidos, Telefono, Email, Direccion, Sexo } = req.body;
        await pool.request()
            .input('Cedula', sql.NVarChar(10), Cedula)
            .input('Nombres', sql.NVarChar(50), Nombres)
            .input('Apellidos', sql.NVarChar(50), Apellidos)
            .input('Telefono', sql.NVarChar(15), Telefono)
            .input('Email', sql.NVarChar(100), Email)
            .input('Direccion', sql.NVarChar(200), Direccion)
            .input('Sexo', sql.Char(1), Sexo)
            .input('Accion', sql.Char(1), 'I')
            .execute('Gestion.sp_CRUD_Cliente');
        res.json({ success: true, message: 'Cliente registrado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- SERVICIOS ---
app.get('/api/servicios', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.Servicio');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/servicios', async (req, res) => {
    try {
        const { NombreServicio, Precio, DuracionMinutos } = req.body;
        await pool.request()
            .input('NombreServicio', sql.NVarChar(100), NombreServicio)
            .input('Precio', sql.Decimal(10, 2), Precio)
            .input('DuracionMinutos', sql.Int, DuracionMinutos || 30)
            .query('INSERT INTO Gestion.Servicio (NombreServicio, Precio, DuracionMinutos) VALUES (@NombreServicio, @Precio, @DuracionMinutos)');
        res.json({ success: true, message: 'Servicio registrado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/servicios/:id', async (req, res) => {
    try {
        const { NombreServicio, Precio, DuracionMinutos } = req.body;
        await pool.request()
            .input('ServicioID', sql.Int, req.params.id)
            .input('NombreServicio', sql.NVarChar(100), NombreServicio)
            .input('Precio', sql.Decimal(10, 2), Precio)
            .input('DuracionMinutos', sql.Int, DuracionMinutos || 30)
            .query('UPDATE Gestion.Servicio SET NombreServicio = @NombreServicio, Precio = @Precio, DuracionMinutos = @DuracionMinutos WHERE ServicioID = @ServicioID');
        res.json({ success: true, message: 'Servicio actualizado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/servicios/:id', async (req, res) => {
    try {
        await pool.request()
            .input('ServicioID', sql.Int, req.params.id)
            .query('DELETE FROM Gestion.Servicio WHERE ServicioID = @ServicioID');
        res.json({ success: true, message: 'Servicio eliminado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- FRANQUICIADOS ---
app.get('/api/franquiciados', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.Franquiciado');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- SEDES CRUD ---
app.post('/api/sedes', async (req, res) => {
    try {
        const { NombreSede, Direccion, CiudadID, FranquiciadoID, Telefono } = req.body;
        await pool.request()
            .input('NombreSede', sql.NVarChar(100), NombreSede)
            .input('Direccion', sql.NVarChar(200), Direccion)
            .input('CiudadID', sql.Int, CiudadID)
            .input('FranquiciadoID', sql.Int, FranquiciadoID)
            .input('Telefono', sql.NVarChar(15), Telefono)
            .query('INSERT INTO Gestion.Sede (NombreSede, Direccion, CiudadID, FranquiciadoID, Telefono) VALUES (@NombreSede, @Direccion, @CiudadID, @FranquiciadoID, @Telefono)');
        res.json({ success: true, message: 'Sede registrada' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.put('/api/sedes/:id', async (req, res) => {
    try {
        const { NombreSede, Direccion, CiudadID, FranquiciadoID, Telefono } = req.body;
        await pool.request()
            .input('SedeID', sql.Int, req.params.id)
            .input('NombreSede', sql.NVarChar(100), NombreSede)
            .input('Direccion', sql.NVarChar(200), Direccion)
            .input('CiudadID', sql.Int, CiudadID)
            .input('FranquiciadoID', sql.Int, FranquiciadoID)
            .input('Telefono', sql.NVarChar(15), Telefono)
            .query('UPDATE Gestion.Sede SET NombreSede = @NombreSede, Direccion = @Direccion, CiudadID = @CiudadID, FranquiciadoID = @FranquiciadoID, Telefono = @Telefono WHERE SedeID = @SedeID');
        res.json({ success: true, message: 'Sede actualizada' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.delete('/api/sedes/:id', async (req, res) => {
    try {
        await pool.request()
            .input('SedeID', sql.Int, req.params.id)
            .query('DELETE FROM Gestion.Sede WHERE SedeID = @SedeID');
        res.json({ success: true, message: 'Sede eliminada' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- CITAS ---
app.get('/api/citas', async (req, res) => {
    try {
        const result = await pool.request().query(`
            SELECT c.*, 
                   cli.Nombres + ' ' + cli.Apellidos AS NombreCliente,
                   b.Nombres + ' ' + b.Apellidos AS NombreBarbero,
                   s.NombreSede
            FROM Gestion.Cita c
            LEFT JOIN Gestion.Cliente cli ON c.ClienteID = cli.ClienteID
            LEFT JOIN Gestion.Barbero b ON c.BarberoID = b.BarberoID
            LEFT JOIN Gestion.Sede s ON c.SedeID = s.SedeID
            ORDER BY c.FechaHora DESC
        `);
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/citas', async (req, res) => {
    try {
        const { FechaHora, ClienteID, BarberoID, SedeID, Servicios } = req.body;

        // 1. Insertar cabecera de cita
        const citaResult = await pool.request()
            .input('FechaHora', sql.DateTime, FechaHora)
            .input('ClienteID', sql.Int, ClienteID)
            .input('BarberoID', sql.Int, BarberoID)
            .input('SedeID', sql.Int, SedeID)
            .execute('Gestion.sp_InsertarCita');

        const nuevaCitaID = citaResult.recordset[0].NuevaCitaID;

        // 2. Insertar detalles (servicios)
        for (const servicioID of Servicios) {
            await pool.request()
                .input('CitaID', sql.Int, nuevaCitaID)
                .input('ServicioID', sql.Int, servicioID)
                .execute('Gestion.sp_InsertarDetalleCita');
        }

        res.json({ success: true, message: 'Cita creada', citaID: nuevaCitaID });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/citas/:id/cancelar', async (req, res) => {
    try {
        await pool.request()
            .input('CitaID', sql.Int, req.params.id)
            .execute('Gestion.sp_CancelarCita');
        res.json({ success: true, message: 'Cita cancelada' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/citas/:id/atender', async (req, res) => {
    try {
        await pool.request()
            .input('CitaID', sql.Int, req.params.id)
            .query("UPDATE Gestion.Cita SET Estado = 'Atendida' WHERE CitaID = @CitaID");
        res.json({ success: true, message: 'Cita marcada como atendida' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- CITAS PUBLICAS (Flow Integrado) ---
app.post('/api/citas-publicas', async (req, res) => {
    try {
        const { cita, cliente } = req.body;
        let ClienteID;

        // 1. Buscar si el cliente ya existe por Cedula
        const clienteExistente = await pool.request()
            .input('Cedula', sql.NVarChar(10), cliente.Cedula)
            .query('SELECT ClienteID FROM Gestion.Cliente WHERE Cedula = @Cedula');

        if (clienteExistente.recordset.length > 0) {
            // Cliente existe, usar su ID
            ClienteID = clienteExistente.recordset[0].ClienteID;
        } else {
            // Cliente nuevo, crearlo
            // Usamos sp_CRUD_Cliente con accion 'I'
            // Nota: Este SP no devuelve el ID insertado por defecto a menos que lo modifiquemos o hagamos un SELECT despues.
            // Asumiremos que podemos buscarlo por Cedula inmediatamente despues.
            await pool.request()
                .input('Cedula', sql.NVarChar(10), cliente.Cedula)
                .input('Nombres', sql.NVarChar(50), cliente.Nombres)
                .input('Apellidos', sql.NVarChar(50), cliente.Apellidos)
                .input('Telefono', sql.NVarChar(15), cliente.Telefono)
                .input('Email', sql.NVarChar(100), cliente.Email)
                .input('Direccion', sql.NVarChar(200), cliente.Direccion)
                .input('Sexo', sql.Char(1), cliente.Sexo)
                .input('Accion', sql.Char(1), 'I')
                .execute('Gestion.sp_CRUD_Cliente');

            // Recuperar el ID del cliente recien creado
            const nuevoCliente = await pool.request()
                .input('Cedula', sql.NVarChar(10), cliente.Cedula)
                .query('SELECT ClienteID FROM Gestion.Cliente WHERE Cedula = @Cedula');

            ClienteID = nuevoCliente.recordset[0].ClienteID;
        }

        // 2. Crear la Cita
        const citaResult = await pool.request()
            .input('FechaHora', sql.DateTime, cita.FechaHora)
            .input('ClienteID', sql.Int, ClienteID)
            .input('BarberoID', sql.Int, cita.BarberoID)
            .input('SedeID', sql.Int, cita.SedeID)
            .execute('Gestion.sp_InsertarCita');

        const nuevaCitaID = citaResult.recordset[0].NuevaCitaID;

        // 3. Insertar detalles (servicios)
        for (const servicioID of cita.Servicios) {
            await pool.request()
                .input('CitaID', sql.Int, nuevaCitaID)
                .input('ServicioID', sql.Int, servicioID)
                .execute('Gestion.sp_InsertarDetalleCita');
        }

        res.json({ success: true, message: 'Cita y cliente procesados', citaID: nuevaCitaID });

    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// =============================================
// API: VISTAS (REPORTES)
// =============================================

app.get('/api/reportes/regalias', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_ReporteRegaliasMensuales');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/ciudades', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_IngresosPorCiudad');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/top-barberos', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_TopBarberosDelMes');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/ticket-promedio', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_TicketPromedioPorSede');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/clientes-vip', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_ClientesVIP');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/clientes-recurrentes', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_ClientesRecurrentes');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/servicios-populares', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_RankingServiciosPopulares');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/servicios-rentables', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_ServiciosMasRentables');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/picos-atencion', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_PicosDeAtencion');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/eficiencia', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_EficienciaCitas');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/perdidas', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_PerdidasPorCancelacion');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/ventas-diarias', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_ResumenDiarioVentas ORDER BY Fecha DESC');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/citas-futuras', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_CitasFuturas');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/sedes-bajo-rendimiento', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_SedesBajoRendimiento');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/barberos-multifaceticos', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_BarberosMultifaceticos');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/antiguedad-personal', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_AntiguedadPersonal');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/ultima-visita', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_UltimaVisitaCliente');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/demografia', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_DistribucionDemografica');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/citas-combinadas', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_AnalisisCitasCombinadas');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/reportes/auditoria-precios', async (req, res) => {
    try {
        const result = await pool.request().query('SELECT * FROM Gestion.v_AuditoriaPrecios');
        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// =============================================
// FUNCIONES ESPECIALES
// =============================================

// Ejecutar cursor de citas no asistidas
app.post('/api/procesar-no-asistidas', async (req, res) => {
    try {
        await pool.request().execute('Gestion.sp_ProcesarCitasNoAsistidas');
        res.json({ success: true, message: 'Proceso de citas no asistidas ejecutado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Verificar disponibilidad de barbero
app.get('/api/barberos/:id/disponibilidad', async (req, res) => {
    try {
        const { fechaHora } = req.query;
        const result = await pool.request()
            .input('BarberoID', sql.Int, req.params.id)
            .input('FechaHora', sql.DateTime, fechaHora)
            .query('SELECT Gestion.fn_EsBarberoDisponible(@BarberoID, @FechaHora) AS Disponible');
        res.json({ disponible: result.recordset[0].Disponible === true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// =============================================
// INICIAR SERVIDOR
// =============================================

connectDB().then(() => {
    app.listen(PORT, () => {
        console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
        console.log(`📊 API disponible en http://localhost:${PORT}/api`);
    });
});
