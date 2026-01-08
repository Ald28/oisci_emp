import { Router } from 'express'
import { RegisterController } from '../../controllers/services/register.controller.js'

const router = Router()

router.post('/servicios', RegisterController.createServicio)

export default router