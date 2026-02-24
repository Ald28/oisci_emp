import { listNFCService, getNFCByIdService, searchExtinguisherService, getExtinguisherByIdService, getExtintoresBySedeService, getExtintoresStatsBySedeService, getExtinguishersUpdatedSinceService, listExtintorNumber, updateExtinguisherService, listExtintoresWithFiltersService } from "../../service/nfc/list.service.js";

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
    const sedeId = req.query.sedeId ? Number(req.query.sedeId) : null;

    try {
        const extinguisher = await searchExtinguisherService(searchTerm, sedeId);
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

export async function getExtinguishersUpdatedSinceController(req, res) {
    try {
        const since = req.query.since;

        if (!since || typeof since !== 'string') {
            return res.status(400).json({
                ok: false,
                message: 'El parámetro "since" es requerido (ISO 8601 timestamp)'
            });
        }

        const extintores = await getExtinguishersUpdatedSinceService(since);

        return res.status(200).json({
            ok: true,
            data: extintores
        });
    } catch (error) {
        return res.status(500).json({
            ok: false,
            message: error.message
        });
    }
}

export async function listExtintorNumberController(req, res) {
    try {
        const sedeId = req.query.sedeId ? Number(req.query.sedeId) : null;
        const page = req.query.page ? Number(req.query.page) : null;
        const limit = req.query.limit ? Number(req.query.limit) : null;

        const extintores = await listExtintorNumber({ sedeId, page, limit });

        res.status(200).json({
            ok: true,
            data: extintores,
            pagination: page && limit ? {
                page,
                limit
            } : null
        });

    } catch (error) {
        res.status(500).json({
            ok: false,
            message: "Error retrieving extintor list",
            error: error.message
        });
    }
}

export async function updateExtinguisherController(req, res) {
    try {
        const { extintorId } = req.params;
        const data = req.body;

        // Validar que extintorId sea un número válido
        if (isNaN(Number(extintorId))) {
            return res.status(400).json({
                ok: false,
                message: 'extintorId inválido',
            });
        }

        const extinguisher = await updateExtinguisherService(extintorId, data);

        return res.status(200).json({
            ok: true,
            data: extinguisher,
        });
    } catch (error) {
        // Log detallado en servidor para monitoreo (no se expone al cliente)
        console.error('Error al actualizar extintor:', error);

        // Manejar errores específicos de Prisma con mensajes amigables
        if (error.code === 'P2025') {
            // Prisma: Record not found
            return res.status(404).json({
                ok: false,
                message: 'Extintor no encontrado',
            });
        }

        // Retornar mensaje amigable al cliente (sin exponer códigos técnicos)
        return res.status(500).json({
            ok: false,
            message: 'Error al actualizar extintor. Por favor, intente nuevamente.',
        });
    }
}

export async function listExtintoresWithFiltersController(req, res) {
    try {
        const extintores = await listExtintoresWithFiltersService(req.query);

        return res.status(200).json({
            ok: true,
            data: extintores
        });
    } catch (error) {
        return res.status(500).json({
            ok: false,
            message: error.message
        });
    }
}
