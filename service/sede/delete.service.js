import { DeleteRepository } from "../../repository/sede/delete.repository.js";

export async function softDeleteSedeService(id) {
    const sede = await DeleteRepository.softDeleteSede(id);
    return sede;
}

export async function restoreSedeService(id) {
    const sede = await DeleteRepository.restoreSede(id);
    return sede;
}