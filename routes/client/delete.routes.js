import { Router } from 'express'
import { deleteClient, restoreClient } from '../../controllers/client/delete.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /users/clients/{id}:
 *   delete:
 *     summary: Eliminar cliente
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del cliente
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Cliente eliminado correctamente
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: No tiene permisos de administrador
 *       404:
 *         description: Cliente no encontrado
 */
router.delete('/clients/:id', authenticate, authorize(['admin']), deleteClient)

/**
 * @swagger
 * /users/clients/{id}/restore:
 *   patch:
 *     summary: Restaurar cliente eliminado
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         description: ID del cliente
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Cliente restaurado correctamente
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: No tiene permisos de administrador
 *       404:
 *         description: Cliente no encontrado
 */
router.patch('/clients/:id/restore', authenticate, authorize(['admin']), restoreClient)

export default router