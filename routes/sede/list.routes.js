import { Router } from 'express';
import { getSedeByIdController, listSedeController, searchSedeByClientController } from '../../controllers/sede/list.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @swagger
 * /sede/list-sedes:
 *   get:
 *     summary: Listar todas las sedes
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de sedes
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
 *                       name_sede:
 *                         type: string
 *                         example: Sede Central
 *                       address:
 *                         type: string
 *                         example: Av. Principal 123
 *                       city:
 *                         type: string
 *                         example: Lima
 *                       active:
 *                         type: boolean
 *                         example: true
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       500:
 *         description: Error interno del servidor
 */
router.get(
    '/list-sedes',
    authenticate,
    authorize(['admin', 'user', 'tecnico']),
    listSedeController
);

/**
 * @swagger
 * /sede/list-sede/{id}:
 *   get:
 *     summary: Obtener una sede por ID
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 1
 *     responses:
 *       200:
 *         description: Sede encontrada
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
 *                     name_sede:
 *                       type: string
 *                       example: Sede Central
 *                     address:
 *                       type: string
 *                       example: Av. Principal 123
 *                     city:
 *                       type: string
 *                       example: Lima
 *                     active:
 *                       type: boolean
 *                       example: true
 *       400:
 *         description: ID inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       404:
 *         description: Sede no encontrada
 *       500:
 *         description: Error interno del servidor
 */
router.get(
    '/list-sede/:id',
    authenticate,
    authorize(['admin', 'user']),
    getSedeByIdController
);

/**
 * @swagger
 * /sede/search-by-client/{id}:
 *   get:
 *     summary: Buscar sedes por ID de cliente
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         example: 1
 *     responses:
 *       200:
 *         description: Sedes encontradas para el cliente
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
 *                       name_sede:
 *                         type: string
 *                         example: Sede Central
 *                       address:
 *                         type: string
 *                         example: Av. Principal 123
 *                       city:
 *                         type: string
 *                         example: Lima
 *                       active:
 *                         type: boolean
 *                         example: true
 *       400:
 *         description: ID inválido
 *       401:
 *         description: No autenticado
 *       403:
 *         description: No autorizado
 *       404:
 *         description: No se encontraron sedes para el cliente
 *       500:
 *         description: Error interno del servidor
 */

router.get(
    '/search-by-client/:id',
    authenticate,
    authorize(['admin', 'user']),
    searchSedeByClientController
);

export default router;