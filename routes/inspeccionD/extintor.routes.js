import express from "express";
import {
  listExtintores,
  getExtintor,
} from "../../controllers/inspeccionD/extintor.controller.js";

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

export default router;
