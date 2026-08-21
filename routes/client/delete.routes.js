import { Router } from 'express'
import { deleteClient, restoreClient } from '../../controllers/client/delete.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /users/clients/{id}:
 *   delete:
 *     summary: Desactivar cliente y todas sus sedes
 *     description: |
 *       Realiza un borrado lógico dentro de una transacción:
 *       establece `Client.active = false` y desactiva todas las sedes
 *       relacionadas mediante `Sede.active = false`.
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
 *         description: Cliente y sedes desactivados correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Cliente eliminado correctamente
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     active:
 *                       type: boolean
 *                       example: false
 *                     sedesDesactivadas:
 *                       type: integer
 *                       description: Cantidad de sedes activas que fueron desactivadas
 *                       example: 2
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
 *     summary: Activar cliente y todas sus sedes
 *     description: |
 *       Revierte el borrado lógico dentro de una transacción:
 *       establece `Client.active = true` y activa todas las sedes
 *       relacionadas mediante `Sede.active = true`.
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
 *         description: Cliente y sedes activados correctamente
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Cliente restaurado correctamente
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     active:
 *                       type: boolean
 *                       example: true
 *                     sedesActivadas:
 *                       type: integer
 *                       description: Cantidad de sedes inactivas que fueron activadas
 *                       example: 2
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: No tiene permisos de administrador
 *       404:
 *         description: Cliente no encontrado
 */
router.patch('/clients/:id/restore', authenticate, authorize(['admin']), restoreClient)

export default router
