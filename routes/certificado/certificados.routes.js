import { Router } from 'express';
import { certificadosController } from '../../controllers/certificado/certificados.controller.js';

const router = Router();

router.get('/informacion', certificadosController.listInformacion);
router.get('/informacion/:id', certificadosController.getInformacionById);

export default router;