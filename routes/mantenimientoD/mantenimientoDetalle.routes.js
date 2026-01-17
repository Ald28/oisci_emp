import { Router } from 'express'
import { MantenimientoDetalleController } from '../../controllers/mantenimientoD/mantenimientoDetalle.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

/**
 * @swagger
 * /mantenimiento/services/extintores/{servicioExtintorId}/mantenimiento:
 *   get:
 *     summary: Obtener mantenimiento por servicioExtintorId
 *     tags:
 *       - Mantenimiento
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioExtintorId
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio de extintor
 *     responses:
 *       200:
 *         description: Mantenimiento encontrado
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
 *                     servicioExtintorId:
 *                       type: integer
 *                     mantenimiento:
 *                       type: boolean
 *                     recarga:
 *                       type: boolean
 *                     agenteCarga:
 *                       type: string
 *                     pruebaHidrostatica:
 *                       type: boolean
 *                     bajaExtintor:
 *                       type: boolean
 *                     motivoBaja:
 *                       type: string
 *                     pintura:
 *                       type: boolean
 *                     recargaCartucho:
 *                       type: boolean
 *                     cambioPartes:
 *                       type: boolean
 *                     detallesCambioPartes:
 *                       type: string
 *       404:
 *         description: Mantenimiento no encontrado
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get(
    '/services/extintores/:servicioExtintorId/mantenimiento',
    authenticate,
    authorize(['tecnico']),
    MantenimientoDetalleController.get
)

router.post('/services/extintores/:servicioExtintorId/mantenimiento',authenticate, authorize(['tecnico']),MantenimientoDetalleController.create)

export default router