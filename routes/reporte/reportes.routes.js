import { Router } from 'express'
import { reportesController } from '../../controllers/reporte/reportes.controller.js'

const router = Router()

/**
 * @swagger
 * /reporte/reportes:
 *   post:
 *     summary: Crear reporte de servicio
 *     tags: [Reporte Inspección]
 *     description: |
 *       Crea un reporte asociado a un servicio a partir de un archivo PDF previamente generado y almacenado en S3.
 *       
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           example:
 *             servicioId: 12
 *             tipo: "MENSUAL"
 *             pdfUrl: "https://mi-bucket.s3.amazonaws.com/reporte123.pdf"
 *           schema:
 *             type: object
 *             required:
 *               - servicioId
 *               - tipo
 *               - pdfUrl
 *             properties:
 *               servicioId:
 *                 type: integer
 *                 description: ID del servicio al que pertenece el reporte
 *                 example: 12
 *               tipo:
 *                 type: string
 *                 description: Tipo de reporte
 *                 example: MENSUAL
 *               pdfUrl:
 *                 type: string
 *                 description: URL del PDF almacenado en S3
 *                 example: https://mi-bucket.s3.amazonaws.com/reporte123.pdf
 *     responses:
 *       201:
 *         description: Reporte creado correctamente
 *         content:
 *           application/json:
 *             example:
 *               success: true
 *               message: Reporte creado correctamente
 *               data:
 *                 id: 10
 *                 servicioId: 12
 *                 tipo: MENSUAL
 *                 fechaEmision: "2026-04-06T18:00:00.000Z"
 *                 emitido: SI
 *                 archivoPdfUrl: https://mi-bucket.s3.amazonaws.com/reporte123.pdf
 *                 usuarioCreadorId: 1
 *                 createdAt: "2026-04-06T18:00:00.000Z"
 *                 updatedAt: "2026-04-06T18:00:00.000Z"
 *       400:
 *         description: Error en la solicitud
 *         content:
 *           application/json:
 *             examples:
 *               urlInvalida:
 *                 summary: URL inválida
 *                 value:
 *                   success: false
 *                   message: pdfUrl no es una URL válida
 *               noEsS3:
 *                 summary: URL no es de S3
 *                 value:
 *                   success: false
 *                   message: El archivo debe estar alojado en S3
 */

router.post('/reportes', reportesController.createReporte)

export default router