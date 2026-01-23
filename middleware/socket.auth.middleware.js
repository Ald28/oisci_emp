import jwt from 'jsonwebtoken';

/**
 * Middleware de autenticación para WebSocket
 * Verifica el token JWT del cliente antes de permitir la conexión
 */
export function authenticateSocket(socket, next) {
  try {
    // El token puede venir en:
    // 1. Query parameter: ?token=xxx
    // 2. Authorization header (si se usa con upgrade)
    const token = socket.handshake.auth?.token || 
                  socket.handshake.query?.token;

    if (!token) {
      return next(new Error('Token de autenticación requerido'));
    }

    // Verificar token JWT
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Agregar información del usuario al socket
    socket.userId = decoded.sub; // sub contiene el userId
    socket.userRole = decoded.role;
    
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return next(new Error('Token inválido'));
    }
    if (error.name === 'TokenExpiredError') {
      return next(new Error('Token expirado'));
    }
    next(new Error('Error de autenticación'));
  }
}
