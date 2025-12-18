import { Router } from 'express'
import { deleteClient, restoreClient } from '../../controllers/client/delete.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.delete('/clients/:id', authenticate, authorize(['admin']), deleteClient)
router.patch('/clients/:id/restore', authenticate, authorize(['admin']), restoreClient)

export default router