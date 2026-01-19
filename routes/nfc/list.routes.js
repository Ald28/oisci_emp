import { Router } from 'express';
import { listNFCController, getNFCByIdController, searchExtinguisherController, getExtinguisherByIdController, getExtintoresBySedeController } from '../../controllers/nfc/list.controller.js';
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

/**
 * @swagger
 * /nfc/ext-sede/{sedeId}:
 *   get:
 *     summary: Obtener extintores por sede (NFC)
 *     description: Lista todos los extintores asociados a una sede específica usando el módulo NFC
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sedeId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la sede
 *         example: 2
 *     responses:
 *       200:
 *         description: Lista de extintores de la sede
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 15
 *                       codeNFC:
 *                         type: string
 *                         example: NFC-987654
 *                       serialNumber:
 *                         type: string
 *                         example: SN-789456
 *                       type:
 *                         type: string
 *                         example: PQS
 *                       capacity:
 *                         type: string
 *                         example: 6KG
 *                       agent:
 *                         type: string
 *                         example: ABC
 *                       location:
 *                         type: string
 *                         example: Almacén
 *                       status:
 *                         type: string
 *                         example: OPERATIVO
 *                       sedeId:
 *                         type: integer
 *                         example: 2
 *       400:
 *         description: sedeId inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       404:
 *         description: No se encontraron extintores para la sede
 *       500:
 *         description: Error interno del servidor
 */

router.get('/ext-sede/:sedeId', authenticate, authorize(['admin', 'user', 'tecnico']), getExtintoresBySedeController);

export default router;