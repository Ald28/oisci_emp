import { Router } from 'express'
import { ApprovedController } from '../../controllers/services/approved.controller.js'
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router()

router.get('/:serviceId/review', authenticate, authorize(['admin']), ApprovedController.getReview)
router.put('/:serviceId/approve', authenticate, authorize(['admin']), ApprovedController.approve)
router.put('/:serviceId/reject', authenticate, authorize(['admin']), ApprovedController.reject)

export default router