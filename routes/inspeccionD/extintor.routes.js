import express from "express";
import {
  listExtintores,
  getExtintor,
  exportExtintoresExcel,
} from "../../controllers/inspeccionD/extintor.controller.js";
import {
  softDeleteExtintorController,
  restoreExtintorController,
} from "../../controllers/inspeccionD/delete.controller.js";
import { authenticate, authorize } from "../../middleware/auth.middleware.js";

const router = express.Router();
/**
 * @swagger
 * tags:
 *   - name: Reporte Inspección
 *     description: API para reportes de inspección de extintores
 */

/**
 * @swagger
 * /extintores/info:
 *   get:
 *     summary: Listar extintores con información de inspección
 *     tags: [Reporte Inspección]
 *     responses:
 *       200:
 *         description: Lista de extintores con inspecciones
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                   codigo:
 *                     type: string
 *                   foto:
 *                     type: string
 *                   empresa:
 *                     type: string
 *                   sede:
 *                     type: string
 *                   inspecciones:
 *                     type: array
 *                     items:
 *                       type: object
 *                       properties:
 *                         fecha:
 *                           type: string
 *                           format: date-time
 *                         fotos:
 *                           type: array
 *                           items:
 *                             type: string
 *                         observaciones:
 *                           type: string
 *       500:
 *         description: Error del servidor
 */
router.get("/info", listExtintores);

/**
 * @swagger
 * /extintores/pdf:
 *   get:
 *     summary: Obtener data completa para generar PDF de inspección
 *     tags: [Reporte Inspección]
 *     parameters:
 *       - in: query
 *         name: extintorId
 *         schema:
 *           type: integer
 *         required: false
 *         description: ID del extintor (opcional para filtrar uno específico)
 *     responses:
 *       200:
 *         description: Data completa del extintor para PDF
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 codigo:
 *                   type: string
 *                 tipo:
 *                   type: string
 *                 capacidad:
 *                   type: string
 *                 empresa:
 *                   type: string
 *                 sede:
 *                   type: string
 *                 inspecciones:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       fecha:
 *                         type: string
 *                         format: date-time
 *                       checklist:
 *                         type: object
 *                         properties:
 *                           ubicacion:
 *                             type: string
 *                           accesibilidad:
 *                             type: string
 *                           presion:
 *                             type: string
 *                           manguera:
 *                             type: string
 *                       fotos:
 *                         type: array
 *                         items:
 *                           type: string
 *                       observaciones:
 *                         type: string
 *                 mantenimientos:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       fecha:
 *                         type: string
 *                         format: date-time
 *                       checklist:
 *                         type: object
 *                         properties:
 *                           mantenimiento:
 *                             type: boolean
 *                           recarga:
 *                             type: boolean
 *                           pintura:
 *                             type: boolean
 *                       observaciones:
 *                         type: string
 *       500:
 *         description: Error del servidor
 */
router.get("/pdf", getExtintor);

/**
 * @swagger
 * /extintores/excel:
 *   get:
 *     summary: Descargar extintores en formato Excel o PDF
 *     description: |
 *       Exporta extintores por servicio o por extintor en formato Excel (por defecto) o PDF.
 *
 *       Ejemplos en local:
 *       - http://localhost:8000/extintores/excel?serviceId=3
 *       - http://localhost:8000/extintores/excel?format=pdf&serviceId=6
 *
 *       Ejemplos en servidor:
 *       - https://api.aldosanchez.es/extintores/excel?serviceId=3
 *       - https://api.aldosanchez.es/extintores/excel?format=pdf&serviceId=6
 *     tags: [Reporte Inspección]
 *     parameters:
 *       - in: query
 *         name: extintorId
 *         schema:
 *           type: integer
 *         required: false
 *         description: ID del extintor para exportar un registro en específico
 *       - in: query
 *         name: serviceId
 *         schema:
 *           type: integer
 *         required: false
 *         description: ID del servicio para exportar únicamente los extintores asociados a ese servicio
 *         example: 6
 *       - in: query
 *         name: format
 *         schema:
 *           type: string
 *           enum: [excel, pdf]
 *         required: false
 *         description: Formato de descarga (por defecto excel)
 *         example: pdf
 *     responses:
 *       200:
 *         description: Archivo generado
 *         content:
 *           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet:
 *             schema:
 *               type: string
 *               format: binary
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       500:
 *         description: Error del servidor
 */
router.get("/excel", exportExtintoresExcel);

/**
 * @swagger
 * /extintores/soft-delete/{id}:
 *   delete:
 *     summary: Desactivar (soft delete) un extintor
 *     tags: [Reporte Inspección]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         description: ID del extintor a desactivar
 *         required: true
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Extintor desactivado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     historic:
 *                       type: integer
 *                       example: 1
 *       400:
 *         description: ID inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       404:
 *         description: Extintor no encontrado
 */
router.delete(
  "/soft-delete/:id",
  authenticate,
  authorize(["admin"]),
  softDeleteExtintorController,
);

/**
 * @swagger
 * /extintores/restore/{id}:
 *   patch:
 *     summary: Restaurar un extintor desactivado
 *     tags: [Reporte Inspección]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         description: ID del extintor a restaurar
 *         required: true
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Extintor restaurado correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     historic:
 *                       type: integer
 *                       example: 0
 *       400:
 *         description: ID inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       404:
 *         description: Extintor no encontrado
 */
router.patch(
  "/restore/:id",
  authenticate,
  authorize(["admin"]),
  restoreExtintorController,
);

export default router;
