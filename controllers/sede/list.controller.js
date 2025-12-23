import { getSedeByIdService, listSedeService, searchSedeByClient } from "../../service/sede/list.service.js";

export async function listSedeController(req, res) {
    try {
        const sedes = await listSedeService();
        res.status(200).json({
            ok: true,
            data: sedes,
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: error.message,
        });
    }

}

export async function getSedeByIdController(req, res) {
    try {
        const id = Number(req.params.id);

        if (isNaN(id)) {
            return res.status(400).json({
                ok: false,
                message: 'ID inválido',
            });
        }

        const sede = await getSedeByIdService(id);

        if (!sede) {
            return res.status(404).json({
                ok: false,
                message: 'Sede not found',
            });
        }

        res.status(200).json({
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

export async function searchSedeByClientController(req, res) {
    try {
        const id = Number(req.params.id);
        if (isNaN(id)) {
            return res.status(400).json({
                ok: false,
                message: 'ID inválido',
            });
        }
        const sede = await searchSedeByClient(id);

        if (!sede) {
            return res.status(404).json({
                ok: false,
                message: 'Sede no encontrada',
            });
        }
        res.status(200).json({
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