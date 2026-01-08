import { Router } from 'express'
import { MantenimientoDetalleController } from '../../controllers/mantenimientoD/mantenimientoDetalle.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

router.post('/services/extintores/:servicioExtintorId/mantenimiento',authenticate, authorize(['tecnico']),MantenimientoDetalleController.create)

export default router