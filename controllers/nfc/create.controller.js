import { createExtintorService } from "../../service/nfc/create.service.js";

export async function createExtintorController(req, res) {
    try {
        const usuarioId = req.user.sub;
        const data = req.body;

        const extintor = await createExtintorService(data, usuarioId);

        res.status(201).json({ ok: true, data: extintor });
    } catch (error) {
        res.status(500).json({ ok: false, message: error.message });
    }
}