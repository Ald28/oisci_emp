import { Router } from 'express'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'
import { ReporteInspeccionController } from '../../controllers/reporte/inspeccion.controller.js'

const router = Router()

/**
 * @swagger
 * /reporte/fotografico/{servicioId}:
 *   get:
 *     summary: Obtener reporte de inspección por servicio
 *     description: >
 *       Devuelve toda la información necesaria para generar el PDF del
 *       reporte de inspección: estados finales por extintor, checklist
 *       dinámico y fecha/hora de inspección.
 *     tags:
 *       - Reporte Inspección
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 9
 *     responses:
 *       200:
 *         description: Reporte de inspección obtenido correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 reporte:
 *                   type: object
 *                   properties:
 *                     servicio:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                         tipo:
 *                           type: string
 *                           example: INSPECCION
 *                         fechaInicio:
 *                           type: string
 *                           format: date-time
 *                         fechaFin:
 *                           type: string
 *                           format: date-time
 *                     cliente:
 *                       type: object
 *                       properties:
 *                         razonSocial:
 *                           type: string
 *                           example: EMPRESA SAC
 *                         ruc:
 *                           type: string
 *                           example: 20123456789
 *                     sede:
 *                       type: object
 *                       properties:
 *                         nombre:
 *                           type: string
 *                         direccion:
 *                           type: string
 *                         ciudad:
 *                           type: string
 *                     equipos:
 *                       type: array
 *                       description: Lista de extintores inspeccionados
 *                       items:
 *                         type: object
 *                         properties:
 *                           extintorId:
 *                             type: integer
 *                           codigo:
 *                             type: string
 *                             example: EXT-001
 *                           tipo:
 *                             type: string
 *                             example: PQS
 *                           ubicacion:
 *                             type: string
 *                             example: Almacén
 *                           estadoFinal:
 *                             type: string
 *                             enum: [OPERATIVO, INOPERATIVO]
 *                           checklist:
 *                             type: object
 *                             description: Checklist dinámico de inspección
 *                             additionalProperties:
 *                               type: string
 *                             example:
 *                               presion: OK
 *                               manguera: OK
 *                               boquilla: OK
 *                           observaciones:
 *                             type: string
 *                             example: Sin novedades
 *                           fechaHora:
 *                             type: string
 *                             format: date-time
 *                             example: 2026-01-31T10:15:00.000Z
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       500:
 *         description: Error interno
 */
router.get(
    '/fotografico/:servicioId',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteInspeccionController.obtenerReporte
)

/**
 * @swagger
 * /reporte/fotografico/{servicioId}/download:
 *   get:
 *     summary: Descargar certificado PDF de inspección
 *     description: >
 *       Genera y descarga el certificado en formato PDF con toda la
 *       información de la inspección y fotografías de los equipos.
 *     tags:
 *       - Reporte Inspección
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 26
 *     responses:
 *       200:
 *         description: PDF generado correctamente
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       404:
 *         description: Servicio no encontrado
 *       500:
 *         description: Error interno al generar PDF
 */
router.get(
    '/fotografico/:servicioId/download',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteInspeccionController.descargarCertificado
)

export default router