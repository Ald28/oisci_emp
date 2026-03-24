import { Router } from "express";
import { CertificadoDataController } from "../../controllers/inspeccionD/detail.controller.js";

const router = Router();

/**
 * @swagger
 * /services/{servicioId}/inspection/data:
 *   get:
 *     summary: Obtener datos del reporte de inspección
 *     description: Retorna los datos del cliente, sede, servicio y extintores relacionados para un servicio de tipo INSPECCION y estado FINALIZADO.
 *     tags:
 *       - Services
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 10
 *     responses:
 *       200:
 *         description: Datos del reporte obtenidos correctamente
 *       400:
 *         description: Servicio inválido o no apto
 *       404:
 *         description: Servicio no encontrado
 *       500:
 *         description: Error interno del servidor
 */
router.get("/:servicioId/inspection/data", CertificadoDataController.getData);

/**
 * @swagger
 * /services/{servicioId}/inspection/pdf:
 *   get:
 *     summary: Generar PDF del reporte de inspección
 *     description: Genera y devuelve un PDF del reporte para servicios de tipo INSPECCION y estado FINALIZADO.
 *     tags:
 *       - Services
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 10
 *     responses:
 *       200:
 *         description: PDF generado correctamente
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         description: Servicio inválido o no apto
 *       404:
 *         description: Servicio no encontrado
 *       500:
 *         description: Error interno del servidor
 */
router.get("/:servicioId/inspection/pdf", CertificadoDataController.getPdf);

export default router;