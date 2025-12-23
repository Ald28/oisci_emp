import { softDeleteSedeService, restoreSedeService } from "../../service/sede/delete.service.js";

export async function softDeleteSedeController(req, res) {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({
                ok: false,
                message: 'ID inválido',
            });
        }
        const sede = await softDeleteSedeService(id);
        res.status(200).json({
            ok: true,
            data: sede,
        });
    }
    catch (error) {
        res.status(500).json({
            ok: false,
            message: error.message,
        });
    }
}

export async function restoreSedeController(req, res) {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({
                ok: false,
                message: 'ID inválido',
            });
        }
        const sede = await restoreSedeService(id);
        res.status(200).json({
            ok: true,
            data: sede,
        });
    }
    catch (error) {
        res.status(500).json({
            ok: false,
            message: error.message,
        });
    }
}