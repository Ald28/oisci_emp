import { Router } from 'express';
import { listNFCController, getNFCByIdController, searchExtinguisherController, getExtinguisherByIdController, getExtintoresBySedeController, getExtintoresStatsBySedeController, getExtinguishersUpdatedSinceController, listExtintorNumberController, updateExtinguisherController, listExtintoresWithFiltersController } from '../../controllers/nfc/list.controller.js';
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
 *                   codeExtintor:
 *                     type: string
 *                     example: "NFC123456"
 *                   serialNumberNFC:
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
 * /nfc/list-nfc:
 *   get:
 *     summary: Listar todos los Extintores sin número de serie
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de Extintores sin número de serie
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   codeExtintor:
 *                     type: string
 *                     example: "NFC123456"
 *                   serialNumberNFC:
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
router.get('/list-extintor-number', authenticate, authorize(['admin', 'user', 'tecnico']), listExtintorNumberController);

/**
 * @swagger
 * /nfc/extintores:
 *   get:
 *     summary: Listar extintores con filtros opcionales
 *     description: |
 *       Permite listar extintores aplicando filtros opcionales.
 *       Si no se envía ningún parámetro, retorna todos los extintores.
 *
 *       Filtros disponibles:
 *       - hasCodeExtintor=true → solo extintores con codeExtintor
 *       - hasCodeExtintor=false → solo extintores sin codeExtintor
 *       - hasSerialNumberNFC=true → solo extintores con serialNumberNFC
 *       - hasSerialNumberNFC=false → solo extintores sin serialNumberNFC
 *
 *       Los filtros pueden combinarse.
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: hasCodeExtintor
 *         required: false
 *         schema:
 *           type: boolean
 *         description: Filtrar extintores que tengan o no codeExtintor
 *         example: true
 *
 *       - in: query
 *         name: hasSerialNumberNFC
 *         required: false
 *         schema:
 *           type: boolean
 *         description: Filtrar extintores que tengan o no serialNumberNFC
 *         example: false
 *
 *     responses:
 *       200:
 *         description: Lista de extintores
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
 *                         example: 10
 *                       codeExtintor:
 *                         type: string
 *                         nullable: true
 *                         example: NFC123456
 *                       serialNumberNFC:
 *                         type: string
 *                         nullable: true
 *                         example: SN-987654
 *                       type:
 *                         type: string
 *                         example: Polvo Químico
 *                       capacity:
 *                         type: string
 *                         example: 5kg
 *                       agent:
 *                         type: string
 *                         example: ABC
 *                       status:
 *                         type: string
 *                         example: OPERATIVO
 *                       sedeId:
 *                         type: integer
 *                         example: 1
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/extintores', authenticate, authorize(['admin', 'tecnico']), listExtintoresWithFiltersController);

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
 *                       codeExtintor:
 *                         type: string
 *                         example: NFC-987654
 *                       serialNumberNFC:
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

router.get('/extintores/sede/:sedeId', authenticate, authorize(['admin', 'user', 'tecnico']), getExtintoresStatsBySedeController);

/**
 * @swagger
 * /nfc/sync/incremental:
 *   get:
 *     summary: Obtener extintores modificados después de un timestamp
 *     description: Para sincronización incremental. Retorna solo extintores creados o modificados después del timestamp proporcionado.
 *     tags:
 *       - NFC
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: since
 *         required: true
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Timestamp ISO 8601 desde el cual obtener cambios
 *         example: "2026-01-22T10:00:00Z"
 *     responses:
 *       200:
 *         description: Lista de extintores modificados
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *       400:
 *         description: Parámetro "since" faltante o inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/sync/incremental', authenticate, authorize(['admin', 'user', 'tecnico']), getExtinguishersUpdatedSinceController);

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
 *                     codeExtintor:
 *                       type: string
 *                     serialNumberNFC:
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
 * /nfc/{extintorId}:
 *   patch:
 *     summary: Actualizar extintor
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
 *         description: ID del extintor a actualizar
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               codeExtintor:
 *                 type: string
 *               serialNumberNFC:
 *                 type: string
 *               type:
 *                 type: string
 *               capacity:
 *                 type: string
 *               agent:
 *                 type: string
 *               cylinderNumber:
 *                 type: string
 *               location:
 *                 type: string
 *               status:
 *                 type: string
 *               pressure:
 *                 type: string
 *               brand:
 *                 type: string
 *               model:
 *                 type: string
 *               rating:
 *                 type: string
 *               yearManufacture:
 *                 type: string
 *               dateHydrostatic:
 *                 type: string
 *               dateMaintenance:
 *                 type: string
 *     responses:
 *       200:
 *         description: Extintor actualizado exitosamente
 *       404:
 *         description: Extintor no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.patch('/:extintorId', authenticate, authorize(['tecnico']), updateExtinguisherController);

export default router;