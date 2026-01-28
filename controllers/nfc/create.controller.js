import { createExtintorService } from "../../service/nfc/create.service.js";
import { emitExtinguisherChange } from "../../utils/socket.helper.js";

export async function createExtintorController(req, res) {
    try {
        const usuarioId = req.user.sub;
        const data = req.body;

        const extintor = await createExtintorService(data, usuarioId);

        // Emitir evento WebSocket para notificar a otros dispositivos
        emitExtinguisherChange('created', extintor);

        res.status(201).json({ ok: true, data: extintor });
    } catch (error) {
        if (error.code === 'P2002') {
            return res.status(409).json({
                ok: false,
                message: 'El codeNFC ya existe'
            });
        }

        return res.status(500).json({
            ok: false,
            message: error.message
        });
    }
}