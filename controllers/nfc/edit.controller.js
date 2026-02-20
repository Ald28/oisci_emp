import { editExtintorService } from "../../service/nfc/edit.service.js";

export const editExtintorController = async (req, res) => {
    try {
        const { id } = req.params;

        const updatedExtintor = await editExtintorService(id, req.body);

        return res.status(200).json({
            message: "Extintor actualizado correctamente",
            data: updatedExtintor,
        });
    } catch (error) {
        return res.status(400).json({
            message: error.message,
        });
    }
};