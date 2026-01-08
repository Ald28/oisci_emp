import express from 'express';
import cors from 'cors';
import dotenv from "dotenv";
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger.js';

import userRoutes from '../routes/client/auth.routes.js';
import registeRoutes from '../routes/client/register.routes.js';
import listRoutes from '../routes/client/list.routes.js';
import deleteRoutes from '../routes/client/delete.routes.js';
import editRoutes from '../routes/client/edit.routes.js';

import sedeCreateRoutes from '../routes/sede/create.routes.js';
import sedeListRoutes from '../routes/sede/list.routes.js';
import sedeDeleteRoutes from '../routes/sede/delete.routes.js';

import nfcListRoutes from '../routes/nfc/list.routes.js';
import nfcCreateRoutes from '../routes/nfc/create.routes.js';

import servicioCreateRoutes from '../routes/services/register.routes.js';
import listServicioRoutes from '../routes/services/list.routes.js';

import mantenimientoRoutes from '../routes/mantenimientoD/mantenimientoDetalle.routes.js';

dotenv.config();

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());

app.get('/', (req, res) => {
    res.status(200).json({
        status: 'OK',
        message: 'Servidor backend activo ingresar a la ruta de /api-docs para ver la documentación',
        timestamp: new Date()
    });
});

// 📌 Swagger
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 📌 Rutas
app.use('/users', userRoutes);
app.use('/users', registeRoutes);
app.use('/users', listRoutes);
app.use('/users', deleteRoutes);
app.use('/users', editRoutes);

app.use('/sede', sedeCreateRoutes);
app.use('/sede', sedeListRoutes);
app.use('/sede', sedeDeleteRoutes);

app.use('/nfc', nfcListRoutes);
app.use('/nfc', nfcCreateRoutes);

app.use('/services', servicioCreateRoutes);
app.use('/services', listServicioRoutes);

app.use('/mantenimiento', mantenimientoRoutes);

export default app;