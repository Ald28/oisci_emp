import { Router } from 'express'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'
import { ReporteMantenimientoAnualController } from '../../controllers/reporte/mantenimientoAnual.controller.js'

const router = Router()

/**
 * @swagger
 * tags:
 *   - name: Reporte Mantenimiento Anual
 *     description: Consulta y generación de fichas técnicas para servicios de tipo MANTENIMIENTO
 */

/**
 * @swagger
 * /reporte/mantenimientos-anuales:
 *   get:
 *     summary: Listar todos los servicios de mantenimiento anual
 *     description: |
 *       Retorna únicamente servicios cuyo tipo sea `MANTENIMIENTO`.
 *       Incluye empresa, sede, técnico asignado, extintores activos
 *       (`historic = 0`), mantenimiento, inspección y características técnicas.
 *     tags:
 *       - Reporte Mantenimiento Anual
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Servicios de mantenimiento obtenidos correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 total:
 *                   type: integer
 *                   example: 7
 *                 servicios:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 114
 *                       type:
 *                         type: string
 *                         enum: [MANTENIMIENTO]
 *                         example: MANTENIMIENTO
 *                       dateStart:
 *                         type: string
 *                         format: date-time
 *                       status:
 *                         type: string
 *                         example: FINALIZADO
 *                       sede:
 *                         type: object
 *                         description: Sede y cliente contratante
 *                       user:
 *                         type: object
 *                         description: Técnico asignado al servicio
 *                       servicioExtintores:
 *                         type: array
 *                         description: Extintores activos incluidos en el mantenimiento
 *                         items:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: integer
 *                             estadoFinal:
 *                               type: string
 *                               nullable: true
 *                             observaciones:
 *                               type: string
 *                               nullable: true
 *                             extintor:
 *                               type: object
 *                               description: Características técnicas del extintor
 *                             mantenimientoDetalle:
 *                               type: object
 *                               nullable: true
 *                               description: Servicios y componentes intervenidos
 *                             inspeccionDetalle:
 *                               type: object
 *                               nullable: true
 *                               description: Resultado de la inspección del equipo
 *       401:
 *         description: Token ausente o inválido
 *       403:
 *         description: El usuario no tiene rol admin o técnico
 *       500:
 *         description: Error al listar mantenimientos anuales
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
 *                   example: Error al listar mantenimientos anuales
 */
router.get(
    '/mantenimientos-anuales',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteMantenimientoAnualController.listar,
)

// Descarga global conservada para compatibilidad. No se publica en Swagger;
// la descarga documentada exige seleccionar un servicioId.
router.get(
    '/mantenimientos-anuales/download',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteMantenimientoAnualController.descargar,
)

/**
 * @swagger
 * /reporte/mantenimientos-anuales/{servicioId}:
 *   get:
 *     summary: Listar extintores de mantenimiento de una sede y servicio específicos
 *     description: Retorna únicamente los extintorId asociados al servicio MANTENIMIENTO indicado y cuya sedeId coincide con la sede del servicio.
 *     tags: [Reporte Mantenimiento Anual]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 114
 *     responses:
 *       200:
 *         description: Servicio y extintores asociados obtenidos correctamente
 *       400:
 *         description: servicioId inválido
 *       404:
 *         description: Servicio de mantenimiento no encontrado
 */
router.get(
    '/mantenimientos-anuales/:servicioId',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteMantenimientoAnualController.listar,
)

/**
 * @swagger
 * /reporte/mantenimientos-anuales/{servicioId}/download:
 *   get:
 *     operationId: descargarMantenimientoAnualPorServiceId
 *     summary: Descargar PDF por SERVICE ID
 *     description: |
 *       Escribe el `SERVICE ID` del mantenimiento y presiona **Execute**.
 *       Por ejemplo, con `114` Swagger llamará exactamente a:
 *       `http://localhost:8000/reporte/mantenimientos-anuales/114/download`.
 *       El PDF genera una página por cada extintor asociado al servicio e incluye
 *       la última inspección registrada para cada equipo.
 *     tags: [Reporte Mantenimiento Anual]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         description: SERVICE ID del servicio de tipo MANTENIMIENTO
 *         required: true
 *         schema:
 *           type: integer
 *           minimum: 1
 *           example: 114
 *     responses:
 *       200:
 *         description: PDF del servicio generado correctamente
 *         headers:
 *           Content-Disposition:
 *             description: Nombre del PDF descargado
 *             schema:
 *               type: string
 *               example: attachment; filename=mantenimiento-anual-servicio-114.pdf
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         description: servicioId inválido
 *       404:
 *         description: Servicio no encontrado o sin extintores asociados
 *       401:
 *         description: Token ausente o inválido
 *       403:
 *         description: El usuario no tiene rol admin o técnico
 *       500:
 *         description: Error al generar el PDF
 */
router.get(
    '/mantenimientos-anuales/:servicioId/download',
    authenticate,
    authorize(['admin', 'tecnico']),
    ReporteMantenimientoAnualController.descargar,
)

export default router
