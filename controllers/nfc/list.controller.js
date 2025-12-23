import { listNFCService, getNFCByIdService, searchExtinguisherService } from "../../service/nfc/list.service.js";

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