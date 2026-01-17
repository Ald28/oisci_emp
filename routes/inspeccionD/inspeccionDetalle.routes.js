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

/**
 * @swagger
 * /inspeccion/services/extintores/{servicioExtintorId}/inspeccion:
 *   post:
 *     summary: Crear o actualizar inspección con fotos y datos del checklist en una sola petición
 *     tags:
 *       - Inspección
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioExtintorId
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
 *             required:
 *               - servicioExtintorId
 *               - data
 *             properties:
 *               servicioExtintorId:
 *                 type: integer
 *                 example: 1
 *               foto1:
 *                 type: string
 *                 format: binary
 *                 description: Primera foto (opcional)
 *               foto2:
 *                 type: string
 *                 format: binary
 *                 description: Segunda foto (opcional)
 *               foto3:
 *                 type: string
 *                 format: binary
 *                 description: Tercera foto (opcional)
 *               data:
 *                 type: string
 *                 description: JSON stringificado con los datos del checklist
 *                 example: '{"visibilidad":"BUENA","accesibilidad":"LIBRE","altura":"CORRECTA","peso":"OK","observaciones":"Extintor operativo","situacion":"Activo","conservacion":"Buena"}'
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
router.post(
    '/services/extintores/:servicioExtintorId/inspeccion',
    upload.fields([
        { name: 'foto1', maxCount: 1 },
        { name: 'foto2', maxCount: 1 },
        { name: 'foto3', maxCount: 1 },
    ]),
    authenticate,
    authorize(['tecnico']),
    controller.createOrUpdateInspeccionWithFotos
)

/**
 * @swagger
 * /inspeccion/extintores/{servicioExtintorId}/inspeccion:
 *   put:
 *     summary: Actualizar inspección con fotos y datos del checklist en una sola petición
 *     tags:
 *       - Inspección
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioExtintorId
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
 *             required:
 *               - data
 *             properties:
 *               foto1:
 *                 type: string
 *                 format: binary
 *                 description: Primera foto (opcional)
 *               foto2:
 *                 type: string
 *                 format: binary
 *                 description: Segunda foto (opcional)
 *               foto3:
 *                 type: string
 *                 format: binary
 *                 description: Tercera foto (opcional)
 *               data:
 *                 type: string
 *                 description: JSON stringificado con los datos del checklist
 *                 example: '{"visibilidad":"BUENA","accesibilidad":"LIBRE","altura":"CORRECTA","peso":"OK","observaciones":"Extintor operativo","situacion":"Activo","conservacion":"Buena"}'
 *     responses:
 *       200:
 *         description: Inspección actualizada correctamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.put(
    '/extintores/:servicioExtintorId/inspeccion',
    upload.fields([
        { name: 'foto1', maxCount: 1 },
        { name: 'foto2', maxCount: 1 },
        { name: 'foto3', maxCount: 1 },
    ]),
    authenticate,
    authorize(['tecnico']),
    controller.createOrUpdateInspeccionWithFotos
)

/**
 * @swagger
 * /inspeccion/services/extintores/{servicioExtintorId}/inspeccion:
 *   get:
 *     summary: Obtener inspección por servicioExtintorId
 *     tags:
 *       - Inspección
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
 *         description: Inspección encontrada
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
 *                     foto1Url:
 *                       type: string
 *                     foto2Url:
 *                       type: string
 *                     foto3Url:
 *                       type: string
 *                     visibilidad:
 *                       type: string
 *                     visualizacion:
 *                       type: string
 *                     accesibilidad:
 *                       type: string
 *                     altura:
 *                       type: string
 *                     situacion:
 *                       type: string
 *                     conservacion:
 *                       type: string
 *                     inscripciones:
 *                       type: string
 *                     recorrido:
 *                       type: string
 *                     peso:
 *                       type: string
 *                     observaciones:
 *                       type: string
 *       404:
 *         description: Inspección no encontrada
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get(
    '/services/extintores/:servicioExtintorId/inspeccion',
    authenticate,
    authorize(['tecnico']),
    controller.getInspeccionByServicioExtintorId
)

export default router