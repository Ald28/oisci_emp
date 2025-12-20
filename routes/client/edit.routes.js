import { Router } from 'express'
import { editClientAndUser } from '../../controllers/client/edit.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /users/clients/{id}:
 *   put:
 *     summary: Editar cliente y usuario asociado
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
 *           example: 2
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               razonSocial:
 *                 type: string
 *                 example: Empresa SAC
 *               ruc:
 *                 type: string
 *                 example: 12345678901
 *               phone:
 *                 type: string
 *                 example: 999888777
 *               address:
 *                 type: string
 *                 example: Av. Principal 123
 *               name:
 *                 type: string
 *                 example: Juan Pérez
 *               email:
 *                 type: string
 *                 example: cliente@empresa.com
 *               roleId:
 *                 type: integer
 *                 example: 2
 *     responses:
 *       200:
 *         description: Cliente actualizado correctamente
 *       400:
 *         description: Datos inválidos
 *       401:
 *         description: Token inválido o no enviado
 *       403:
 *         description: No tiene permisos de administrador
 *       404:
 *         description: Cliente no encontrado
 */
router.put('/clients/:id', authenticate, authorize(['admin']), editClientAndUser)

export default router