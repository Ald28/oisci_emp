import { Router } from 'express'
import upload from '../../middleware/upload.middleware.js'
import controller from '../../controllers/inspeccionD/inspeccionDetalle.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

/**
 * @swagger
 * /inspeccion/{id}/fotos:
 *   post:
 *     summary: Subir fotos de inspección para un extintor
 *     tags:
 *       - Inspección
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID del servicio de extintor
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               fotos:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: Imágenes del extintor (máx. 3)
 *     responses:
 *       200:
 *         description: Fotos subidas correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 foto1Url:
 *                   type: string
 *                 foto2Url:
 *                   type: string
 *                 foto3Url:
 *                   type: string
 *       400:
 *         description: No se enviaron imágenes o datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.post('/:id/fotos', upload.array('fotos', 3), authenticate, authorize(['tecnico']), controller.uploadFotosInspeccion)

/**
 * @swagger
 * /inspeccion:
 *   post:
 *     summary: Crear o actualizar inspección de extintor
 *     tags:
 *       - Inspección
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - servicioExtintorId
 *             properties:
 *               servicioExtintorId:
 *                 type: integer
 *                 example: 1
 *               visibilidad:
 *                 type: string
 *                 example: "BUENA"
 *               accesibilidad:
 *                 type: string
 *                 example: "LIBRE"
 *               altura:
 *                 type: string
 *                 example: "CORRECTA"
 *               peso:
 *                 type: string
 *                 example: "OK"
 *               observaciones:
 *                 type: string
 *                 example: "Extintor operativo"
 *               situacion:
 *                 type: string
 *                 example: "Activo"
 *               conservacion:
 *                 type: string
 *                 example: "Buena"
 *     responses:
 *       200:
 *         description: Inspección creada o actualizada correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                 servicioExtintorId:
 *                   type: integer
 *                 visibilidad:
 *                   type: string
 *                 accesibilidad:
 *                   type: string
 *                 altura:
 *                   type: string
 *                 peso:
 *                   type: string
 *                 observaciones:
 *                   type: string
 *                 foto1Url:
 *                   type: string
 *                 foto2Url:
 *                   type: string
 *                 foto3Url:
 *                   type: string
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.post('/', authenticate, authorize(['tecnico']), controller.createOrUpdateInspeccion)

export default router