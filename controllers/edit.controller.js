import { editClientAndUserService } from "../service/edit.service.js"

export async function editClientAndUser(req, res) {
    try {
        const clientId = Number(req.params.id)
        const payload = req.body

        if (isNaN(clientId)) {
            return res.status(400).json({ message: 'ID inválido' })
        }
        const updatedData = await editClientAndUserService(clientId, payload)

        return res.status(200).json({
            message: 'Cliente y usuario actualizados correctamente',
            data: updatedData,
        })
    } catch (error) {
        return res.status(404).json({ message: error.message })
    }
}