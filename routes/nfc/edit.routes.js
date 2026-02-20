import { Router } from 'express';
import { editExtintorController } from '../../controllers/nfc/edit.controller.js';
import { authenticate, authorize } from '../../middleware/auth.middleware.js';

const router = Router();

router.put('/edit-extintor/:id', authenticate, authorize(['admin', 'tecnico']), editExtintorController);

export default router;