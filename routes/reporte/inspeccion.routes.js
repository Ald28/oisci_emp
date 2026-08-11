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
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       servicio:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           tipo:
 *                             type: string
 *                             example: INSPECCION
 *                           fechaInicio:
 *                             type: string
 *                             format: date-time
 *                           fechaFin:
 *                             type: string
 *                             format: date-time
 *                       cliente:
 *                         type: object
 *                         properties:
 *                           razonSocial:
 *                             type: string
 *                             example: EMPRESA SAC
 *                           ruc:
 *                             type: string
 *                             example: 20123456789
 *                       sede:
 *                         type: object
 *                         properties:
 *                           nombre:
 *                             type: string
 *                           direccion:
 *                             type: string
 *                           ciudad:
 *                             type: string
 *                       equipos:
 *                         type: array
 *                         description: Lista de extintores inspeccionados
 *                         items:
 *                           type: object
 *                           properties:
 *                             extintorId:
 *                               type: integer
 *                             codigo:
 *                               type: string
 *                               example: EXT-001
 *                             tipo:
 *                               type: string
 *                               example: PQS
 *                             ubicacion:
 *                               type: string
 *                               example: Almacén
 *                             estadoFinal:
 *                               type: string
 *                               enum: [OPERATIVO, INOPERATIVO]
 *                             fotos:
 *                               type: object
 *                               nullable: true
 *                               properties:
 *                                 foto1Url:
 *                                   type: string
 *                                   nullable: true
 *                                 foto2Url:
 *                                   type: string
 *                                   nullable: true
 *                                 foto3Url:
 *                                   type: string
 *                                   nullable: true
 *                             checklist:
 *                               type: object
 *                               nullable: true
 *                               description: Checklist dinámico de inspección
 *                               additionalProperties:
 *                                 type: string
 *                               example:
 *                                 ubicacion: OK
 *                                 accesibilidad: OK
 *                                 instalacion: OK
 *                                 instrucciones: OK
 *                                 clasificacion: OK
 *                                 presion: OK
 *                                 seguridad: OK
 *                                 estado: OK
 *                                 carga: OK
 *                                 soporte: OK
 *                                 activacion: OK
 *                                 manguera: OK
 *                                 boquilla: OK
 *                                 abrazadera: OK
 *                             observaciones:
 *                               type: string
 *                               nullable: true
 *                               example: Sin novedades
 *                             fechaHora:
 *                               type: string
 *                               format: date-time
 *                               nullable: true
 *                               example: 2026-01-31T10:15:00.000-05:00
 *       400:
 *         description: Parámetro inválido
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       404:
 *         description: Reporte no encontrado
 *       500:
 *         description: Error interno
 */
router.get(
    '/fotografico/:servicioId',
    ReporteInspeccionController.obtenerReporte
)

/**
 * @swagger
 * /reporte/fotografico/{servicioId}/download:
 *   get:
 *     summary: Descargar certificado fotográfico PDF de inspección
 *     description: |
 *       Genera y descarga el certificado en formato PDF con toda la
 *       información de la inspección y fotografías de los equipos.
 *
 *       Ejemplo en local:
 *       - http://localhost:8000/reporte/fotografico/6/download
 *
 *       Ejemplo en servidor:
 *       - https://api.aldosanchez.es/reporte/fotografico/6/download
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
    ReporteInspeccionController.descargarCertificado
)

/**
 * @swagger
 * /reporte/fotografico/{servicioId}/download-servicio:
 *   get:
 *     summary: Descargar certificado unificado general de 3 paginas por servicio en un solo PDF
 *     description: |
 *       Genera un solo PDF con tres secciones dentro del mismo documento:
 *       Integridad/Mantenimiento, Prueba Hidrostática y Extintores dados de Baja.
 *       Cada sección se pagina de 10 en 10 según la cantidad de extintores.
 *
 *       Ejemplo en local:
 *       - http://localhost:8000/reporte/fotografico/13/download-servicio
 *
 *       Ejemplo en servidor:
 *       - https://api.aldosanchez.es/reporte/fotografico/13/download-servicio
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
 *         example: 16
 *     responses:
 *       200:
 *         description: PDF unificado generado correctamente
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
    '/fotografico/:servicioId/download-servicio',
    ReporteInspeccionController.descargarCertificadoServicio
)

/**
 * @swagger
 * /reporte/fotografico/{servicioId}/download-pdf:
 *   get:
 *     summary: Descargar certificado BAJA/HIDRO/OPER en formato pdf
 *     description: |
 *       Genera y descarga el certificado en PDF con formato de certificado
 *       (encabezado, tabla y texto normativo) según la plantilla del servicio.
 *
 *       Ejemplo en local:
 *       - http://localhost:8000/reporte/fotografico/1/download-pdf
 *
 *       Ejemplo en servidor:
 *       - https://api.aldosanchez.es/reporte/fotografico/1/download-pdf
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
    '/fotografico/:servicioId/download-pdf',
    ReporteInspeccionController.descargarWord
)

export default router