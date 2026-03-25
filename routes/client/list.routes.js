import { Router } from 'express'
import { listClients } from '../../controllers/client/list.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

/**
 * @swagger
 * /users/clients:
 *   get:
 *     summary: Listar clientes
 *     tags: [Clients]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *       - in: query
 *         name: pageSize
 *         schema:
 *           type: integer
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *       - in: query
 *         name: all
 *         schema:
 *           type: boolean
 *         description: Si es true, lista todos los clientes sin paginado
 *     responses:
 *       200:
 *         description: Lista de clientes
 */

router.get('/clients', authenticate, authorize(['admin', 'tecnico']), listClients)

export default router