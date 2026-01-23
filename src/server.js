import { createServer } from 'http';
import app from "./app.js";
import dotenv from "dotenv";
import { initializeSocket } from './socket/socket.server.js';

dotenv.config();

const PORT = process.env.PORT || 8000;

// Crear servidor HTTP (necesario para Socket.io)
const httpServer = createServer(app);

// Inicializar Socket.io
export const io = initializeSocket(httpServer);

// Hacer io disponible globalmente para emitir eventos desde otros módulos
global.io = io;

httpServer.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log(`🔌 WebSocket server ready`);
});