import { Router } from 'express';
import { listNFCController, getNFCByIdController, searchExtinguisherController, getExtinguisherByIdController } from '../../controllers/nfc/list.controller.js';
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
 * /nfc/search/{searchTerm}:
 *   get:
 *     summary: Buscar extintor por número de serie
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: searchTerm
 *         required: true
 *         schema:
 *           type: string
 *         description: Número de serie del extintor
 *         example: "SN123456"
 *     responses:
 *       200:
 *         description: Extintor encontrado
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
 *                     numeroSerie:
 *                       type: string
 *                       example: "SN123456"
 *                     tipo:
 *                       type: string
 *                       example: "Polvo Químico"
 *                     capacidad:
 *                       type: string
 *                       example: "5kg"
 *                     agente:
 *                       type: string
 *                       example: "ABC"
 *                     estado:
 *                       type: string
 *                       example: "OPERATIVO"
 *       404:
 *         description: Extintor no encontrado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: "Extintor no encontrado"
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/search/:searchTerm', authenticate, authorize(['tecnico']), searchExtinguisherController);

/**
 * @swagger
 * /nfc/{extintorId}:
 *   get:
 *     summary: Obtener extintor por ID
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: extintorId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del extintor
 *         example: 1
 *     responses:
 *       200:
 *         description: Extintor encontrado
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
 *                     serialNumber:
 *                       type: string
 *                     type:
 *                       type: string
 *                     capacity:
 *                       type: string
 *                     agent:
 *                       type: string
 *                     status:
 *                       type: string
 *       404:
 *         description: Extintor no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/:extintorId', authenticate, authorize(['tecnico']), getExtinguisherByIdController);

export default router;