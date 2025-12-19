import { editClientAndUserService } from "../../service/client/edit.service.js"

export async function editClientAndUser(req, res) {
    try {
        const clientId = Number(req.params.id)
        const payload = req.body
        const editorUser = req.user

        const updatedData = await editClientAndUserService(
            clientId,
            payload,
            editorUser
        )

        return res.status(200).json({
            message: 'Cliente y usuario actualizados correctamente',
            data: updatedData,
        })
    } catch (error) {
        return res.status(404).json({ message: error.message })
    }
}