import express from 'express';
import userRoutes from '../routes/auth.routes.js';
import registeRoutes from '../routes/register.routes.js';
import dotenv from "dotenv";
import { registerUser } from '../controllers/register.controller.js';
dotenv.config();

const app = express();

app.use(express.json());
app.use('/users', userRoutes);
app.use('/users', registeRoutes);

export default app;