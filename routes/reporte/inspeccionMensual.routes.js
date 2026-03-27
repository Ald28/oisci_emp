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
 *         description: ID del servicio
 *         example: 9
 *     responses:
 *       200:
 *         description: Datos obtenidos correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 reporte:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       empresa:
 *                         type: string
 *                         example: EMPRESA SAC
 *                       ruc:
 *                         type: string
 *                         example: 20123456789
 *                       instalacion:
 *                         type: string
 *                         example: Sede Central
 *                       direccion:
 *                         type: string
 *                         example: Av. Perú 123
 *                       ciudad:
 *                         type: string
 *                         example: Lima
 *                       mes:
 *                         type: string
 *                         format: date-time
 *                         example: 2026-01-01T00:00:00.000-05:00
 *                       equipos:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             numero:
 *                               type: integer
 *                               example: 1
 *                             codigo:
 *                               type: string
 *                               example: EXT-001
 *                             capacidad:
 *                               type: string
 *                               example: 6 KG
 *                             tipo:
 *                               type: string
 *                               example: PQS
 *                             claseRating:
 *                               type: string
 *                               example: ABC
 *                             presionEquipo:
 *                               type: string
 *                               example: OPERATIVO
 *                             marca:
 *                               type: string
 *                               example: Amerex
 *                             modelo:
 *                               type: string
 *                               example: B500
 *                             numeroSerie:
 *                               type: string
 *                               example: NFC123456
 *                             numeroCilindro:
 *                               type: string
 *                               example: CIL-789
 *                             anioFabricacion:
 *                               type: integer
 *                               example: 2024
 *                             ph:
 *                               type: string
 *                               format: date-time
 *                               nullable: true
 *                               example: 2026-01-31T10:15:00.000-05:00
 *                             ubicacionEquipo:
 *                               type: string
 *                               example: Almacén
 *                             fechaVencMantto:
 *                               type: string
 *                               format: date-time
 *                               nullable: true
 *                               example: 2026-06-30T00:00:00.000-05:00
 *                             fechaPruebaHidro:
 *                               type: string
 *                               format: date-time
 *                               nullable: true
 *                               example: 2027-01-31T00:00:00.000-05:00
 *                             ubicadoNumeracion:
 *                               type: string
 *                               nullable: true
 *                             accesoLibre:
 *                               type: string
 *                               nullable: true
 *                             alturaAdecuada:
 *                               type: string
 *                               nullable: true
 *                             pictogramaUso:
 *                               type: string
 *                               nullable: true
 *                             pictogramaClase:
 *                               type: string
 *                               nullable: true
 *                             manometro:
 *                               type: string
 *                               nullable: true
 *                             precinto:
 *                               type: string
 *                               nullable: true
 *                             cilindroEstado:
 *                               type: string
 *                               nullable: true
 *                             indicaAgente:
 *                               type: string
 *                               nullable: true
 *                             colgador:
 *                               type: string
 *                               nullable: true
 *                             manija:
 *                               type: string
 *                               nullable: true
 *                             manguera:
 *                               type: string
 *                               nullable: true
 *                             tobera:
 *                               type: string
 *                               nullable: true
 *                             sujetador:
 *                               type: string
 *                               nullable: true
 *                             observaciones:
 *                               type: string
 *                               nullable: true
 *       400:
 *         description: Parámetro inválido
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       404:
 *         description: Servicio no encontrado
 *       500:
 *         description: Error interno
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