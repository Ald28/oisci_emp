import { ListRepository } from "../../repository/sede/list.repository.js";

export async function listSedeService() {
    const sedes =  await ListRepository.listAll();
    return sedes;
}

export async function getSedeByIdService(id) {
    const sede = await ListRepository.findById(id);
    return sede;
}

export async function searchSedeByClient(id){
    const sede = await ListRepository.searchSedeByClient(id);
    return sede;
}