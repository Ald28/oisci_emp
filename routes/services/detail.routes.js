import { Router } from "express";
import { CertificadoDataController } from "../../controllers/services/detail.controller.js";

const router = Router();

/**
 * @swagger
 * /services/{servicioId}/data/{tipo}:
 *   get:
 *     summary: Obtener datos para generar certificado
 *     tags:
 *       - Services
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *       - in: path
 *         name: tipo
 *         required: true
 *         schema:
 *           type: string
 *           enum: [OPER, HIDRO, BAJA]
 *     responses:
 *       200:
 *         description: Datos obtenidos correctamente
 */
router.get("/:servicioId/data/:tipo", CertificadoDataController.getData);

/**
 * @swagger
 * /services/{servicioId}/data/{tipo}/pdf:
 *   get:
 *     summary: Generar PDF del certificado
 *     description: Genera y devuelve un PDF del certificado usando los mismos datos del endpoint JSON. Solo aplica a servicios FINALIZADOS de tipo MANTENIMIENTO.
 *     tags:
 *       - Services
 *     parameters:
 *       - in: path
 *         name: servicioId
 *         required: true
 *         schema:
 *           type: integer
 *         example: 10
 *       - in: path
 *         name: tipo
 *         required: true
 *         schema:
 *           type: string
 *           enum: [OPER, HIDRO, BAJA]
 *         example: OPER
 *     responses:
 *       200:
 *         description: PDF generado correctamente
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       400:
 *         description: Parámetros inválidos o servicio no apto
 *       404:
 *         description: Servicio no encontrado
 *       500:
 *         description: Error interno del servidor
 */
router.get("/:servicioId/data/:tipo/pdf", CertificadoDataController.getPdf);

export default router;