import { Router } from 'express'
import { listClients } from '../../controllers/client/list.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.get('/clients', authenticate, authorize(['admin']), listClients)

export default router

/*| URL                       | Resultado              |
| ------------------------- | ---------------------- |
| `/clients`                | Lista todos            |
| `/clients?search=1045`    | Busca por RUC          |
| `/clients?search=empresa` | Busca por razón social |*/