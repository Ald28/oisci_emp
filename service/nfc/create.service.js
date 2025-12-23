import { CreateNFCRepository } from "../../repository/nfc/create.repository.js";

export async function createExtintorService(data, usuarioId) {
    const {
        sedeId,
        ...extintorData
    } = data;

    const extintor = await CreateNFCRepository.create({
        ...extintorData,

        sede: {
            connect: { id: sedeId }
        },

        usuarioCreador: {
            connect: { id: usuarioId }
        }
    });

    return extintor;
}