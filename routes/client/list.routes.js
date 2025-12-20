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
 *         name: search
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Lista de clientes
 */

router.get('/clients', authenticate, authorize(['admin']), listClients)

export default router

/*| URL                          | Resultado              |
| -------------------------      | ---------------------- |
| /clients?page=1                | Lista todos            |
| /clients?search=1045&page=3    | Busca por RUC          |
| /clients?search=empresa&page=1 | Busca por razón social |*/