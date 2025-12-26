import { Router } from 'express';
import { createExtintorController } from '../../controllers/nfc/create.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @swagger
 * /nfc/create-extintor:
 *   post:
 *     summary: Crear un nuevo extintor
 *     tags:
 *       - Extintor
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               codeNFC:
 *                 type: string
 *                 example: "NFC123456"
 *               serialNumber:
 *                 type: string
 *                 example: "SERIE98765"
 *               type:
 *                 type: string
 *                 example: "Polvo Químico"
 *               capacity:
 *                 type: string
 *                 example: "5kg"
 *               agent:
 *                 type: string
 *                 example: "ABC"
 *               cylinderNumber:
 *                 type: string
 *                 example: "CIL123"
 *               location:
 *                 type: string
 *                 example: "Planta 1"
 *               status:
 *                 type: string
 *                 enum: [OPERATIVO, INOPERATIVO]
 *                 example: "OPERATIVO"
 *               historic:
 *                 type: string
 *                 example: "Mantenimiento 2025-01-01"
 *               dateLow:
 *                 type: string
 *                 example: "2026-01-01"
 *               photo:
 *                 type: string
 *                 example: "url_de_la_foto.jpg"
 *               sedeId:
 *                 type: integer
 *                 example: 1
 *     responses:
 *       201:
 *         description: Extintor creado correctamente
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
 *                     codigoNFC:
 *                       type: string
 *                       example: "NFC123456"
 *                     usuarioCreador:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                           example: 2
 *                         name:
 *                           type: string
 *                           example: "Juan Perez"
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */

router.post('/create-extintor', authenticate, authorize(['admin', 'tecnico']), createExtintorController);

export default router;