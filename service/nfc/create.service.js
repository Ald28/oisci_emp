import { CreateNFCRepository } from "../../repository/nfc/create.repository.js";

export async function createExtintorService(data, usuarioId) {
    const { sedeId, status, ...rest } = data;

    const historic = status === "OPERATIVO" ? 0 : 1;

    const extintor = await CreateNFCRepository.create({
        ...rest,
        status,
        historic,
        dateLow: new Date(),

        sede: {
            connect: { id: sedeId }
        },
        usuarioCreador: {
            connect: { id: usuarioId }
        }
    });

    return extintor;
}