import { Router } from 'express';
import { listNFCController, getNFCByIdController } from '../../controllers/nfc/list.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @swagger
 * /nfc/list-nfc:
 *   get:
 *     summary: Listar todos los NFC
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de NFC
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   codigoNFC:
 *                     type: string
 *                     example: "NFC123456"
 *                   numeroSerie:
 *                     type: string
 *                     example: "SERIE98765"
 *                   tipo:
 *                     type: string
 *                     example: "Polvo Químico"
 *                   capacidad:
 *                     type: string
 *                     example: "5kg"
 *                   agente:
 *                     type: string
 *                     example: "ABC"
 *                   estado:
 *                     type: string
 *                     example: "OPERATIVO"
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/list-nfc', listNFCController);

/**
 * @swagger
 * /nfc/search/{codigoNFC}:
 *   get:
 *     summary: Buscar un NFC por su código
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: codigoNFC
 *         required: true
 *         schema:
 *           type: string
 *         example: "NFC123456"
 *     responses:
 *       200:
 *         description: NFC encontrado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 codigoNFC:
 *                   type: string
 *                   example: "NFC123456"
 *                 numeroSerie:
 *                   type: string
 *                   example: "SERIE98765"
 *                 tipo:
 *                   type: string
 *                   example: "Polvo Químico"
 *                 capacidad:
 *                   type: string
 *                   example: "5kg"
 *                 agente:
 *                   type: string
 *                   example: "ABC"
 *                 estado:
 *                   type: string
 *                   example: "OPERATIVO"
 *       404:
 *         description: NFC no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/search/:codigoNFC', getNFCByIdController);

export default router;