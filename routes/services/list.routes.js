import { Router } from 'express'
import { ListController, getServiciosStatsBySedeYearController } from '../../controllers/services/list.controller.js'
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
router.get('/:servicioId/extintores', authenticate, authorize(['tecnico']), ListController.listServicioExtintores)

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

/**
 * @swagger
 * /services/serv-sede/{sedeId}:
 *   get:
 *     summary: Obtener servicios por sede
 *     description: Lista todos los servicios asociados a una sede específica
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sedeId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID de la sede
 *         example: 3
 *     responses:
 *       200:
 *         description: Lista de servicios de la sede
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
 *                         example: MANTENIMIENTO
 *                       dateStart:
 *                         type: string
 *                         format: date-time
 *                       dateEnd:
 *                         type: string
 *                         format: date-time
 *                         nullable: true
 *                       status:
 *                         type: string
 *                         example: EN_PROCESO
 *                       sede:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           name_sede:
 *                             type: string
 *                       user:
 *                         type: object
 *                         nullable: true
 *                         properties:
 *                           id:
 *                             type: integer
 *                           name:
 *                             type: string
 *                           email:
 *                             type: string
 *                       usuarioCreador:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           name:
 *                             type: string
 *                           email:
 *                             type: string
 *       400:
 *         description: sedeId inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/serv-sede/:sedeId', authenticate, authorize(['admin', 'user', 'tecnico']), ListController.getBySede)

router.get('/servicios/sede/:sedeId', authenticate, authorize(['admin', 'user', 'tecnico']), getServiciosStatsBySedeYearController)
/* /servicios/sede/1?year=2026 */

/**
 * @swagger
 * /services/sync/all:
 *   get:
 *     summary: Obtener todos los servicios con detalles completos para sincronización inicial
 *     description: Retorna todos los servicios con sus servicioExtintores, mantenimientoDetalle e inspeccionDetalle anidados
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista completa de servicios con todas sus relaciones
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
 *                       dateEnd:
 *                         type: string
 *                       status:
 *                         type: string
 *                       servicioExtintores:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: integer
 *                             mantenimientoDetalle:
 *                               type: object
 *                             inspeccionDetalle:
 *                               type: object
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/sync/all', authenticate, authorize(['admin', 'user', 'tecnico']), ListController.getAllWithDetails)

/**
 * @swagger
 * /services/sync/incremental:
 *   get:
 *     summary: Obtener servicios modificados después de un timestamp
 *     description: Para sincronización incremental. Retorna solo servicios y sus detalles creados o modificados después del timestamp proporcionado.
 *     tags:
 *       - Services
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
 *         description: Lista de servicios modificados con detalles
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
 *         description: Parámetro "since" faltante o inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get('/sync/incremental', authenticate, authorize(['admin', 'user', 'tecnico']), ListController.getUpdatedSince)

export default router
