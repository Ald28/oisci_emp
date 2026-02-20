import { EditNFCRepository } from "../../repository/nfc/edit.repository.js";

export const editExtintorService = async (id, body) => {
    if (!id) {
        throw new Error("El ID del extintor es requerido");
    }

    const filteredData = Object.fromEntries(
        Object.entries(body).filter(([_, value]) => value !== undefined)
    );

    if (Object.keys(filteredData).length === 0) {
        throw new Error("Debe enviar al menos un campo para actualizar");
    }

    const updatedExtintor = await EditNFCRepository.editExtintor(
        id,
        filteredData
    );

    return updatedExtintor;
};