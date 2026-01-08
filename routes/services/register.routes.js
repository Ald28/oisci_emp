import { Router } from 'express'
import { ServiceController } from '../../controllers/services/register.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

router.post('/create', authenticate, authorize(['tecnico']), ServiceController.createService)
router.post('/create/:servicioId/extintores', authenticate, authorize(['tecnico']), ServiceController.addExtintor)
router.put('/:servicioId/finalizar', authenticate, authorize(['tecnico']), ServiceController.finalizeService)

export default router