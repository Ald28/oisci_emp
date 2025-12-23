import { CreateSedeRepository } from '../../repository/sede/create.repository.js'

export async function createSedeService(data) {

    const sede = await CreateSedeRepository.create(data);

    return sede;
}