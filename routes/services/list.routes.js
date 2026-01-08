import { Router } from 'express'
import { ListController } from '../../controllers/services/list.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.get('/:servicioId/extintores',authenticate,authorize(['tecnico']),ListController.listServicioExtintores)

export default router
