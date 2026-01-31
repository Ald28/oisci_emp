import { CreateNFCRepository } from "../../repository/nfc/create.repository.js";
import { safeDate } from "../../utils/date.util.js";

export async function createExtintorService(data, usuarioId) {
    const {
        sedeId,
        status,
        dateHydrostatic,
        dateMaintenance,
        ...rest
    } = data;

    if (rest.codeExtintor === "") {
        rest.codeExtintor = null;
    }
    if (rest.serialNumberNFC === "") {
        rest.serialNumberNFC = null;
    }

    const historic = status === "OPERATIVO" ? 0 : 1;

    return CreateNFCRepository.create({
        ...rest,
        status,
        historic,
        dateLow: new Date(),

        dateHydrostatic: safeDate(dateHydrostatic),
        dateMaintenance: safeDate(dateMaintenance),

        sede: { connect: { id: sedeId } },
        usuarioCreador: { connect: { id: usuarioId } }
    });
}