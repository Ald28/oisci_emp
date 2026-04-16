import { Router } from 'express';
import { certificadosController } from '../../controllers/certificado/certificados.controller.js';

const router = Router();

/**
 * @swagger
 * tags:
 *   name: Certificado
 *   description: Endpoints relacionados a certificados
 */

/**
 * @swagger
 * /certificados/informacion:
 *   get:
 *     summary: Obtener lista de información de certificados
 *     tags: [Certificado]
 *     responses:
 *       200:
 *         description: Lista de información de certificados
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 1
 *                       nombre:
 *                         type: string
 *                         example: Certificado ABC
 *                       descripcion:
 *                         type: string
 *                         example: Información del certificado
 *       500:
 *         description: Error del servidor
 */
router.get('/informacion', certificadosController.listInformacion);

/**
 * @swagger
 * /certificados/informacion/{id}:
 *   get:
 *     summary: Obtener información de certificado por ID
 *     tags: [Certificado]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del certificado
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Información del certificado
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 ok:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     nombre:
 *                       type: string
 *                       example: Certificado ABC
 *                     descripcion:
 *                       type: string
 *                       example: Información detallada del certificado
 *       404:
 *         description: Certificado no encontrado
 *       500:
 *         description: Error del servidor
 */
router.get('/informacion/:id', certificadosController.getInformacionById);

export default router;