import { Router } from 'express'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'
import { ReporteInspeccionMensualController } from '../../controllers/reporte/inspeccionMensual.controller.js'

const router = Router()

/**
 * @swagger
 * /reporte/inspeccion-mensual/{servicioId}:
 *   get:
 *     summary: Obtener datos de inspección mensual
 *     tags:
 *       - Reporte Inspección Mensual
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Datos obtenidos correctamente
 */
router.get(
    '/inspeccion-mensual/:servicioId',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteInspeccionMensualController.obtener
)

 /**
 * @swagger
 * /reporte/inspeccion-mensual/{servicioId}/download:
 *   get:
 *     summary: Descargar reporte mensual en PDF
 *     tags:
 *       - Reporte Inspección Mensual
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: PDF generado correctamente
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 */

router.get(
    '/inspeccion-mensual/:servicioId/download',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteInspeccionMensualController.descargar
)

export default router