import { Router } from 'express'
import { ApprovedController } from '../../controllers/services/approved.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

/**
 * @swagger
 * /services/{serviceId}/review:
 *   get:
 *     summary: Obtener información completa de un servicio para revisión
 *     description: Retorna el servicio con sede, usuario, extintores asociados, detalles de mantenimiento/inspección y el historial de cada extintor.
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio a revisar
 *         example: 10
 *     responses:
 *       200:
 *         description: Servicio listo para revisión
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                 type:
 *                   type: string
 *                 dateStart:
 *                   type: string
 *                   format: date-time
 *                 status:
 *                   type: string
 *                 sede:
 *                   type: object
 *                 user:
 *                   type: object
 *                 servicioExtintores:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                       estadoFinal:
 *                         type: string
 *                         nullable: true
 *                       extintor:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           codigo:
 *                             type: string
 *                           historial:
 *                             type: array
 *                             items:
 *                               type: object
 *                               properties:
 *                                 servicio:
 *                                   type: object
 *                                   properties:
 *                                     id:
 *                                       type: integer
 *                                     type:
 *                                       type: string
 *                                     dateStart:
 *                                       type: string
 *                                     statusValid:
 *                                       type: string
 *       400:
 *         description: Servicio no encontrado o error en la solicitud
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado (solo admin)
 */
router.get('/:serviceId/review', authenticate, authorize(['admin']), ApprovedController.getReview)

/**
 * @swagger
 * /services/{serviceId}/approve:
 *   put:
 *     summary: Aprobar un servicio
 *     description: Aprueba un servicio, actualiza el estado final del servicio y sincroniza el estado de los extintores según el estadoFinal definido.
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio a aprobar
 *         example: 10
 *     requestBody:
 *       required: false
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               comentario:
 *                 type: string
 *                 description: Comentario opcional del aprobador
 *                 example: Servicio verificado y conforme
 *     responses:
 *       200:
 *         description: Servicio aprobado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Servicio aprobado
 *                 result:
 *                   type: object
 *       400:
 *         description: Servicio no encontrado o error en la aprobación
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado (solo admin)
 */
router.put('/:serviceId/approve', authenticate, authorize(['admin']), ApprovedController.approve)

/**
 * @swagger
 * /services/{serviceId}/reject:
 *   put:
 *     summary: Rechazar un servicio
 *     description: Rechaza un servicio. El comentario es obligatorio y queda registrado en el historial del servicio.
 *     tags:
 *       - Services
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio a rechazar
 *         example: 10
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - comentario
 *             properties:
 *               comentario:
 *                 type: string
 *                 description: Motivo del rechazo
 *                 example: Falta evidencia fotográfica del mantenimiento
 *     responses:
 *       200:
 *         description: Servicio rechazado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Servicio rechazado
 *                 result:
 *                   type: object
 *       400:
 *         description: El comentario es obligatorio o servicio no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado (solo admin)
 */
router.put('/:serviceId/reject', authenticate, authorize(['admin']), ApprovedController.reject)

export default router