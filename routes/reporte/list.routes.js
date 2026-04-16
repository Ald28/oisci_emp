import { Router } from "express";
import { previewPdf } from "../../controllers/reporte/preview.controller.js";

const router = Router();

/**
 * @swagger
 * /reporte/ver/{id}/preview:
 *   get:
 *     summary: Visualizar PDF de reporte (stream desde S3)
 *     tags: [Reporte]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del reporte
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: PDF en stream
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       404:
 *         description: PDF no encontrado
 */
router.get("/ver/:id/preview", previewPdf);

export default router;