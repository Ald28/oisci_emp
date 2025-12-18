import { Router } from 'express'
import { registerUser } from '../../controllers/client/register.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.post('/register', authenticate, authorize(['admin']), registerUser)

export default router