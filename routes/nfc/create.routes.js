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
 *               codeExtintor:
 *                 type: string
 *                 example: "NFC123456"
 *               serialNumberNFC:
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
 *               pressure:
 *                 type: string
 *                 example: "195 PSI"
 *               brand:
 *                 type: string
 *                 example: "Amerex"
 *               model:
 *                 type: string
 *                 example: "B456"
 *               rating:
 *                 type: string
 *                 example: "2A:10B:C"
 *               yearManufacture:
 *                 type: string
 *                 example: "2020"
 *               status:
 *                 type: string
 *                 enum: [OPERATIVO, INOPERATIVO]
 *                 example: "OPERATIVO"
 *               dateHydrostatic:
 *                 type: string
 *                 format: date-time
 *                 example: "2024-01-15T00:00:00.000Z"
 *               dateMaintenance:
 *                 type: string
 *                 format: date-time
 *                 example: "2024-01-15T00:00:00.000Z"
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
 *                     codeExtintor:
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