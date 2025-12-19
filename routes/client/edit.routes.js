import { Router } from 'express'
import { editClientAndUser } from '../../controllers/client/edit.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.put('/clients/:id', authenticate, authorize(['admin']), editClientAndUser)

export default router

/*| URL                       | Ingresar              |
| ------------------------- | ---------------------- |
| `/clients/2`                | Id del cliente            |*/