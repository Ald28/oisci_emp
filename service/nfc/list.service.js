import { ListRepository } from "../../repository/nfc/list.repository.js";

export async function listNFCService() {
    const nfcList = await ListRepository.listAll();
    return nfcList;
}

export async function getNFCByIdService(codeExtintor) {
    const nfc = await ListRepository.findByCodeExtintor(codeExtintor);
    return nfc;
}

export async function searchExtinguisherService(searchTerm, sedeId = null) {
    const extinguisher = await ListRepository.findBySearchTerm(searchTerm, sedeId);
    return extinguisher;
}

export async function getExtinguisherByIdService(extintorId) {
    const extinguisher = await ListRepository.findById(extintorId);
    return extinguisher;
}

export async function getExtintoresBySedeService(sedeId) {
    const extintores = await ListRepository.findBySedeId(sedeId);
    return extintores;
}

export async function getExtintoresStatsBySedeService(sedeId) {
    const extintores = await ListRepository.getBySede(sedeId);

    const byType = {};
    let total = 0;
    let operativos = 0;
    let inoperativos = 0;

    for (const ext of extintores) {
        total++;

        if (ext.status === 'OPERATIVO') operativos++;
        if (ext.status === 'INOPERATIVO') inoperativos++;

        // Agrupar solo por tipo, sin incluir el agente
        const key = ext.type || 'SIN_TIPO';

        byType[key] = (byType[key] || 0) + 1;
    }

    return {
        sedeId: Number(sedeId),
        byType,
        total,
        operativos,
        inoperativos,
    };
}

export async function getExtinguishersUpdatedSinceService(since) {
    const extintores = await ListRepository.findUpdatedSince(since);
    return extintores;
}

export async function listExtintorNumber({ sedeId = null, page = null, limit = null }) {
    return await ListRepository.listByExtintorNumber({ sedeId, page, limit });
}

export async function updateExtinguisherService(extintorId, data) {
    const extinguisher = await ListRepository.updateExtintor(extintorId, data);
    return extinguisher;
}

export async function listExtintoresWithFiltersService(query) {
    const filters = {};

    if (query.hasCodeExtintor !== undefined) {
        filters.hasCodeExtintor = query.hasCodeExtintor === 'true';
    }

    if (query.hasSerialNumberNFC !== undefined) {
        filters.hasSerialNumberNFC = query.hasSerialNumberNFC === 'true';
    }

    return await ListRepository.listWithFilters(filters);
}