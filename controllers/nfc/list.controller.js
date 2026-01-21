import { listNFCService, getNFCByIdService, searchExtinguisherService, getExtinguisherByIdService, getExtintoresBySedeService,getExtintoresStatsBySedeService } from "../../service/nfc/list.service.js";

export async function listNFCController(req, res) {
    try {
        const nfcList = await listNFCService();
        res.status(200).json(nfcList);
    } catch (error) {
        res.status(500).json({ message: "Error retrieving NFC list", error: error.message });
    }
}

export async function getNFCByIdController(req, res) {
    const { codigoNFC } = req.params;
    try {
        const nfc = await getNFCByIdService(codigoNFC);
        if (nfc) {
            res.status(200).json({ ok: true, data: nfc });
        } else {
            res.status(404).json({ ok: false, message: "NFC no encontrado" });
        }
    } catch (error) {
        res.status(500).json({ message: "Error retrieving NFC", error: error.message });
    }
}

export async function searchExtinguisherController(req, res) {
    const { searchTerm } = req.params;
    try {
        const extinguisher = await searchExtinguisherService(searchTerm);
        if (extinguisher) {
            res.status(200).json({ ok: true, data: extinguisher });
        } else {
            res.status(404).json({ ok: false, message: "Extintor no encontrado" });
        }
    } catch (error) {
        res.status(500).json({ ok: false, message: "Error al buscar extintor", error: error.message });
    }
}

export async function getExtinguisherByIdController(req, res) {
    const { extintorId } = req.params;
    try {
        const extinguisher = await getExtinguisherByIdService(Number(extintorId));
        if (extinguisher) {
            res.status(200).json({ ok: true, data: extinguisher });
        } else {
            res.status(404).json({ ok: false, message: "Extintor no encontrado" });
        }
    } catch (error) {
        res.status(500).json({ ok: false, message: "Error al obtener extintor", error: error.message });
    }
}

export async function getExtintoresBySedeController(req, res) {
    try {
        const sedeId = Number(req.params.sedeId);

        if (isNaN(sedeId)) {
            return res.status(400).json({
                ok: false,
                message: 'sedeId inválido',
            });
        }

        const extintores = await getExtintoresBySedeService(sedeId);

        return res.status(200).json({
            ok: true,
            data: extintores,
        });

    } catch (error) {
        return res.status(500).json({
            ok: false,
            message: error.message,
        });
    }
}

export async function getExtintoresStatsBySedeController(req, res) {
    try {
        const sedeId = Number(req.params.sedeId);

        if (isNaN(sedeId)) {
            return res.status(400).json({
                ok: false,
                message: 'sedeId inválido',
            });
        }

        const stats = await getExtintoresStatsBySedeService(sedeId);

        return res.status(200).json({
            ok: true,
            data: stats,
        });

    } catch (error) {
        return res.status(500).json({
            ok: false,
            message: 'Error al obtener estadísticas',
            error: error.message,
        });
    }
}