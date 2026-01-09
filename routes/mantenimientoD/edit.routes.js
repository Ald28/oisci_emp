import { Router } from 'express'
import { MantenimientoDetalleController } from '../../controllers/mantenimientoD/edit.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

router.put('/extintores/:servicioExtintorId/mantenimiento', authenticate, authorize(['tecnico']), MantenimientoDetalleController.update)

export default router