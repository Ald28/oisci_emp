import { Server } from 'socket.io';
import { authenticateSocket } from '../../middleware/socket.auth.middleware.js';

/**
 * Inicializar servidor Socket.io
 * @param {http.Server} httpServer - Servidor HTTP de Express
 * @returns {Server} Instancia de Socket.io
 */
export function initializeSocket(httpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  // Middleware de autenticación para WebSocket
  io.use(authenticateSocket);

  io.on('connection', (socket) => {
    console.log(`🔌 Cliente conectado: ${socket.id} (Usuario: ${socket.userId})`);

    // Unirse a una "sala" por userId para recibir notificaciones personalizadas
    if (socket.userId) {
      socket.join(`user:${socket.userId}`);
    }

    // Evento: Cliente solicita sincronización incremental
    socket.on('request_sync', async (data) => {
      try {
        const { lastSyncTimestamp } = data;
        // El cliente puede solicitar sincronización manual
        socket.emit('sync_response', {
          message: 'Sincronización solicitada',
          lastSyncTimestamp,
        });
      } catch (error) {
        socket.emit('sync_error', { error: error.message });
      }
    });

    // Evento: Cliente desconectado
    socket.on('disconnect', (reason) => {
      console.log(`🔌 Cliente desconectado: ${socket.id} (Razón: ${reason})`);
    });

    // Manejo de errores
    socket.on('error', (error) => {
      console.error(`❌ Error en socket ${socket.id}:`, error);
    });
  });

  return io;
}

/**
 * Emitir evento de cambio a todos los clientes conectados
 * @param {Server} io - Instancia de Socket.io
 * @param {string} event - Nombre del evento
 * @param {object} data - Datos a enviar
 */
export function broadcastChange(io, event, data) {
  if (!io) return;
  
  // Emitir a todos los clientes conectados
  io.emit(event, {
    ...data,
    timestamp: new Date().toISOString(),
  });
  
  console.log(`📡 Evento emitido: ${event} a todos los clientes`);
}

/**
 * Emitir evento de cambio a un usuario específico
 * @param {Server} io - Instancia de Socket.io
 * @param {number} userId - ID del usuario
 * @param {string} event - Nombre del evento
 * @param {object} data - Datos a enviar
 */
export function emitToUser(io, userId, event, data) {
  if (!io) return;
  
  // Emitir solo a la sala del usuario
  io.to(`user:${userId}`).emit(event, {
    ...data,
    timestamp: new Date().toISOString(),
  });
  
  console.log(`📡 Evento emitido: ${event} al usuario ${userId}`);
}
