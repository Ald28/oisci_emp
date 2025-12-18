import express from 'express';
import userRoutes from '../routes/auth.routes.js';
import registeRoutes from '../routes/register.routes.js';
import listRoutes from '../routes/list.routes.js';
import deleteRoutes from '../routes/delete.routes.js';
import editRoutes from '../routes/edit.routes.js';
import dotenv from "dotenv";
dotenv.config();

const app = express();

app.use(express.json());
app.use('/users', userRoutes);
app.use('/users', registeRoutes);
app.use('/users', listRoutes);
app.use('/users', deleteRoutes);
app.use('/users', editRoutes);

export default app;