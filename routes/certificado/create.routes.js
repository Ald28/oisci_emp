import { Router } from 'express'
import { CertificadoController } from '../../controllers/certificado/create.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /certificado/create:
 *   post:
 *     summary: Crear certificado de servicio
 *     description: >
 *       Crea un certificado asociado a un servicio, incluyendo el checklist
 *       y estado final de cada extintor.
 *     tags:
 *       - Certificado
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - tipo
 *               - clientId
 *               - sedeId
 *               - servicioId
 *               - frecuencia
 *               - extintores
 *             properties:
 *               tipo:
 *                 type: string
 *                 enum: [OPER, HIDRO, BAJA]
 *                 example: OPER
 *               clientId:
 *                 type: integer
 *                 example: 1
 *               sedeId:
 *                 type: integer
 *                 example: 2
 *               servicioId:
 *                 type: integer
 *                 example: 12
 *               frecuencia:
 *                 type: string
 *                 example: ANUAL
 *               extintores:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - extintorId
 *                     - estado
 *                     - checklist
 *                   properties:
 *                     extintorId:
 *                       type: integer
 *                       example: 10
 *                     estado:
 *                       type: string
 *                       enum: [OPERATIVO, INOPERATIVO]
 *                       example: OPERATIVO
 *                     checklist:
 *                       type: object
 *                       additionalProperties: true
 *                       example:
 *                         presion: true
 *                         manguera: true
 *                         boquilla: true
 *     responses:
 *       201:
 *         description: Certificado creado correctamente
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       500:
 *         description: Error interno
 */
router.post(
    '/create',
    authenticate,
    authorize(['admin']),
    CertificadoController.create
)

/**
 * @swagger
 * /certificado/{id}/pdf:
 *   put:
 *     summary: Subir o actualizar PDF del certificado
 *     description: >
 *       Guarda la URL del PDF generado y marca el certificado como emitido.
 *     tags:
 *       - Certificado
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 2
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - archivoPdfUrl
 *             properties:
 *               archivoPdfUrl:
 *                 type: string
 *                 example: https://cdn.miapp.com/certificados/OPER-2026-000002.pdf
 *     responses:
 *       200:
 *         description: PDF guardado correctamente
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       500:
 *         description: Error interno
 */
router.put(
    '/:id/pdf',
    authenticate,
    authorize(['admin']),
    CertificadoController.subirPdf
)

/**
 * @swagger
 * /certificado/{servicioId}:
 *   get:
 *     summary: Obtener reporte fotográfico por servicio
 *     description: >
 *       Devuelve la información necesaria para generar el PDF del reporte
 *       fotográfico del servicio, ordenado por extintor y fecha.
 *     tags:
 *       - Certificado
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 12
 *     responses:
 *       200:
 *         description: Reporte fotográfico obtenido
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
 *                       extintorId:
 *                         type: integer
 *                       codeExtintor:
 *                         type: string
 *                       serialNumberNFC:
 *                         type: string
 *                       type:
 *                         type: string
 *                       location:
 *                         type: string
 *                       fotos:
 *                         type: array
 *                         items:
 *                           type: string
 *                       comentarios:
 *                         type: string
 *                       fechaHora:
 *                         type: string
 *                         format: date-time
 *       401:
 *         description: No autorizado
 *       403:
 *         description: Sin permisos
 *       500:
 *         description: Error interno
 */
router.get(
    '/preview',
    CertificadoController.previewImagen
)

router.get(
    '/:servicioId',
    authenticate,
    authorize(['admin', 'tecnico']),
    CertificadoController.obtenerReporte
)

export default router