import { createSedeService } from '../../service/sede/create.service.js';

export async function createSedeController(req, res) {
    try {
        const sede = await createSedeService(req.body);

        res.status(201).json({
            ok: true,
            data: sede,
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: error.message,
        });
    }
}