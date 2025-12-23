import { Router } from 'express';
import { createSedeController } from '../../controllers/sede/create.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @swagger
 * /sede/crear-sede:
 *   post:
 *     summary: Crear una nueva sede
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name_sede
 *               - address
 *               - manager_name
 *               - manager_phone
 *               - manager_email
 *               - city
 *               - clientId
 *             properties:
 *               name_sede:
 *                 type: string
 *                 example: "Sede Central"
 *               address:
 *                 type: string
 *                 example: "Av. Principal 123"
 *               manager_name:
 *                 type: string
 *                 example: "Juan Pérez"
 *               manager_phone:
 *                 type: string
 *                 example: "999888777"
 *               manager_email:
 *                 type: string
 *                 example: "juan.perez@empresa.com"
 *               city:
 *                 type: string
 *                 example: "Lima"
 *               clientId:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       201:
 *         description: Sede creada correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     name_sede:
 *                       type: string
 *                       example: "Sede Central"
 *                     address:
 *                       type: string
 *                       example: "Av. Principal 123"
 *                     city:
 *                       type: string
 *                       example: "Lima"
 *                     clientId:
 *                       type: integer
 *                       example: 1
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.post('/crear-sede', authenticate, authorize(['admin']), createSedeController);

export default router;