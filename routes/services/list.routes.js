import { Router } from 'express'
import { ListController } from '../../controllers/services/list.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /services/en-proceso:
 *   get:
 *     summary: Obtener servicios en proceso del usuario actual
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de servicios en proceso
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                       type:
 *                         type: string
 *                       dateStart:
 *                         type: string
 *                       status:
 *                         type: string
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
// IMPORTANTE: Las rutas específicas deben ir ANTES de las rutas con parámetros
// para evitar que Express interprete "en-proceso" como un servicioId
router.get('/en-proceso', authenticate, authorize(['tecnico']), ListController.getInProgress)

/**
 * @swagger
 * /services/{servicioId}/extintores:
 *   get:
 *     summary: Obtener extintores de un servicio
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
 *         example: 1
 *     responses:
 *       200:
 *         description: Lista de extintores del servicio
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *       400:
 *         description: Error en la solicitud
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 */
router.get('/:servicioId/extintores',authenticate,authorize(['tecnico']),ListController.listServicioExtintores)

/**
 * @swagger
 * /services/{servicioId}:
 *   get:
 *     summary: Obtener servicio por ID
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio
 *         example: 1
 *     responses:
 *       200:
 *         description: Servicio encontrado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     type:
 *                       type: string
 *                     dateStart:
 *                       type: string
 *                     status:
 *                       type: string
 *       400:
 *         description: servicioId inválido o faltante
 *       404:
 *         description: Servicio no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/:servicioId', authenticate, authorize(['tecnico']), ListController.getById)

export default router
