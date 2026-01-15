import { Router } from 'express'
import upload from '../../middleware/upload.middleware.js'
import controller from '../../controllers/inspeccionD/inspeccionDetalle.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

router.post('/:id/fotos', upload.array('fotos', 3), authenticate, authorize(['tecnico']), controller.uploadFotosInspeccion)
router.post('/', authenticate, authorize(['tecnico']), controller.createOrUpdateInspeccion)

export default router