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
 *               codigoNFC:
 *                 type: string
 *                 example: "NFC123456"
 *               numeroSerie:
 *                 type: string
 *                 example: "SERIE98765"
 *               tipo:
 *                 type: string
 *                 example: "Polvo Químico"
 *               capacidad:
 *                 type: string
 *                 example: "5kg"
 *               agente:
 *                 type: string
 *                 example: "ABC"
 *               numeroCilindro:
 *                 type: string
 *                 example: "CIL123"
 *               ubicacion:
 *                 type: string
 *                 example: "Planta 1"
 *               estado:
 *                 type: string
 *                 enum: [OPERATIVO, INOPERATIVO]
 *                 example: "OPERATIVO"
 *               historico:
 *                 type: string
 *                 example: "Mantenimiento 2025-01-01"
 *               fechaBaja:
 *                 type: string
 *                 example: "2026-01-01"
 *               foto:
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