import express from 'express';
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

dotenv.config();

const app = express();

app.use(express.json());

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

export default app;