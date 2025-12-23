import { Router } from 'express';
import { softDeleteSedeController, restoreSedeController } from '../../controllers/sede/delete.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

/**
 * @swagger
 * /sede/soft-delete/{id}:
 *   delete:
 *     summary: Desactivar (soft delete) una sede
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         description: ID de la sede a desactivar
 *         required: true
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Sede desactivada correctamente
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
 *                     active:
 *                       type: boolean
 *                       example: false
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
router.delete(
    '/soft-delete/:id',
    authenticate,
    authorize(['admin']),
    softDeleteSedeController
);

/**
 * @swagger
 * /sede/restore/{id}:
 *   patch:
 *     summary: Restaurar una sede desactivada
 *     tags:
 *       - Sede
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         description: ID de la sede a restaurar
 *         required: true
 *         schema:
 *           type: integer
 *           example: 1
 *     responses:
 *       200:
 *         description: Sede restaurada correctamente
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
router.patch(
    '/restore/:id',
    authenticate,
    authorize(['admin']),
    restoreSedeController
);

export default router;