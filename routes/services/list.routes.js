import { Router } from 'express'
import { ListController } from '../../controllers/services/list.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js'

const router = Router()

router.get('/:servicioId/extintores',authenticate,authorize(['tecnico']),ListController.listServicioExtintores)
router.get('/en-proceso', authenticate, authorize(['tecnico']), ListController.getInProgress)

export default router
