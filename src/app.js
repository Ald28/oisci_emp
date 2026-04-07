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
import nfcEditRoutes from '../routes/nfc/edit.routes.js';

import servicioCreateRoutes from '../routes/services/register.routes.js';
import listServicioRoutes from '../routes/services/list.routes.js';
import approvedRoutes from '../routes/services/approved.routes.js';
import editService from '../routes/services/serviceEdit.routes.js';
import serviceDetailRoutes from '../routes/services/detail.routes.js';

import mantenimientoRoutes from '../routes/mantenimientoD/mantenimientoDetalle.routes.js';
import editMantenimiento from '../routes/mantenimientoD/edit.routes.js';

import inspeccionRoutes from '../routes/inspeccionD/inspeccionDetalle.routes.js';
import pdfInspeccion from '../routes/inspeccionD/detail.routes.js';
import extintorRoutes from '../routes/inspeccionD/extintor.routes.js';

import certificadoRoutes from '../routes/certificado/create.routes.js';
import reporteRoutes from '../routes/reporte/inspeccion.routes.js';
import reporteMensualRoutes from '../routes/reporte/inspeccionMensual.routes.js';
import reporteCreate from '../routes/reporte/reportes.routes.js';

dotenv.config();

const app = express();

app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
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

app.use((req, res, next) => {
    const start = Date.now()

    res.on('finish', () => {
        const duration = Date.now() - start
        console.log(`
🌐 HTTP REQUEST
Method: ${req.method}
URL: ${req.originalUrl}
Status: ${res.statusCode}
Total time: ${duration} ms
`)
    })

    next()
})


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
app.use('/nfc', nfcEditRoutes);

app.use('/statistics', nfcListRoutes);
app.use('/statistics', listServicioRoutes)

app.use('/services', servicioCreateRoutes);
app.use('/services', listServicioRoutes);
app.use('/services', approvedRoutes);
app.use('/services', editService);
app.use('/services', serviceDetailRoutes);

app.use('/mantenimiento', mantenimientoRoutes);
app.use('/mantenimiento', editMantenimiento);

app.use('/inspeccion', inspeccionRoutes);
app.use('/inspeccion', pdfInspeccion);
app.use('/extintores', extintorRoutes);

app.use('/certificado', certificadoRoutes);

app.use('/reporte', reporteRoutes);
app.use('/reporte', reporteMensualRoutes);
app.use('/reporte', reporteCreate);

export default app;