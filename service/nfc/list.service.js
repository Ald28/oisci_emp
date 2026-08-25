import { ListRepository } from "../../repository/nfc/list.repository.js";
import { mapExtintorPhoto } from "../inspeccionD/storage/keyS3.js";

export async function listNFCService(sedeId = null) {
    const nfcList = await ListRepository.listAll(sedeId);
    return nfcList.map(mapExtintorPhoto);
}

export async function getNFCByIdService(codeExtintor) {
    const nfc = await ListRepository.findByCodeExtintor(codeExtintor);
    return mapExtintorPhoto(nfc);
}

export async function searchExtinguisherService(searchTerm, sedeId = null) {
    const extinguisher = await ListRepository.findBySearchTerm(searchTerm, sedeId);
    return mapExtintorPhoto(extinguisher);
}

export async function getExtinguisherByIdService(extintorId) {
    const extinguisher = await ListRepository.findById(extintorId);
    return mapExtintorPhoto(extinguisher);
}

export async function getExtintoresBySedeService(sedeId) {
    const extintores = await ListRepository.findBySedeId(sedeId);
    return extintores.map(mapExtintorPhoto);
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
    return extintores.map(mapExtintorPhoto);
}

export async function listExtintorNumber({ sedeId = null, page = null, limit = null }) {
    const extintores = await ListRepository.listByExtintorNumber({ sedeId, page, limit });
    return extintores.map(mapExtintorPhoto);
}

export async function updateExtinguisherService(extintorId, data) {
    const extinguisher = await ListRepository.updateExtintor(extintorId, data);
    return mapExtintorPhoto(extinguisher);
}

export async function listExtintoresWithFiltersService(query) {
    const page = query.page === undefined ? 1 : Number(query.page);
    const sedeId = query.sedeId === undefined ? null : Number(query.sedeId);
    const clientId = query.clientId === undefined ? null : Number(query.clientId);

    if (!Number.isInteger(page) || page < 1) {
        throw new Error('page debe ser un entero mayor o igual a 1');
    }
    if (sedeId !== null && (!Number.isInteger(sedeId) || sedeId < 1)) {
        throw new Error('sedeId debe ser un entero mayor o igual a 1');
    }
    if (clientId !== null && (!Number.isInteger(clientId) || clientId < 1)) {
        throw new Error('clientId debe ser un entero mayor o igual a 1');
    }

    const filters = { page, limit: 10, sedeId, clientId };

    if (query.hasCodeExtintor !== undefined) {
        filters.hasCodeExtintor = query.hasCodeExtintor === 'true';
    }

    if (query.hasSerialNumberNFC !== undefined) {
        filters.hasSerialNumberNFC = query.hasSerialNumberNFC === 'true';
    }

    const { total, extintores } = await ListRepository.listWithFilters(filters);
    const totalPages = Math.ceil(total / filters.limit);

    return {
        data: extintores.map(mapExtintorPhoto),
        pagination: {
            page,
            limit: filters.limit,
            total,
            totalPages,
            hasNextPage: page < totalPages,
            hasPreviousPage: page > 1,
        }
    };
}

export const servicioExtintorService = {
    async getExtintoresDetalleByServicio(servicioId) {
        const id = Number(servicioId)

        if (Number.isNaN(id) || id <= 0) {
            throw new Error('El id del servicio no es válido')
        }

        const registros = await ListRepository.getExtintoresDetalleByServicio(id)

        return registros.map((item) => ({
            cliente: item.servicio?.sede?.client || null,
            sede: item.servicio?.sede || null,
            extintor: item.extintor,
            observaciones: item.observaciones || '',
            inspeccion: item.inspeccionDetalle || null,
            mantenimiento: item.mantenimientoDetalle || null
        }))
    }
}
