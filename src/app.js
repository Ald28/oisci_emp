import express from 'express';
import dotenv from "dotenv";
import swaggerUi from 'swagger-ui-express';
import swaggerSpec from './config/swagger.js';

import userRoutes from '../routes/client/auth.routes.js';
import registeRoutes from '../routes/client/register.routes.js';
import listRoutes from '../routes/client/list.routes.js';
import deleteRoutes from '../routes/client/delete.routes.js';
import editRoutes from '../routes/client/edit.routes.js';

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

export default app;