import { Router } from 'express'
import { ServiceEditController } from '../../controllers/services/serviceEdit.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * tags:
 *   name: Servicios - Edición
 *   description: Edición de servicios de inspección y mantenimiento
 */

/**
 * @swagger
 * /services/listar/{serviceId}/edit:
 *   get:
 *     tags: [Servicios - Edición]
 *     summary: Obtener servicio para edición
 *     description: |
 *       Devuelve el servicio con su sede y todos los extintores asociados,
 *       incluyendo detalles de inspección o mantenimiento.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 7
 *     responses:
 *       200:
 *         description: Servicio encontrado
 *       404:
 *         description: Servicio no encontrado
 */
router.get(
  '/listar/:serviceId/edit',
  authenticate,
  authorize(['admin']),
  ServiceEditController.getServiceForEdit
)

/**
 * @swagger
 * /services/extintores/{servicioExtintorId}/inspeccion:
 *   put:
 *     tags: [Servicios - Edición]
 *     summary: Editar inspección de un extintor
 *     description: |
 *       Permite editar las respuestas de inspección enviadas por el técnico.
 *       Al completarse, el extintor queda marcado como completado.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioExtintorId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 15
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               foto1Url: { type: string, example: https://img.com/f1.jpg }
 *               foto2Url: { type: string }
 *               foto3Url: { type: string }
 *               ubicacion: { type: string }
 *               accesibilidad: { type: string }
 *               instalacion: { type: string }
 *               instrucciones: { type: string }
 *               clasificacion: { type: string }
 *               recarga: { type: string }
 *               certificacion: { type: string }
 *               presion: { type: string }
 *               seguridad: { type: string }
 *               estado: { type: string }
 *               carga: { type: string }
 *               soporte: { type: string }
 *               activacion: { type: string }
 *               manguera: { type: string }
 *               boquilla: { type: string }
 *               abrazadera: { type: string }
 *               observaciones: { type: string }
 *     responses:
 *       200:
 *         description: Inspección actualizada correctamente
 *       400:
 *         description: Error de validación
 */
router.put(
  '/extintores/:servicioExtintorId/inspeccion',
  authenticate,
  authorize(['admin']),
  ServiceEditController.updateInspeccion
)

/**
 * @swagger
 * /services/extintores/{servicioExtintorId}/mantenimiento:
 *   put:
 *     tags: [Servicios - Edición]
 *     summary: Editar mantenimiento de un extintor
 *     description: |
 *       Permite registrar o corregir acciones de mantenimiento realizadas
 *       sobre un extintor. Al completarse, el extintor queda marcado como completado.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: servicioExtintorId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 15
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               mantenimiento: { type: boolean, example: true }
 *               recarga: { type: boolean }
 *               agenteCarga: { type: string }
 *               pruebaHidrostatica: { type: boolean }
 *               bajaExtintor: { type: boolean }
 *               motivoBaja: { type: string }
 *               pintura: { type: boolean }
 *               recargaCartucho: { type: boolean }
 *               cambioPartes: { type: boolean }
 *               detallesCambioPartes: { type: string }
 *     responses:
 *       200:
 *         description: Mantenimiento actualizado correctamente
 *       400:
 *         description: Error de validación
 */
router.put(
  '/extintores/:servicioExtintorId/mantenimiento',
  authenticate,
  authorize(['admin']),
  ServiceEditController.updateMantenimiento
)

/**
 * @swagger
 * /services/editar/{serviceId}/confirmar:
 *   put:
 *     tags: [Servicios - Edición]
 *     summary: Confirmar servicio
 *     description: |
 *       Finaliza el servicio solo si todos los extintores asociados
 *       están marcados como completados.
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: serviceId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 7
 *     responses:
 *       200:
 *         description: Servicio confirmado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Servicio confirmado correctamente
 *       400:
 *         description: Error de negocio
 */
router.put(
  '/editar/:serviceId/confirmar',
  authenticate,
  authorize(['admin']),
  ServiceEditController.confirmarServicio
)

export default router